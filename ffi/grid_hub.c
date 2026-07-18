/* Grid Hub federation client: LocalHub (in-memory, always available) or
 * RemoteHub (HTTP JSON-RPC over libcurl). See include/hg_grid.h.
 *
 * Ownership: this file owns HTTP/JSON/libcurl transport and all event/prose
 * formatting for hub-backed output. It never decides game rules; ASM decides
 * when to call and how to dispatch player commands (docs/ARCHITECTURE.md).
 */
#include "hg_grid.h"
#include "hg_session.h"

#include <cjson/cJSON.h>
#include <ctype.h>
#include <curl/curl.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <time.h>

#define HG_RPC_TIMEOUT_MS 2000L
#define HG_MAX_TRACES 200
#define HG_MAX_ECHO 128
#define HG_MAX_RESCUED 200
#define HG_MAX_FALLEN 200
#define HG_FEDERATION_TICK_MS 10000LL

typedef struct {
  char world[48];
  char node[64];
  char kind[24];
  char text[200];
  long long at;
} hg_trace;

typedef struct {
  char node[64];
  char kind[24];
  char text[200];
  long long at;
} hg_echo;

typedef struct {
  char world[48];
  char name[33];
  char saved_by[33];
  long long at;
} hg_rescued;

typedef struct {
  char world[48];
  char name[33];
  char room[32];
  long long at;
} hg_fallen;

static struct {
  int booted;
  int remote;
  char world_name[64];
  char world_url[160];
  char hub_url[256];
  char token[256];
  CURL *curl;
  int curl_global_owned;

  hg_trace traces[HG_MAX_TRACES];
  int trace_count;
  int tide;

  hg_rescued rescued[HG_MAX_RESCUED];
  int rescued_count;
  hg_fallen fallen[HG_MAX_FALLEN];
  int fallen_count;

#define HG_MAX_CASTS 200
  hg_grid_cast_row casts[HG_MAX_CASTS];
  int cast_count;
  int next_cast_id;

  hg_echo echo[HG_MAX_ECHO];
  int echo_count;

  long long last_federation_tick_ms;
} g;

/* ---------- small helpers ---------- */

static long long now_ms(void) {
  struct timeval tv;
  gettimeofday(&tv, NULL);
  return (long long)tv.tv_sec * 1000LL + (long long)tv.tv_usec / 1000LL;
}

/* Deliberately truncates rather than overflowing when src is longer than
 * cap; GCC's format-truncation check can't see that callers accept this. */
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wformat-truncation"
static void safe_copy(char *dst, size_t cap, const char *src) {
  if (src == NULL) {
    src = "";
  }
  snprintf(dst, cap, "%s", src);
}
#pragma GCC diagnostic pop

/* Escapes '"', '\\', and control characters for safe embedding in our own
 * generated JSON. Truncates rather than overflowing. */
static void json_escape(char *out, size_t cap, const char *in) {
  if (cap == 0) {
    return;
  }
  if (in == NULL) {
    in = "";
  }
  size_t w = 0;
  for (; *in != '\0' && w + 2 < cap; ++in) {
    unsigned char c = (unsigned char)*in;
    if (c == '"' || c == '\\') {
      out[w++] = '\\';
      out[w++] = (char)c;
    } else if (c == '\n') {
      out[w++] = '\\';
      out[w++] = 'n';
    } else if (c == '\r') {
      out[w++] = '\\';
      out[w++] = 'r';
    } else if (c < 0x20) {
      /* drop other control bytes */
    } else {
      out[w++] = (char)c;
    }
  }
  out[w] = '\0';
}

static int ci_equal(const char *a, const char *b) {
  if (a == NULL || b == NULL) {
    return a == b;
  }
  while (*a != '\0' && *b != '\0') {
    if (tolower((unsigned char)*a) != tolower((unsigned char)*b)) {
      return 0;
    }
    ++a;
    ++b;
  }
  return *a == '\0' && *b == '\0';
}

static int clamp_tide(int n) {
  if (n < -100) {
    return -100;
  }
  if (n > 100) {
    return 100;
  }
  return n;
}

/* ---------- local echo (always-on, both modes) ---------- */

static void echo_prepend(const char *node, const char *kind, const char *text,
                         long long at) {
  int n = g.echo_count < HG_MAX_ECHO ? g.echo_count : HG_MAX_ECHO - 1;
  for (int i = n; i > 0; --i) {
    g.echo[i] = g.echo[i - 1];
  }
  safe_copy(g.echo[0].node, sizeof(g.echo[0].node), node);
  safe_copy(g.echo[0].kind, sizeof(g.echo[0].kind), kind);
  safe_copy(g.echo[0].text, sizeof(g.echo[0].text), text);
  g.echo[0].at = at;
  if (g.echo_count < HG_MAX_ECHO) {
    g.echo_count++;
  }
}

/* ---------- LocalHub cross-world memory ---------- */

static void trace_prepend(const char *world, const char *node,
                          const char *kind, const char *text, long long at) {
  int n = g.trace_count < HG_MAX_TRACES ? g.trace_count : HG_MAX_TRACES - 1;
  for (int i = n; i > 0; --i) {
    g.traces[i] = g.traces[i - 1];
  }
  safe_copy(g.traces[0].world, sizeof(g.traces[0].world), world);
  safe_copy(g.traces[0].node, sizeof(g.traces[0].node), node);
  safe_copy(g.traces[0].kind, sizeof(g.traces[0].kind), kind);
  safe_copy(g.traces[0].text, sizeof(g.traces[0].text), text);
  g.traces[0].at = at;
  if (g.trace_count < HG_MAX_TRACES) {
    g.trace_count++;
  }
}

static void seed_local_traces(void) {
  trace_prepend("Dustfall", "the long market", "slain",
               "a trader put down a chrome-jackal with a length of pipe.", 0);
  trace_prepend("the Ninth Server", "cell block C", "oath",
               "someone swore off the dust for the ninth time.", 0);
  trace_prepend("Saltreach", "the drowned pier", "death",
               "a runner called Mox bled out, cursing the tide.", 0);
  /* Ambient noise the keeper can flush with gridprune. */
  trace_prepend("Basalt Relay", "nexus", "ghost",
               "a faint cursor blinks once and is gone.", 0);
  trace_prepend("Basalt Relay", "market", "passage",
               "someone passed through without leaving a name.", 0);
  trace_prepend("Basalt Relay", "roof", "recall",
               "a half-remembered transmission dissolves into static.", 0);
}

/* ---------- RemoteHub transport ---------- */

struct hg_membuf {
  char *data;
  size_t size;
};

static size_t curl_write_cb(char *ptr, size_t size, size_t nmemb,
                            void *userdata) {
  struct hg_membuf *buf = userdata;
  size_t add = size * nmemb;
  char *next = realloc(buf->data, buf->size + add + 1);
  if (next == NULL) {
    return 0;
  }
  buf->data = next;
  memcpy(buf->data + buf->size, ptr, add);
  buf->size += add;
  buf->data[buf->size] = '\0';
  return add;
}

