#define _DEFAULT_SOURCE
#include <libwebsockets.h>

#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "hg_grid.h"
#include "hg_session.h"

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
extern void *hg_session_at(int index);
extern void hg_combat_round(void *session, void *wsi);
extern long long hg_now_ms(void);
extern void hg_emit_vitals_now(void *session, const char *room_id);
extern const char *hg_room_id_cstr(long long room);
extern void hg_session_queue(void *session, void *wsi, const void *data,
                             size_t len);

static volatile sig_atomic_t stopped;
static const char *active_world = "Basalt Relay";
static struct lws_context *g_context;

/* Async-signal-safe: set the flag only. The 50ms lws_sul beat below keeps the
 * service loop waking, so shutdown is observed within one beat. */
static void stop_server(int signal_number) {
  (void)signal_number;
  stopped = 1;
}

/* Called from asm at combat start: arm first swing for +2000ms so smoke can
 * observe inCombat and clear its event log before rounds arrive. */
void hg_combat_arm(void *session, void *wsi) {
  if (session == NULL) {
    return;
  }
  long long now = hg_now_ms();
  hg_s_set_i64(session, HG_SESSION_LAST_TICK, now + 2000);
  if (wsi != NULL) {
    *(void **)((unsigned char *)session + HG_SESSION_WSI) = wsi;
  }
  if (g_context != NULL) {
    lws_cancel_service(g_context);
  }
}


/* Resting regen on the living-world beat (same 2s cadence as Go). Owned here
 * so idle recv waits cannot starve asm tick_session. */
static void hg_rest_service(long long now_ms) {
  static long long last_rest_ms;
  if (last_rest_ms != 0 && now_ms - last_rest_ms < 2000) {
    return;
  }
  last_rest_ms = now_ms;
  for (int i = 0; i < HG_MAX_SESSIONS; i++) {
    unsigned char *session = (unsigned char *)hg_session_at(i);
    if (session == NULL) {
      continue;
    }
    if (hg_s_i64(session, HG_SESSION_IN_COMBAT)) {
      continue;
    }
    const char *pos = hg_s_str(session, HG_SESSION_POSITION);
    if (pos == NULL || strcmp(pos, "resting") != 0) {
      continue;
    }
    long long hp = hg_s_i64(session, HG_SESSION_HP);
    long long max_hp = hg_s_i64(session, HG_SESSION_MAX_HP);
    if (hp >= max_hp) {
      continue;
    }
    hp += 2;
    if (hp > max_hp) {
      hp = max_hp;
    }
    hg_s_set_i64(session, HG_SESSION_HP, hp);
    long long room = hg_s_i64(session, HG_SESSION_ROOM);
    const char *rid = hg_room_id_cstr(room);
    hg_emit_vitals_now(session, rid);
    struct lws *wsi = *(struct lws **)(session + HG_SESSION_WSI);
    if (wsi != NULL) {
      lws_callback_on_writable(wsi);
    }
  }
}

/* One swing per due beat. Never nest lws_service here -- nested zero-timeout
 * pumps hang after attack. Drain only via WRITEABLE on the outer service. */
static void hg_combat_service(long long now_ms) {
  for (int i = 0; i < HG_MAX_SESSIONS; i++) {
    unsigned char *session = (unsigned char *)hg_session_at(i);
    if (session == NULL) {
      continue;
    }
    if (!hg_s_i64(session, HG_SESSION_IN_COMBAT)) {
      continue;
    }
    long long last = hg_s_i64(session, HG_SESSION_LAST_TICK);
    struct lws *wsi = *(struct lws **)(session + HG_SESSION_WSI);
    if (wsi == NULL) {
      continue;
    }
    if (last == 0) {
      hg_s_set_i64(session, HG_SESSION_LAST_TICK, now_ms + 2000);
      continue;
    }
    if (now_ms < last) {
      continue;
    }
    hg_combat_round(session, wsi);
    lws_callback_on_writable(wsi);
    if (hg_s_i64(session, HG_SESSION_IN_COMBAT)) {
      hg_s_set_i64(session, HG_SESSION_LAST_TICK, now_ms + 2000);
    }
  }
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
  case LWS_CALLBACK_RECEIVE: {
    /* Reassemble fragmented text messages; reject oversize with a notice
     * instead of silently truncating ("never silently", CLAUDE.md). */
    unsigned char *s = (unsigned char *)session;
    long long rx_len = hg_s_i64(s, HG_SESSION_RX_LEN);
    unsigned char *rx = s + HG_SESSION_RX;

    if (lws_frame_is_binary(wsi)) {
      /* /ws is UTF-8 text; drop binary and any partial message around it. */
      hg_s_set_i64(s, HG_SESSION_RX_LEN, 0);
      break;
    }
    if (rx_len >= 0) {
      if ((size_t)rx_len + length > (size_t)(HG_SESSION_RX_CAP - 1)) {
        rx_len = -1; /* oversize: answer at message end */
      } else {
        memcpy(rx + rx_len, input, length);
        rx_len += (long long)length;
      }
      hg_s_set_i64(s, HG_SESSION_RX_LEN, rx_len);
    }
    if (lws_is_final_fragment(wsi) &&
        lws_remaining_packet_payload(wsi) == 0) {
      if (rx_len < 0) {
        static const char too_long[] =
            "Input too long (255 bytes max). Command ignored.\r\n";
        hg_session_queue(session, wsi, too_long, sizeof(too_long) - 1);
      } else if (rx_len > 0) {
        rc = hg_app_callback(wsi, HG_EVT_RECEIVE, session, rx,
                             (size_t)rx_len);
      }
      hg_s_set_i64(s, HG_SESSION_RX_LEN, 0);
    }
    break;
  }
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
  if (socket == NULL) {
    return;
  }
  lws_callback_on_writable((struct lws *)socket);
}

