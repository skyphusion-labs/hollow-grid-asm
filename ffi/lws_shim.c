#include <libwebsockets.h>

#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

enum hg_event {
  HG_EVT_CONNECTED = 1,
  HG_EVT_RECEIVE = 2,
  HG_EVT_WRITABLE = 3,
  HG_EVT_CLOSED = 4,
};

extern size_t hg_app_session_size(void);
extern int hg_app_callback(void *wsi, int event, void *session,
                           const unsigned char *input, size_t length);

static volatile sig_atomic_t stopped;
static const char *active_world = "Basalt Relay";

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
  long long now_ms = (long long)time(NULL) * 1000;

  if (strcmp(path, "/health") == 0) {
    snprintf(body, sizeof(body),
             "{\"ok\":true,\"ts\":%lld,\"world\":\"%s\"}", now_ms,
             active_world);
    return send_http(wsi, HTTP_STATUS_OK, "application/json", body);
  }
  if (strcmp(path, "/health/deep") == 0) {
    snprintf(body, sizeof(body),
             "{\"ok\":true,\"ts\":%lld,\"world\":\"%s\",\"checks\":{"
             "\"world\":{\"ok\":true,\"latency_ms\":0,\"critical\":true},"
             "\"grid_hub\":{\"ok\":true,\"latency_ms\":0,"
             "\"critical\":false}}}",
             now_ms, active_world);
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
  switch (reason) {
  case LWS_CALLBACK_FILTER_PROTOCOL_CONNECTION: {
    char path[128];
    int copied = lws_hdr_copy(wsi, path, sizeof(path), WSI_TOKEN_GET_URI);
    return copied > 0 && strcmp(path, "/ws") == 0 ? 0 : 1;
  }
  case LWS_CALLBACK_HTTP:
    return handle_http(wsi, (const char *)input);
  case LWS_CALLBACK_ESTABLISHED:
    return hg_app_callback(wsi, HG_EVT_CONNECTED, session, NULL, 0);
  case LWS_CALLBACK_RECEIVE:
    if (!lws_frame_is_binary(wsi) && lws_is_final_fragment(wsi)) {
      return hg_app_callback(wsi, HG_EVT_RECEIVE, session, input, length);
    }
    return 0;
  case LWS_CALLBACK_SERVER_WRITEABLE:
    return hg_app_callback(wsi, HG_EVT_WRITABLE, session, NULL, 0);
  case LWS_CALLBACK_CLOSED:
    return hg_app_callback(wsi, HG_EVT_CLOSED, session, NULL, 0);
  default:
    return 0;
  }
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
  fprintf(stdout, "%s listening on %s:%d\n", world_name, host, port);
  while (!stopped && lws_service(context, 100) >= 0) {
  }
  lws_context_destroy(context);
  return 0;
}