/* 0 = ok (result may be NULL for JSON null). -1 = transport/RPC failure.
 * Fail-open: callers must treat -1 as "hub unreachable", never fatal. */
static int rpc_call(const char *method, cJSON *params, cJSON **out_result) {
  if (out_result != NULL) {
    *out_result = NULL;
  }
  if (!g.remote || g.curl == NULL) {
    cJSON_Delete(params);
    return -1;
  }
  cJSON *req = cJSON_CreateObject();
  if (req == NULL) {
    cJSON_Delete(params);
    return -1;
  }
  cJSON_AddStringToObject(req, "method", method);
  if (params == NULL) {
    params = cJSON_CreateArray();
  }
  cJSON_AddItemToObject(req, "params", params);
  char *body = cJSON_PrintUnformatted(req);
  cJSON_Delete(req);
  if (body == NULL) {
    return -1;
  }

  struct hg_membuf buf = {0};
  struct curl_slist *headers = NULL;
  headers = curl_slist_append(headers, "Content-Type: application/json");
  headers = curl_slist_append(headers, "User-Agent: hollow-grid-asm/0.1.0");
  char auth[320];
  if (g.token[0] != '\0') {
    snprintf(auth, sizeof(auth), "Authorization: Bearer %s", g.token);
    headers = curl_slist_append(headers, auth);
  }

  curl_easy_reset(g.curl);
  curl_easy_setopt(g.curl, CURLOPT_URL, g.hub_url);
  curl_easy_setopt(g.curl, CURLOPT_HTTPHEADER, headers);
  curl_easy_setopt(g.curl, CURLOPT_POSTFIELDS, body);
  curl_easy_setopt(g.curl, CURLOPT_WRITEFUNCTION, curl_write_cb);
  curl_easy_setopt(g.curl, CURLOPT_WRITEDATA, &buf);
  curl_easy_setopt(g.curl, CURLOPT_TIMEOUT_MS, HG_RPC_TIMEOUT_MS);
  curl_easy_setopt(g.curl, CURLOPT_CONNECTTIMEOUT_MS, HG_RPC_TIMEOUT_MS);
  curl_easy_setopt(g.curl, CURLOPT_NOSIGNAL, 1L);

  CURLcode rc = curl_easy_perform(g.curl);
  curl_slist_free_all(headers);
  free(body);
  if (rc != CURLE_OK) {
    free(buf.data);
    return -1;
  }

  cJSON *wrap = cJSON_Parse(buf.data != NULL ? buf.data : "");
  free(buf.data);
  if (wrap == NULL) {
    return -1;
  }
  cJSON *ok = cJSON_GetObjectItemCaseSensitive(wrap, "ok");
  if (!cJSON_IsTrue(ok)) {
    cJSON_Delete(wrap);
    return -1;
  }
  cJSON *result = cJSON_DetachItemFromObjectCaseSensitive(wrap, "result");
  cJSON_Delete(wrap);
  if (out_result != NULL) {
    *out_result = result;
  } else {
    cJSON_Delete(result);
  }
  return 0;
}

static const char *json_str(const cJSON *obj, const char *key) {
  const cJSON *item = cJSON_GetObjectItemCaseSensitive(obj, key);
  return cJSON_IsString(item) && item->valuestring != NULL ? item->valuestring
                                                           : "";
}

static long long json_ll(const cJSON *obj, const char *key) {
  const cJSON *item = cJSON_GetObjectItemCaseSensitive(obj, key);
  return cJSON_IsNumber(item) ? (long long)item->valuedouble : 0;
}

static long json_num(const cJSON *obj, const char *key, long fallback) {
  const cJSON *item = cJSON_GetObjectItemCaseSensitive(obj, key);
  return cJSON_IsNumber(item) ? (long)item->valuedouble : fallback;
}

/* ---------- boot / shutdown / health ---------- */

int hg_grid_boot(const char *world_name, const char *world_url,
                 const char *hub_url, const char *token) {
  memset(&g, 0, sizeof(g));
  safe_copy(g.world_name, sizeof(g.world_name), world_name);
  safe_copy(g.world_url, sizeof(g.world_url), world_url);
  srand((unsigned)now_ms());

  if (hub_url == NULL || hub_url[0] == '\0') {
    g.remote = 0;
    seed_local_traces();
    return 0;
  }

  safe_copy(g.hub_url, sizeof(g.hub_url), hub_url);
  size_t len = strlen(g.hub_url);
  while (len > 0 && g.hub_url[len - 1] == '/') {
    g.hub_url[--len] = '\0';
  }
  safe_copy(g.token, sizeof(g.token), token);

  if (curl_global_init(CURL_GLOBAL_DEFAULT) != 0) {
    /* Fail open to LocalHub rather than failing boot outright. */
    g.remote = 0;
    seed_local_traces();
    return 0;
  }
  g.curl_global_owned = 1;
  g.curl = curl_easy_init();
  if (g.curl == NULL) {
    curl_global_cleanup();
    g.curl_global_owned = 0;
    g.remote = 0;
    seed_local_traces();
    return 0;
  }
  g.remote = 1;
  g.booted = 1;
  return 0;
}

void hg_grid_shutdown(void) {
  if (g.curl != NULL) {
    curl_easy_cleanup(g.curl);
    g.curl = NULL;
  }
  if (g.curl_global_owned) {
    curl_global_cleanup();
    g.curl_global_owned = 0;
  }
}

int hg_grid_remote(void) { return g.remote; }

int hg_grid_health(int *ok, long *latency_ms) {
  if (!g.remote) {
    if (ok != NULL) {
      *ok = 1;
    }
    if (latency_ms != NULL) {
      *latency_ms = 0;
    }
    return 0;
  }
  long long start = now_ms();
  cJSON *result = NULL;
  int rc = rpc_call("tide", cJSON_CreateArray(), &result);
  cJSON_Delete(result);
  if (latency_ms != NULL) {
    *latency_ms = (long)(now_ms() - start);
  }
  if (ok != NULL) {
    *ok = rc == 0;
  }
  return 0;
}

/* ---------- record / echo ---------- */

int hg_grid_record(const char *world, const char *node, const char *kind,
                   const char *text, long long at_ms) {
  if (at_ms == 0) {
    at_ms = now_ms();
  }
  if (!g.remote) {
    trace_prepend(world, node, kind, text, at_ms);
    return 0;
  }
  cJSON *params = cJSON_CreateArray();
  cJSON_AddItemToArray(params, cJSON_CreateString(world != NULL ? world : ""));
  cJSON_AddItemToArray(params, cJSON_CreateString(node != NULL ? node : ""));
  cJSON_AddItemToArray(params, cJSON_CreateString(kind != NULL ? kind : ""));
  cJSON_AddItemToArray(params, cJSON_CreateString(text != NULL ? text : ""));
  cJSON_AddItemToArray(params, cJSON_CreateNumber((double)at_ms));
  return rpc_call("record", params, NULL);
}

