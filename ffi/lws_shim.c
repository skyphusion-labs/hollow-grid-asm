#include <libwebsockets.h>

#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#if defined(__linux__)
#include <sys/time.h>
#endif

#include "hg_grid.h"

enum hg_event {
  HG_EVT_CONNECTED = 1,
  HG_EVT_RECEIVE = 2,
  HG_EVT_WRITABLE = 3,
  HG_EVT_CLOSED = 4,
};

extern size_t hg_app_session_size(void);
extern int hg_app_callback(void *wsi, int event, void *session,
                           const unsigned char *input, size_t length);
extern void hg_heartbeat(long long now_ms);

int hg_format_vitals(char *buf, size_t cap, long hp, long max_hp, long level,
                     long xp, long gold, const char *room, int in_combat,
                     const char *position) {
  return snprintf(
      buf, cap,
      "@event char.vitals "
      "{\"hp\":%ld,\"maxHp\":%ld,\"level\":%ld,\"xp\":%ld,\"gold\":%ld,"
      "\"room\":\"%s\",\"inCombat\":%s,\"poisoned\":false,"
      "\"position\":\"%s\"}\r\n",
      hp, max_hp, level, xp, gold, room, in_combat ? "true" : "false",
      position);
}

int hg_format_affects(char *buf, size_t cap, long morality, long addiction,
                      const char *faction, const char *race, int ashsworn) {
  return snprintf(
      buf, cap,
      "@event char.affects "
      "{\"morality\":%ld,\"addiction\":%ld,\"faction\":\"%s\","
      "\"resisted\":false,\"race\":\"%s\",\"ashsworn\":%s}\r\n",
      morality, addiction, faction, race, ashsworn ? "true" : "false");
}

int hg_format_combat_round(char *buf, size_t cap, long mob_hp, long player_dmg,
                           long mob_dmg, long hp) {
  return snprintf(buf, cap,
                  "@event combat.round "
                  "{\"mob\":\"rat\",\"mobHp\":%ld,\"mobMaxHp\":12,"
                  "\"playerDmg\":%ld,\"mobDmg\":%ld,\"hp\":%ld}\r\n",
                  mob_hp, player_dmg, mob_dmg, hp);
}

int hg_format_world_state(char *buf, size_t cap, long tick,
                          const char *phase) {
  return snprintf(buf, cap,
                  "@event world.state "
                  "{\"tick\":%ld,\"phase\":\"%s\",\"weather\":\"clear\"}\r\n",
                  tick, phase);
}

static volatile sig_atomic_t stopped;
static const char *active_world = "Basalt Relay";

static long long hg_now_ms(void) {
#if defined(__linux__)
  struct timeval tv;
  if (gettimeofday(&tv, NULL) == 0) {
    return (long long)tv.tv_sec * 1000LL + (long long)tv.tv_usec / 1000LL;
  }
#endif
  return (long long)time(NULL) * 1000LL;
}

static void stop_server(int signal_number) {
  (void)signal_number;
  stopped = 1;
}

static int send_http(struct lws *wsi, unsigned int status,
                     const char *content_type, const char *body) {
  unsigned char headers[LWS_PRE + 512];
  unsigned char *start = &headers[LWS_PRE];
  unsigned char *cursor = start;
  unsigned char *end = &headers[sizeof(headers) - 1];
  size_t length = strlen(body);

  if (lws_add_http_common_headers(wsi, status, content_type, length, &cursor,
                                  end) != 0 ||
      lws_finalize_write_http_header(wsi, start, &cursor, end) != 0) {
    return -1;
  }
  if (lws_write_http(wsi, body, length) < 0) {
    return -1;
  }
  return lws_http_transaction_completed(wsi) ? -1 : 0;
}