/* Only safe from LWS_CALLBACK_SERVER_WRITEABLE. */
int hg_ws_write(void *socket, const unsigned char *data, size_t length) {
  struct lws *wsi = (struct lws *)socket;
  unsigned char *buf;
  int n;

  if (wsi == NULL || data == NULL || length == 0) {
    return -1;
  }
  buf = malloc(LWS_PRE + length);
  if (buf == NULL) {
    return -1;
  }
  memcpy(buf + LWS_PRE, data, length);
  n = lws_write(wsi, buf + LWS_PRE, length, LWS_WRITE_TEXT);
  free(buf);
  if (n < 0) {
    return -1;
  }
  if ((size_t)n < length) {
    lws_callback_on_writable(wsi);
    return 1;
  }
  return 0;
}

/* 50ms living-world beat on an lws_sul timer. Replaces the old SIGALRM +
 * lws_cancel_service watchdog: the callback runs on the event loop inside
 * lws_service, so no library call happens in signal context, and the pending
 * deadline bounds every service wait (shutdown observed within one beat). */
static lws_sorted_usec_list_t g_tick_sul;

static void tick_service(lws_sorted_usec_list_t *sul) {
  long long tick_now = hg_now_ms();
  hg_heartbeat(tick_now);
  hg_combat_service(tick_now);
  hg_rest_service(tick_now);
  hg_grid_federation_tick(tick_now);
  lws_sul_schedule(g_context, 0, sul, tick_service, 50 * LWS_US_PER_MS);
}

int hg_lws_run(const char *host, int port, const char *world_name) {
  struct lws_protocols protocols[] = {
      {"http", callback, hg_app_session_size(), 8192, 0, NULL, 0},
      LWS_PROTOCOL_LIST_TERM,
  };
  struct lws_context_creation_info info;
  struct sigaction sa;

  memset(&info, 0, sizeof(info));
  info.port = port;
  info.iface = host;
  info.protocols = protocols;
  info.options = LWS_SERVER_OPTION_VALIDATE_UTF8;

  active_world = world_name;
  stopped = 0;
  memset(&sa, 0, sizeof(sa));
  sa.sa_handler = stop_server;
  sigemptyset(&sa.sa_mask);
  sigaction(SIGINT, &sa, NULL);
  sigaction(SIGTERM, &sa, NULL);
  lws_set_log_level(LLL_ERR | LLL_WARN, NULL);

  g_context = lws_create_context(&info);
  if (g_context == NULL) {
    fprintf(stderr, "failed to create libwebsockets context\n");
    return 1;
  }
  if (hg_grid_remote()) {
    hg_grid_register_self();
  }

  lws_sul_schedule(g_context, 0, &g_tick_sul, tick_service,
                   50 * LWS_US_PER_MS);

  fprintf(stdout, "%s listening on %s:%d\n", world_name, host, port);
  fflush(stdout);
  /* Single outer service call. Do not nest lws_service. */
  while (!stopped && lws_service(g_context, 0) >= 0) {
  }
  lws_sul_cancel(&g_tick_sul);
  lws_context_destroy(g_context);
  g_context = NULL;
  return 0;
}