int hg_grid_record_local_echo(const char *node, const char *kind,
                              const char *text) {
  echo_prepend(node, kind, text, now_ms());
  return 0;
}

int hg_grid_inscribe(const char *node, const char *name, const char *msg) {
  char text[240];
  if (node == NULL || name == NULL || msg == NULL || msg[0] == '\0') {
    return -1;
  }
  snprintf(text, sizeof(text), "%s: \"%s\"", name, msg);
  hg_grid_record_local_echo(node, "mark", text);
  hg_grid_record(g.world_name, node, "mark", text, now_ms());
  return 0;
}

int hg_grid_record_fallen(const char *world, const char *name,
                          const char *room, long long at_ms) {
  if (at_ms == 0) {
    at_ms = now_ms();
  }
  if (!g.remote) {
    int n = g.fallen_count < HG_MAX_FALLEN ? g.fallen_count : HG_MAX_FALLEN - 1;
    for (int i = n; i > 0; --i) {
      g.fallen[i] = g.fallen[i - 1];
    }
    safe_copy(g.fallen[0].world, sizeof(g.fallen[0].world), world);
    safe_copy(g.fallen[0].name, sizeof(g.fallen[0].name), name);
    safe_copy(g.fallen[0].room, sizeof(g.fallen[0].room), room);
    g.fallen[0].at = at_ms;
    if (g.fallen_count < HG_MAX_FALLEN) {
      g.fallen_count++;
    }
    return 0;
  }
  cJSON *params = cJSON_CreateArray();
  cJSON_AddItemToArray(params, cJSON_CreateString(world != NULL ? world : ""));
  cJSON_AddItemToArray(params, cJSON_CreateString(name != NULL ? name : ""));
  cJSON_AddItemToArray(params, cJSON_CreateString(room != NULL ? room : ""));
  cJSON_AddItemToArray(params, cJSON_CreateNumber((double)at_ms));
  return rpc_call("recordFallen", params, NULL);
}

int hg_grid_record_rescued(const char *world, const char *name,
                           const char *saved_by, long long at_ms) {
  if (at_ms == 0) {
    at_ms = now_ms();
  }
  if (!g.remote) {
    int n = g.rescued_count < HG_MAX_RESCUED ? g.rescued_count
                                             : HG_MAX_RESCUED - 1;
    for (int i = n; i > 0; --i) {
      g.rescued[i] = g.rescued[i - 1];
    }
    safe_copy(g.rescued[0].world, sizeof(g.rescued[0].world), world);
    safe_copy(g.rescued[0].name, sizeof(g.rescued[0].name), name);
    safe_copy(g.rescued[0].saved_by, sizeof(g.rescued[0].saved_by), saved_by);
    g.rescued[0].at = at_ms;
    if (g.rescued_count < HG_MAX_RESCUED) {
      g.rescued_count++;
    }
    char text[256];
    snprintf(text, sizeof(text), "%s freed by %s",
             name != NULL ? name : "", saved_by != NULL ? saved_by : "");
    trace_prepend(world, "rescued", "rescue", text, at_ms);
    return 0;
  }
  cJSON *params = cJSON_CreateArray();
  cJSON_AddItemToArray(params, cJSON_CreateString(world != NULL ? world : ""));
  cJSON_AddItemToArray(params, cJSON_CreateString(name != NULL ? name : ""));
  cJSON_AddItemToArray(params,
                      cJSON_CreateString(saved_by != NULL ? saved_by : ""));
  cJSON_AddItemToArray(params, cJSON_CreateNumber((double)at_ms));
  return rpc_call("recordRescued", params, NULL);
}

int hg_grid_on_kill(const char *room_id, const char *slayer,
                    const char *mob_name) {
  char text[256];
  snprintf(text, sizeof(text), "%s slew %s here.",
           slayer != NULL ? slayer : "someone",
           mob_name != NULL ? mob_name : "a mob");
  hg_grid_record(g.world_name, room_id, "slain", text, now_ms());
  hg_grid_record_local_echo(room_id, "slain", text);
  return 0;
}

int hg_grid_on_death(const char *room_id, const char *name) {
  hg_grid_record_fallen(g.world_name, name, room_id, now_ms());
  return 0;
}

/* ---------- register / presence / tick ---------- */

int hg_grid_register_self(void) {
  if (!g.remote) {
    for (int i = 0; i < g.trace_count; ++i) {
      if (strcmp(g.traces[i].world, g.world_name) == 0) {
        safe_copy(g.traces[i].node, sizeof(g.traces[i].node), g.world_url);
        return 0;
      }
    }
    trace_prepend(g.world_name, g.world_url, "register",
                 "a new node joined the network.", now_ms());
    return 0;
  }
  cJSON *params = cJSON_CreateArray();
  cJSON_AddItemToArray(params, cJSON_CreateString(g.world_name));
  cJSON_AddItemToArray(params, cJSON_CreateString(g.world_url));
  return rpc_call("register", params, NULL);
}

int hg_grid_report_presence_player(const char *name, const char *regard,
                                   const char *title, long long at_ms) {
  if (!g.remote) {
    return 0;
  }
  if (at_ms == 0) {
    at_ms = now_ms();
  }
  cJSON *params = cJSON_CreateArray();
  cJSON_AddItemToArray(params, cJSON_CreateString(g.world_name));
  cJSON *rows = cJSON_CreateArray();
  cJSON *row = cJSON_CreateObject();
  cJSON_AddStringToObject(row, "name", name != NULL ? name : "");
  cJSON_AddStringToObject(row, "regard", regard != NULL ? regard : "");
  cJSON_AddStringToObject(row, "title", title != NULL ? title : "");
  cJSON_AddItemToArray(rows, row);
  cJSON_AddItemToArray(params, rows);
  cJSON_AddItemToArray(params, cJSON_CreateNumber((double)at_ms));
  return rpc_call("reportPresence", params, NULL);
}

void hg_grid_federation_tick(long long now) {
  if (now == 0) {
    now = now_ms();
  }
  if (g.last_federation_tick_ms != 0 &&
      now - g.last_federation_tick_ms < HG_FEDERATION_TICK_MS) {
    return;
  }
  g.last_federation_tick_ms = now;
  if (!g.remote) {
    return;
  }
  hg_grid_register_self();
}

/* ---------- listWorlds (shared local/remote lookup) ---------- */

#define HG_MAX_WORLDS 8
typedef struct {
  char id[48];
  char url[160];
  long long last_seen;
} hg_world_row;