static int handle_http(struct lws *wsi, const char *path) {
  char body[512];
  long long now_ms = hg_now_ms();

  if (strcmp(path, "/health") == 0) {
    snprintf(body, sizeof(body),
             "{\"ok\":true,\"ts\":%lld,\"world\":\"%s\"}", now_ms,
             active_world);
    return send_http(wsi, HTTP_STATUS_OK, "application/json", body);
  }
  if (strcmp(path, "/health/deep") == 0) {
    int grid_ok = 1;
    long grid_latency = 0;
    hg_grid_health(&grid_ok, &grid_latency);
    snprintf(body, sizeof(body),
             "{\"ok\":true,\"ts\":%lld,\"world\":\"%s\",\"checks\":{"
             "\"world\":{\"ok\":true,\"latency_ms\":0,\"critical\":true},"
             "\"grid_hub\":{\"ok\":%s,\"latency_ms\":%ld,"
             "\"critical\":false}}}",
             now_ms, active_world, grid_ok ? "true" : "false", grid_latency);
    return send_http(wsi, HTTP_STATUS_OK, "application/json", body);
  }
  if (strcmp(path, "/map.svg") == 0) {
    return send_http(
        wsi, HTTP_STATUS_OK, "image/svg+xml",
        "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"640\" "
        "height=\"160\"><rect width=\"100%\" height=\"100%\" "
        "fill=\"#111318\"/><text x=\"24\" y=\"42\" fill=\"#c6cbd3\" "
        "font-family=\"monospace\" font-size=\"20\">Basalt Relay</text>"
        "<text x=\"24\" y=\"84\" fill=\"#87909c\" "
        "font-family=\"monospace\">nexus - workshop - roof - relay-cut"
        "</text></svg>");
  }
  return send_http(wsi, HTTP_STATUS_NOT_FOUND, "application/json",
                   "{\"ok\":false,\"error\":\"not found\"}");
}

static int callback(struct lws *wsi, enum lws_callback_reasons reason,
                    void *session, void *input, size_t length) {
  int rc = 0;

  switch (reason) {
  case LWS_CALLBACK_FILTER_PROTOCOL_CONNECTION: {
    char path[128];
    int copied = lws_hdr_copy(wsi, path, sizeof(path), WSI_TOKEN_GET_URI);
    return copied > 0 && strcmp(path, "/ws") == 0 ? 0 : 1;
  }
  case LWS_CALLBACK_HTTP:
    return handle_http(wsi, (const char *)input);
  case LWS_CALLBACK_ESTABLISHED:
    rc = hg_app_callback(wsi, HG_EVT_CONNECTED, session, NULL, 0);
    break;
  case LWS_CALLBACK_RECEIVE:
    if (!lws_frame_is_binary(wsi) && lws_is_final_fragment(wsi)) {
      rc = hg_app_callback(wsi, HG_EVT_RECEIVE, session, input, length);
    }
    break;
  case LWS_CALLBACK_SERVER_WRITEABLE:
    rc = hg_app_callback(wsi, HG_EVT_WRITABLE, session, NULL, 0);
    break;
  case LWS_CALLBACK_CLOSED:
    rc = hg_app_callback(wsi, HG_EVT_CLOSED, session, NULL, 0);
    break;
  default:
    return 0;
  }

  return rc;
}

void hg_ws_request_write(void *socket) {
  lws_callback_on_writable((struct lws *)socket);
}

int hg_ws_write(void *socket, const unsigned char *data, size_t length) {
  unsigned char *buffer = malloc(LWS_PRE + length);
  if (buffer == NULL) {
    return -1;
  }
  memcpy(buffer + LWS_PRE, data, length);
  int written = lws_write((struct lws *)socket, buffer + LWS_PRE, length,
                          LWS_WRITE_TEXT);
  free(buffer);
  return written == (int)length ? 0 : -1;
}

int hg_lws_run(const char *host, int port, const char *world_name) {
  struct lws_protocols protocols[] = {
      {"http", callback, hg_app_session_size(), 8192, 0, NULL, 0},
      LWS_PROTOCOL_LIST_TERM,
  };
  struct lws_context_creation_info info;
  memset(&info, 0, sizeof(info));
  info.port = port;
  info.iface = host;
  info.protocols = protocols;
  info.options = LWS_SERVER_OPTION_VALIDATE_UTF8;

  active_world = world_name;
  stopped = 0;
  signal(SIGINT, stop_server);
  signal(SIGTERM, stop_server);
  lws_set_log_level(LLL_ERR | LLL_WARN, NULL);

  struct lws_context *context = lws_create_context(&info);
  if (context == NULL) {
    fprintf(stderr, "failed to create libwebsockets context\n");
    return 1;
  }
  if (hg_grid_remote()) {
    /* Best-effort: federation never blocks bringing the world up. */
    hg_grid_register_self();
  }
  fprintf(stdout, "%s listening on %s:%d\n", world_name, host, port);
  while (!stopped && lws_service(context, 100) >= 0) {
    long long tick_now = hg_now_ms();
    hg_heartbeat(tick_now);
    hg_grid_federation_tick(tick_now);
    lws_service(context, 0);
  }
  lws_context_destroy(context);
  return 0;
}