static int list_worlds(hg_world_row *out, int cap) {
  if (!g.remote) {
    int n = 0;
    long long now = now_ms();
    if (n < cap) {
      safe_copy(out[n].id, sizeof(out[n].id), "Saltreach");
      safe_copy(out[n].url, sizeof(out[n].url), "wss://saltreach.example/ws");
      out[n].last_seen = 0;
      n++;
    }
    if (n < cap) {
      safe_copy(out[n].id, sizeof(out[n].id), "Dustfall");
      safe_copy(out[n].url, sizeof(out[n].url),
               "wss://dustfall.skyphusion.org/ws");
      out[n].last_seen = now;
      n++;
    }
    if (n < cap) {
      safe_copy(out[n].id, sizeof(out[n].id), g.world_name);
      safe_copy(out[n].url, sizeof(out[n].url), g.world_url);
      out[n].last_seen = now;
      n++;
    }
    return n;
  }
  cJSON *result = NULL;
  if (rpc_call("listWorlds", cJSON_CreateArray(), &result) != 0) {
    return -1;
  }
  if (!cJSON_IsArray(result)) {
    cJSON_Delete(result);
    return -1;
  }
  int n = 0;
  const cJSON *row = NULL;
  cJSON_ArrayForEach(row, result) {
    if (n >= cap) {
      break;
    }
    safe_copy(out[n].id, sizeof(out[n].id), json_str(row, "id"));
    safe_copy(out[n].url, sizeof(out[n].url), json_str(row, "url"));
    out[n].last_seen = json_ll(row, "last_seen");
    n++;
  }
  cJSON_Delete(result);
  return n;
}

/* ---------- fmt: worlds / travel ---------- */

static int append(char *buf, size_t cap, size_t *off, const char *fmt, ...) {
  if (*off >= cap) {
    return -1;
  }
  va_list ap;
  va_start(ap, fmt);
  int n = vsnprintf(buf + *off, cap - *off, fmt, ap);
  va_end(ap);
  if (n < 0 || (size_t)n >= cap - *off) {
    return -1;
  }
  *off += (size_t)n;
  return 0;
}

int hg_grid_fmt_worlds(char *buf, size_t cap) {
  hg_world_row rows[HG_MAX_WORLDS];
  int n = list_worlds(rows, HG_MAX_WORLDS);
  size_t off = 0;
  if (n < 0) {
    if (append(buf, cap, &off,
              "The Grid is silent; the registry is out of reach.\r\n") != 0) {
      return -1;
    }
    return (int)off;
  }
  if (append(buf, cap, &off,
            "Worlds linked on the Grid (say 'travel <world>'):\r\n") != 0) {
    return -1;
  }
  long long now = now_ms();
  char json[1024];
  size_t joff = 0;
  json[0] = '\0';
  if (append(json, sizeof(json), &joff, "[") != 0) {
    return -1;
  }
  for (int i = 0; i < n; ++i) {
    int reachable = rows[i].last_seen > 0;
    int active = rows[i].last_seen > now - 60000;
    int here = strcmp(rows[i].id, g.world_name) == 0;
    const char *tag = "seeded (not yet live)";
    if (here) {
      tag = "you are here";
    } else if (reachable && active) {
      tag = "reachable, active now";
    } else if (reachable) {
      tag = "reachable, quiet";
    }
    if (append(buf, cap, &off, "  %s  [%s]\r\n", rows[i].id, tag) != 0) {
      return -1;
    }
    char idesc[64];
    json_escape(idesc, sizeof(idesc), rows[i].id);
    if (append(json, sizeof(json), &joff,
              "%s{\"id\":\"%s\",\"reachable\":%s,\"active\":%s,"
              "\"lastSeen\":%lld,\"here\":%s}",
              i == 0 ? "" : ",", idesc, reachable ? "true" : "false",
              active ? "true" : "false", rows[i].last_seen,
              here ? "true" : "false") != 0) {
      return -1;
    }
  }
  if (append(json, sizeof(json), &joff, "]") != 0) {
    return -1;
  }
  if (append(buf, cap, &off, "@event grid.worlds {\"worlds\":%s}\r\n",
            json) != 0) {
    return -1;
  }
  return (int)off;
}

int hg_grid_fmt_travel(char *buf, size_t cap, const char *target,
                       int *out_handoff) {
  if (out_handoff != NULL) {
    *out_handoff = 0;
  }
  if (target == NULL || target[0] == '\0') {
    return hg_grid_fmt_worlds(buf, cap);
  }
  hg_world_row rows[HG_MAX_WORLDS];
  int n = list_worlds(rows, HG_MAX_WORLDS);
  size_t off = 0;
  if (n < 0) {
    if (append(buf, cap, &off,
              "The Grid won't answer; travel is impossible right now.\r\n") !=
        0) {
      return -1;
    }
    return (int)off;
  }
  int match = -1;
  for (int i = 0; i < n; ++i) {
    if (ci_equal(rows[i].id, target)) {
      match = i;
      break;
    }
  }
  if (match < 0) {
    for (int i = 0; i < n; ++i) {
      /* substring, case-insensitive, small n so a naive scan is fine */
      char hay[64];
      char needle[64];
      safe_copy(hay, sizeof(hay), rows[i].id);
      safe_copy(needle, sizeof(needle), target);
      for (char *p = hay; *p != '\0'; ++p) {
        *p = (char)tolower((unsigned char)*p);
      }
      for (char *p = needle; *p != '\0'; ++p) {
        *p = (char)tolower((unsigned char)*p);
      }
      if (strstr(hay, needle) != NULL) {
        match = i;
        break;
      }
    }
  }
  if (match < 0) {
    if (append(buf, cap, &off,
              "No world called \"%s\" answers on the Grid. (try 'worlds')\r\n",
              target) != 0) {
      return -1;
    }
    return (int)off;
  }
  if (strcmp(rows[match].id, g.world_name) == 0) {
    if (append(buf, cap, &off, "You're already in %s.\r\n", g.world_name) !=
        0) {
      return -1;
    }
    return (int)off;
  }
  if (append(buf, cap, &off,
            "The Grid routes you toward %s. Reconnect there and your canonical "
            "character follows:\r\n"
            "    %s\r\n",
            rows[match].id, rows[match].url) != 0) {
    return -1;
  }
  char idesc[64];
  char udesc[176];
  json_escape(idesc, sizeof(idesc), rows[match].id);
  json_escape(udesc, sizeof(udesc), rows[match].url);
  if (append(buf, cap, &off, "@event grid.travel {\"to\":\"%s\",\"url\":\"%s\"}\r\n",
            idesc, udesc) != 0) {
    return -1;
  }
  if (out_handoff != NULL) {
    *out_handoff = 1;
  }
  return (int)off;
}

/* ---------- fmt: listen / ping ---------- */

int hg_grid_fmt_listen(char *buf, size_t cap) {
  size_t off = 0;
  if (g.echo_count > 0) {
    const hg_echo *e = &g.echo[rand() % g.echo_count];
    char esc[220];
    json_escape(esc, sizeof(esc), e->text);
    if (append(buf, cap, &off,
              "You go still and tune the dead frequencies. The static "
              "thins, and the network plays something back -- a memory it "
              "never let go of:\r\n  >> %s <<\r\n"
              "@event grid.transmission {\"kind\":\"echo\",\"text\":\"%s\"}\r\n",
              e->text, esc) != 0) {
      return -1;
    }
    return (int)off;
  }
  hg_trace remote_trace = {0};
  const hg_trace *t = NULL;
  if (g.remote) {
    cJSON *params = cJSON_CreateArray();
    cJSON_AddItemToArray(params, cJSON_CreateNumber(20));
    cJSON *result = NULL;
    if (rpc_call("recent", params, &result) == 0 && cJSON_IsArray(result)) {
      int count = cJSON_GetArraySize(result);
      const cJSON *row =
          count > 0 ? cJSON_GetArrayItem(result, rand() % count) : NULL;
      if (cJSON_IsObject(row)) {
        safe_copy(remote_trace.world, sizeof(remote_trace.world),
                  json_str(row, "world"));
        safe_copy(remote_trace.node, sizeof(remote_trace.node),
                  json_str(row, "node"));
        safe_copy(remote_trace.kind, sizeof(remote_trace.kind),
                  json_str(row, "kind"));
        safe_copy(remote_trace.text, sizeof(remote_trace.text),
                  json_str(row, "text"));
        remote_trace.at = json_ll(row, "at");
        if (remote_trace.text[0] != '\0') {
          t = &remote_trace;
        }
      }
    }
    cJSON_Delete(result);
  } else if (g.trace_count > 0) {
    t = &g.traces[rand() % g.trace_count];
  }
  if (t != NULL) {
    char esc[220];
    json_escape(esc, sizeof(esc), t->text);
    if (append(buf, cap, &off,
              "You go still and tune the dead frequencies. The static "
              "thins, and the network plays something back -- a memory it "
              "never let go of:\r\n  >> %s <<\r\n",
              t->text) != 0) {
      return -1;
    }
    if (strcmp(t->world, g.world_name) != 0 && t->world[0] != '\0') {
      if (append(buf, cap, &off,
                "  (...the signal carries from somewhere called %s)\r\n",
                t->world) != 0) {
        return -1;
      }
    }
    if (append(buf, cap, &off,
              "@event grid.transmission {\"kind\":\"echo\",\"text\":\"%s\"}\r\n",
              esc) != 0) {
      return -1;
    }
    return (int)off;
  }
  if (append(buf, cap, &off,
            "You go still and tune the dead frequencies. Only static "
            "answers; the deep memory here is empty.\r\n"
            "@event grid.transmission {\"kind\":\"empty\",\"text\":\"\"}\r\n") !=
      0) {
    return -1;
  }
  return (int)off;
}

int hg_grid_fmt_ping_echo(char *buf, size_t cap, const char *room_id) {
  size_t off = 0;
  const hg_echo *rows[6];
  int n = 0;
  for (int i = 0; i < g.echo_count && n < 6; ++i) {
    if (strcmp(g.echo[i].node, room_id) == 0) {
      rows[n++] = &g.echo[i];
    }
  }
  char json[1536];
  size_t joff = 0;
  json[0] = '\0';
  if (append(json, sizeof(json), &joff, "[") != 0) {
    return -1;
  }
  if (n == 0) {
    if (append(buf, cap, &off,
              "You key into the dead Grid. Static, a cold hum... but this "
              "node remembers nothing. Not yet. (try 'ping all')\r\n") != 0) {
      return -1;
    }
  } else {
    if (append(buf, cap, &off,
              "You key into the dead Grid. Static, then it remembers:\r\n") !=
        0) {
      return -1;
    }
    for (int i = 0; i < n; ++i) {
      if (append(buf, cap, &off, "  - %s\r\n", rows[i]->text) != 0) {
        return -1;
      }
      char esc[220];
      json_escape(esc, sizeof(esc), rows[i]->text);
      char kesc[32];
      json_escape(kesc, sizeof(kesc), rows[i]->kind);
      if (append(json, sizeof(json), &joff,
                "%s{\"kind\":\"%s\",\"text\":\"%s\",\"at\":%lld}",
                i == 0 ? "" : ",", kesc, esc, rows[i]->at) != 0) {
        return -1;
      }
    }
    if (append(buf, cap, &off,
              "  (say 'ping all' to hear the whole network)\r\n") != 0) {
      return -1;
    }
  }
  if (append(json, sizeof(json), &joff, "]") != 0) {
    return -1;
  }
  char resc[80];
  json_escape(resc, sizeof(resc), room_id);
  if (append(buf, cap, &off, "@event grid.echo {\"node\":\"%s\",\"traces\":%s}\r\n",
            resc, json) != 0) {
    return -1;
  }
  return (int)off;
}

int hg_grid_fmt_ping_all(char *buf, size_t cap) {
  size_t off = 0;
  hg_trace rows[8];
  int n = 0;
  if (!g.remote) {
    for (int i = 0; i < g.trace_count && n < 8; ++i) {
      if (strcmp(g.traces[i].world, g.world_name) != 0) {
        rows[n++] = g.traces[i];
      }
    }
  } else {
    cJSON *result = NULL;
    cJSON *params = cJSON_CreateArray();
    cJSON_AddItemToArray(params, cJSON_CreateString(g.world_name));
    cJSON_AddItemToArray(params, cJSON_CreateNumber(8));
    if (rpc_call("recentAcross", params, &result) == 0 &&
        cJSON_IsArray(result)) {
      const cJSON *row = NULL;
      cJSON_ArrayForEach(row, result) {
        if (n >= 8) {
          break;
        }
        safe_copy(rows[n].world, sizeof(rows[n].world), json_str(row, "world"));
        safe_copy(rows[n].node, sizeof(rows[n].node), json_str(row, "node"));
        safe_copy(rows[n].kind, sizeof(rows[n].kind), json_str(row, "kind"));
        safe_copy(rows[n].text, sizeof(rows[n].text), json_str(row, "text"));
        rows[n].at = json_ll(row, "at");
        n++;
      }
    }
    cJSON_Delete(result);
  }
  if (n == 0) {
    if (append(buf, cap, &off,
              "The deep Grid hums, vast and empty. Nothing echoes back from "
              "the other nodes -- yet.\r\n"
              "@event grid.federation {\"traces\":[]}\r\n") != 0) {
      return -1;
    }
    return (int)off;
  }
  if (append(buf, cap, &off,
            "You key past your own node, into the whole dead network. It "
            "remembers, from across the Grid:\r\n") != 0) {
    return -1;
  }
  char json[2048];
  size_t joff = 0;
  json[0] = '\0';
  if (append(json, sizeof(json), &joff, "[") != 0) {
    return -1;
  }
  for (int i = 0; i < n; ++i) {
    if (append(buf, cap, &off, "  - [%s] %s\r\n", rows[i].world,
              rows[i].text) != 0) {
      return -1;
    }
    char wesc[64];
    char nesc[80];
    char kesc[32];
    char tesc[220];
    json_escape(wesc, sizeof(wesc), rows[i].world);
    json_escape(nesc, sizeof(nesc), rows[i].node);
    json_escape(kesc, sizeof(kesc), rows[i].kind);
    json_escape(tesc, sizeof(tesc), rows[i].text);
    if (append(json, sizeof(json), &joff,
              "%s{\"world\":\"%s\",\"node\":\"%s\",\"kind\":\"%s\","
              "\"text\":\"%s\",\"at\":%lld}",
              i == 0 ? "" : ",", wesc, nesc, kesc, tesc, rows[i].at) != 0) {
      return -1;
    }
  }
  if (append(json, sizeof(json), &joff, "]") != 0) {
    return -1;
  }
  if (append(buf, cap, &off, "@event grid.federation {\"traces\":%s}\r\n",
            json) != 0) {
    return -1;
  }
  return (int)off;
}

/* ---------- fmt: whoami ---------- */

int hg_grid_fmt_whoami(char *buf, size_t cap, const hg_grid_identity_ctx *ctx) {
  size_t off = 0;
  long level = ctx->level;
  long xp = ctx->xp;
  long gold = ctx->gold;
  long morality = ctx->morality;
  long ashsworn = ctx->ashsworn;
  char faction[16];
  char title[48];
  char race[16];
  safe_copy(faction, sizeof(faction), ctx->faction);
  safe_copy(title, sizeof(title), ctx->title);
  safe_copy(race, sizeof(race), ctx->race);

  if (g.remote) {
    cJSON *result = NULL;
    cJSON *params = cJSON_CreateArray();
    cJSON_AddItemToArray(params,
                        cJSON_CreateString(ctx->name != NULL ? ctx->name : ""));
    if (rpc_call("loadCharacter", params, &result) == 0 &&
        cJSON_IsObject(result)) {
      long hub_level = json_num(result, "level", 1);
      long hub_xp = json_num(result, "xp", 0);
      const char *hub_race = json_str(result, "race");
      const char *hub_faction = json_str(result, "faction");
      long hub_morality = json_num(result, "morality", 0);
      int found = hub_race[0] != '\0' || hub_level > 1 || hub_xp > 0 ||
                  hub_faction[0] != '\0' || hub_morality != 0;
      if (found) {
        level = hub_level;
        xp = hub_xp;
        gold = json_num(result, "gold", gold);
        morality = hub_morality;
        safe_copy(race, sizeof(race), hub_race);
        /* Session-local standing wins over a stale hub read. */
        if (!(strcmp(faction, "ally") == 0 || strcmp(faction, "front") == 0)) {
          safe_copy(faction, sizeof(faction), hub_faction);
        }
        const char *hub_title = json_str(result, "title");
        if (title[0] == '\0') {
          safe_copy(title, sizeof(title), hub_title);
        }
        const cJSON *ash = cJSON_GetObjectItemCaseSensitive(result, "ashsworn");
        ashsworn = cJSON_IsTrue(ash) ? 1 : 0;
      }
    } else {
      if (append(buf, cap, &off,
                "(the Grid is unreachable; showing your local self)\r\n") !=
          0) {
        return -1;
      }
    }
    cJSON_Delete(result);
  }

  char nesc[40];
  char fesc[24];
  char tesc[64];
  char resc[24];
  json_escape(nesc, sizeof(nesc), ctx->name);
  json_escape(fesc, sizeof(fesc), faction[0] != '\0' ? faction : "none");
  json_escape(tesc, sizeof(tesc), title);
  json_escape(resc, sizeof(resc), race[0] != '\0' ? race : "human");

  if (append(buf, cap, &off,
            "The Grid reads you back: %s, level %ld %s%s%s, %s standing, "
            "morality %ld.\r\n",
            ctx->name != NULL ? ctx->name : "", level,
            race[0] != '\0' ? race : "human", title[0] != '\0' ? " " : "",
            title, faction[0] != '\0' ? faction : "unaligned", morality) !=
      0) {
    return -1;
  }
  if (append(buf, cap, &off,
            "@event char.identity {\"name\":\"%s\",\"level\":%ld,\"xp\":%ld,"
            "\"gold\":%ld,\"faction\":\"%s\",\"morality\":%ld,\"title\":\"%s\","
            "\"race\":\"%s\",\"ashsworn\":%s}\r\n",
            nesc, level, xp, gold, fesc, morality, tesc, resc,
            ashsworn ? "true" : "false") != 0) {
    return -1;
  }
  return (int)off;
}

/* ---------- remaining RPC surface (tide, gridcast, ledger, presence) ---------- */

int hg_grid_tide(int *out_tide) {
  if (!g.remote) {
    if (out_tide != NULL) {
      *out_tide = g.tide;
    }
    return 0;
  }
  cJSON *result = NULL;
  if (rpc_call("tide", cJSON_CreateArray(), &result) != 0) {
    return -1;
  }
  if (out_tide != NULL) {
    *out_tide = cJSON_IsNumber(result) ? (int)result->valuedouble : 0;
  }
  cJSON_Delete(result);
  return 0;
}

int hg_grid_shift_tide(int delta, int *out_tide) {
  if (!g.remote) {
    g.tide = clamp_tide(g.tide + delta);
    if (out_tide != NULL) {
      *out_tide = g.tide;
    }
    return 0;
  }
  cJSON *params = cJSON_CreateArray();
  cJSON_AddItemToArray(params, cJSON_CreateNumber(delta));
  cJSON *result = NULL;
  if (rpc_call("shiftTide", params, &result) != 0) {
    return -1;
  }
  if (out_tide != NULL) {
    *out_tide = cJSON_IsNumber(result) ? (int)result->valuedouble : 0;
  }
  cJSON_Delete(result);
  return 0;
}

int hg_grid_gridcast(const char *sender, const char *text) {
  if (!g.remote) {
    hg_grid_cast_row *row = &g.casts[g.cast_count % HG_MAX_CASTS];
    g.next_cast_id++;
    row->id = g.next_cast_id;
    safe_copy(row->world, sizeof(row->world), g.world_name);
    safe_copy(row->sender, sizeof(row->sender), sender);
    safe_copy(row->text, sizeof(row->text), text);
    if (g.cast_count < HG_MAX_CASTS) {
      g.cast_count++;
    }
    return 0;
  }
  cJSON *params = cJSON_CreateArray();
  cJSON_AddItemToArray(params, cJSON_CreateString(g.world_name));
  cJSON_AddItemToArray(params, cJSON_CreateString(sender != NULL ? sender : ""));
  cJSON_AddItemToArray(params, cJSON_CreateString(text != NULL ? text : ""));
  return rpc_call("gridcast", params, NULL);
}

int hg_grid_casts_since(int since_id, int limit, hg_grid_cast_row *out,
                       size_t cap, size_t *out_count) {
  if (out_count != NULL) {
    *out_count = 0;
  }
  if (!g.remote) {
    size_t n = 0;
    for (int i = 0; i < g.cast_count && n < cap; ++i) {
      if (g.casts[i].id > since_id) {
        out[n++] = g.casts[i];
      }
    }
    if (limit > 0 && n > (size_t)limit) {
      n = (size_t)limit;
    }
    if (out_count != NULL) {
      *out_count = n;
    }
    return 0;
  }
  cJSON *params = cJSON_CreateArray();
  cJSON_AddItemToArray(params, cJSON_CreateNumber(since_id));
  cJSON_AddItemToArray(params, cJSON_CreateNumber(limit));
  cJSON *result = NULL;
  if (rpc_call("castsSince", params, &result) != 0) {
    return -1;
  }
  if (!cJSON_IsArray(result)) {
    cJSON_Delete(result);
    return -1;
  }
  size_t n = 0;
  const cJSON *row = NULL;
  cJSON_ArrayForEach(row, result) {
    if (n >= cap) {
      break;
    }
    out[n].id = (int)json_num(row, "id", 0);
    safe_copy(out[n].world, sizeof(out[n].world), json_str(row, "world"));
    safe_copy(out[n].sender, sizeof(out[n].sender), json_str(row, "sender"));
    safe_copy(out[n].text, sizeof(out[n].text), json_str(row, "text"));
    n++;
  }
  cJSON_Delete(result);
  if (out_count != NULL) {
    *out_count = n;
  }
  return 0;
}

int hg_grid_presence(long long max_age_ms, hg_grid_presence_row *out,
                    size_t cap, size_t *out_count) {
  if (out_count != NULL) {
    *out_count = 0;
  }
  (void)max_age_ms;
  if (!g.remote) {
    return 0;
  }
  cJSON *params = cJSON_CreateArray();
  cJSON_AddItemToArray(params, cJSON_CreateNumber((double)max_age_ms));
  cJSON *result = NULL;
  if (rpc_call("presence", params, &result) != 0) {
    return -1;
  }
  if (!cJSON_IsArray(result)) {
    cJSON_Delete(result);
    return -1;
  }
  size_t n = 0;
  const cJSON *row = NULL;
  cJSON_ArrayForEach(row, result) {
    if (n >= cap) {
      break;
    }
    safe_copy(out[n].world, sizeof(out[n].world), json_str(row, "world"));
    safe_copy(out[n].name, sizeof(out[n].name), json_str(row, "name"));
    safe_copy(out[n].regard, sizeof(out[n].regard), json_str(row, "regard"));
    safe_copy(out[n].title, sizeof(out[n].title), json_str(row, "title"));
    out[n].at = json_ll(row, "at");
    n++;
  }
  cJSON_Delete(result);
  if (out_count != NULL) {
    *out_count = n;
  }
  return 0;
}

int hg_grid_commit_character(const char *name,
                             const hg_grid_identity_ctx *ctx) {
  if (!g.remote) {
    return 0;
  }
  cJSON *params = cJSON_CreateArray();
  cJSON_AddItemToArray(params, cJSON_CreateString(name != NULL ? name : ""));
  cJSON *obj = cJSON_CreateObject();
  cJSON_AddNumberToObject(obj, "level", (double)ctx->level);
  cJSON_AddNumberToObject(obj, "xp", (double)ctx->xp);
  cJSON_AddNumberToObject(obj, "gold", (double)ctx->gold);
  cJSON_AddStringToObject(obj, "faction",
                          ctx->faction != NULL ? ctx->faction : "");
  cJSON_AddNumberToObject(obj, "morality", (double)ctx->morality);
  cJSON_AddStringToObject(obj, "title", ctx->title != NULL ? ctx->title : "");
  cJSON_AddStringToObject(obj, "race", ctx->race != NULL ? ctx->race : "");
  cJSON_AddBoolToObject(obj, "ashsworn", ctx->ashsworn != 0);
  cJSON_AddItemToArray(params, obj);
  return rpc_call("commitCharacter", params, NULL);
}

int hg_grid_load_session(void *session) {
  if (!g.remote || session == NULL) {
    return 0;
  }
  const char *name = hg_s_str(session, HG_SESSION_NAME);
  if (name == NULL || name[0] == '\0') {
    return 0;
  }
  cJSON *params = cJSON_CreateArray();
  cJSON_AddItemToArray(params, cJSON_CreateString(name));
  cJSON *result = NULL;
  if (rpc_call("loadCharacter", params, &result) != 0) {
    return -1;
  }
  if (!cJSON_IsObject(result)) {
    cJSON_Delete(result);
    return -1;
  }
  const char *race = json_str(result, "race");
  if (race[0] == '\0') {
    cJSON_Delete(result);
    return 0;
  }
  hg_s_set_i64(session, HG_SESSION_LEVEL, json_num(result, "level", 1));
  hg_s_set_i64(session, HG_SESSION_XP, json_num(result, "xp", 0));
  hg_s_set_i64(session, HG_SESSION_GOLD, json_num(result, "gold", 20));
  hg_s_set_i64(session, HG_SESSION_MORALITY,
               json_num(result, "morality", 0));
  const cJSON *ashsworn =
      cJSON_GetObjectItemCaseSensitive(result, "ashsworn");
  hg_s_set_i64(session, HG_SESSION_ASHSWORN,
               cJSON_IsTrue(ashsworn) ? 1 : 0);
  safe_copy(hg_s_str_mut(session, HG_SESSION_FACTION), 16,
            json_str(result, "faction"));
  safe_copy(hg_s_str_mut(session, HG_SESSION_TITLE), 48,
            json_str(result, "title"));
  safe_copy(hg_s_str_mut(session, HG_SESSION_RACE), 16, race);
  cJSON_Delete(result);
  return 1;
}

int hg_grid_commit_session(void *session) {
  if (!g.remote || session == NULL) {
    return 0;
  }
  hg_grid_identity_ctx ctx = {
      .name = hg_s_str(session, HG_SESSION_NAME),
      .level = (long)hg_s_i64(session, HG_SESSION_LEVEL),
      .xp = (long)hg_s_i64(session, HG_SESSION_XP),
      .gold = (long)hg_s_i64(session, HG_SESSION_GOLD),
      .faction = hg_s_str(session, HG_SESSION_FACTION),
      .morality = (long)hg_s_i64(session, HG_SESSION_MORALITY),
      .title = hg_s_str(session, HG_SESSION_TITLE),
      .race = hg_s_str(session, HG_SESSION_RACE),
      .ashsworn = (long)hg_s_i64(session, HG_SESSION_ASHSWORN),
  };
  return hg_grid_commit_character(ctx.name, &ctx);
}

int hg_grid_recent_rescued(int limit, hg_grid_rescued_row *out, size_t cap,
                          size_t *out_count) {
  if (out_count != NULL) {
    *out_count = 0;
  }
  if (!g.remote) {
    size_t n = (size_t)g.rescued_count < cap ? (size_t)g.rescued_count : cap;
    if (limit > 0 && n > (size_t)limit) {
      n = (size_t)limit;
    }
    for (size_t i = 0; i < n; ++i) {
      safe_copy(out[i].world, sizeof(out[i].world), g.rescued[i].world);
      safe_copy(out[i].name, sizeof(out[i].name), g.rescued[i].name);
      safe_copy(out[i].saved_by, sizeof(out[i].saved_by),
               g.rescued[i].saved_by);
      out[i].at = g.rescued[i].at;
    }
    if (out_count != NULL) {
      *out_count = n;
    }
    return 0;
  }
  cJSON *params = cJSON_CreateArray();
  cJSON_AddItemToArray(params, cJSON_CreateNumber(limit));
  cJSON *result = NULL;
  if (rpc_call("recentRescued", params, &result) != 0) {
    return -1;
  }
  if (!cJSON_IsArray(result)) {
    cJSON_Delete(result);
    return -1;
  }
  size_t n = 0;
  const cJSON *row = NULL;
  cJSON_ArrayForEach(row, result) {
    if (n >= cap) {
      break;
    }
    safe_copy(out[n].world, sizeof(out[n].world), json_str(row, "world"));
    safe_copy(out[n].name, sizeof(out[n].name), json_str(row, "name"));
    safe_copy(out[n].saved_by, sizeof(out[n].saved_by),
             json_str(row, "savedBy"));
    out[n].at = json_ll(row, "at");
    n++;
  }
  cJSON_Delete(result);
  if (out_count != NULL) {
    *out_count = n;
  }
  return 0;
}

int hg_grid_recent_fallen(int limit, hg_grid_fallen_row *out, size_t cap,
                         size_t *out_count) {
  if (out_count != NULL) {
    *out_count = 0;
  }
  if (!g.remote) {
    size_t n = (size_t)g.fallen_count < cap ? (size_t)g.fallen_count : cap;
    if (limit > 0 && n > (size_t)limit) {
      n = (size_t)limit;
    }
    for (size_t i = 0; i < n; ++i) {
      safe_copy(out[i].world, sizeof(out[i].world), g.fallen[i].world);
      safe_copy(out[i].name, sizeof(out[i].name), g.fallen[i].name);
      safe_copy(out[i].room, sizeof(out[i].room), g.fallen[i].room);
      out[i].at = g.fallen[i].at;
    }
    if (out_count != NULL) {
      *out_count = n;
    }
    return 0;
  }
  cJSON *params = cJSON_CreateArray();
  cJSON_AddItemToArray(params, cJSON_CreateNumber(limit));
  cJSON *result = NULL;
  if (rpc_call("recentFallen", params, &result) != 0) {
    return -1;
  }
  if (!cJSON_IsArray(result)) {
    cJSON_Delete(result);
    return -1;
  }
  size_t n = 0;
  const cJSON *row = NULL;
  cJSON_ArrayForEach(row, result) {
    if (n >= cap) {
      break;
    }
    safe_copy(out[n].world, sizeof(out[n].world), json_str(row, "world"));
    safe_copy(out[n].name, sizeof(out[n].name), json_str(row, "name"));
    safe_copy(out[n].room, sizeof(out[n].room), json_str(row, "room"));
    out[n].at = json_ll(row, "at");
    n++;
  }
  cJSON_Delete(result);
  if (out_count != NULL) {
    *out_count = n;
  }
  return 0;
}

int hg_grid_ledger_stats(hg_grid_ledger_row *out, size_t cap,
                        size_t *out_count) {
  if (out_count != NULL) {
    *out_count = 0;
  }
  if (!g.remote) {
    /* Local ledger stats are a courtesy tally of the cross-world trace kinds
     * this node has seen; not authoritative like a real hub. */
    size_t n = 0;
    for (int i = 0; i < g.trace_count; ++i) {
      size_t j = 0;
      for (; j < n; ++j) {
        if (strcmp(out[j].kind, g.traces[i].kind) == 0) {
          out[j].count++;
          break;
        }
      }
      if (j == n && n < cap) {
        safe_copy(out[n].kind, sizeof(out[n].kind), g.traces[i].kind);
        out[n].count = 1;
        n++;
      }
    }
    if (out_count != NULL) {
      *out_count = n;
    }
    return 0;
  }
  cJSON *result = NULL;
  if (rpc_call("ledgerStats", cJSON_CreateArray(), &result) != 0) {
    return -1;
  }
  if (!cJSON_IsArray(result)) {
    cJSON_Delete(result);
    return -1;
  }
  size_t n = 0;
  const cJSON *row = NULL;
  cJSON_ArrayForEach(row, result) {
    if (n < cap) {
      safe_copy(out[n].kind, sizeof(out[n].kind), json_str(row, "kind"));
      out[n].count = (int)json_num(row, "count", 0);
      n++;
    }
  }
  cJSON_Delete(result);
  if (out_count != NULL) {
    *out_count = n;
  }
  return 0;
}

int hg_grid_prune_ledger(int *removed) {
  if (!g.remote) {
    int before = g.trace_count;
    int write = 0;
    for (int i = 0; i < g.trace_count; ++i) {
      const char *kind = g.traces[i].kind;
      if (strcmp(kind, "ghost") == 0 || strcmp(kind, "passage") == 0 ||
          strcmp(kind, "recall") == 0) {
        continue;
      }
      if (write != i) {
        g.traces[write] = g.traces[i];
      }
      write++;
    }
    g.trace_count = write;
    if (removed != NULL) {
      *removed = before - write;
    }
    return 0;
  }
  cJSON *params = cJSON_CreateArray();
  cJSON *kinds = cJSON_CreateArray();
  cJSON_AddItemToArray(kinds, cJSON_CreateString("ghost"));
  cJSON_AddItemToArray(kinds, cJSON_CreateString("passage"));
  cJSON_AddItemToArray(kinds, cJSON_CreateString("recall"));
  cJSON_AddItemToArray(params, kinds);
  cJSON *result = NULL;
  if (rpc_call("pruneLedgerKinds", params, &result) != 0) {
    return -1;
  }
  if (removed != NULL) {
    *removed = cJSON_IsObject(result) ? (int)json_num(result, "removed", 0) : 0;
  }
  cJSON_Delete(result);
  return 0;
}
