/* Grid Hub federation client: RemoteHub (libcurl/cJSON) plus prose/@event
 * wrappers. LocalHub memory, tide clamp, and prune application live in
 * asm/grid_local.asm. See include/hg_grid.h and docs/ARCHITECTURE.md.
 */
#include "hg_grid.h"
#include "hg_session.h"

#include <cjson/cJSON.h>
#include <curl/curl.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <time.h>

/* Asm: LocalHub store + prune kinds. */
extern int hg_prune_kind_ambient(const char *kind);
extern int hg_prune_ambient_count(void);
extern const char *hg_prune_ambient_at(int index);
extern int hg_grid_local_boot(const char *world_name, const char *world_url);
extern int hg_grid_local_clear(void);
extern const char *hg_grid_local_world_name(void);
extern const char *hg_grid_local_world_url(void);
extern int hg_grid_local_record(const char *world, const char *node,
                                const char *kind, const char *text,
                                long long at_ms);
extern int hg_grid_record_local_echo(const char *node, const char *kind,
                                     const char *text);
extern int hg_grid_local_record_fallen(const char *world, const char *name,
                                       const char *room, long long at_ms);
extern int hg_grid_local_record_rescued(const char *world, const char *name,
                                        const char *saved_by, long long at_ms);
extern int hg_grid_local_tide(int *out_tide);
extern int hg_grid_local_shift_tide(int delta, int *out_tide);
extern int hg_grid_local_gridcast(const char *sender, const char *text);
extern int hg_grid_local_register_self(void);
extern int hg_grid_local_prune(int *removed);
extern int hg_grid_local_recent_rescued(int limit, hg_grid_rescued_row *out,
                                        size_t cap, size_t *out_count);
extern int hg_grid_local_recent_fallen(int limit, hg_grid_fallen_row *out,
                                       size_t cap, size_t *out_count);
extern int hg_grid_local_ledger_stats(hg_grid_ledger_row *out, size_t cap,
                                      size_t *out_count);
extern int hg_grid_local_casts_since(int since_id, int limit,
                                     hg_grid_cast_row *out, size_t cap,
                                     size_t *out_count);
extern int hg_grid_local_echo_count(void);
extern int hg_grid_local_trace_count(void);
extern int hg_grid_local_echo_ptrs(int index, const char **node,
                                   const char **kind, const char **text,
                                   long long *at);
extern int hg_grid_local_trace_ptrs(int index, const char **world,
                                    const char **node, const char **kind,
                                    const char **text, long long *at);
extern int hg_grid_local_list_worlds(char *ids, char *urls, long long *seen,
                                     int cap);

#define HG_RPC_TIMEOUT_MS 2000L
#define HG_FEDERATION_TICK_MS 10000LL

static struct {
  int booted;
  int remote;
  char world_name[64];
  char world_url[160];
  char hub_url[256];
  char token[256];
  CURL *curl;
  int curl_global_owned;
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
    hg_grid_local_boot(g.world_name, g.world_url);
    g.booted = 1;
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
    hg_grid_local_boot(g.world_name, g.world_url);
    g.booted = 1;
    return 0;
  }
  g.curl_global_owned = 1;
  g.curl = curl_easy_init();
  if (g.curl == NULL) {
    curl_global_cleanup();
    g.curl_global_owned = 0;
    g.remote = 0;
    hg_grid_local_boot(g.world_name, g.world_url);
    g.booted = 1;
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
  hg_grid_local_clear();
  g.remote = 0;
  g.booted = 0;
}

int hg_grid_remote(void) { return g.remote; }

/* Configured world id, so @event payloads that claim a world id report the
 * name this node was booted with instead of a hardcoded literal. */
const char *hg_grid_world_name(void) {
  return g.world_name[0] != '\0' ? g.world_name : "Basalt Relay";
}

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
    return hg_grid_local_record(world, node, kind, text, at_ms);
  }
  cJSON *params = cJSON_CreateArray();
  cJSON_AddItemToArray(params, cJSON_CreateString(world != NULL ? world : ""));
  cJSON_AddItemToArray(params, cJSON_CreateString(node != NULL ? node : ""));
  cJSON_AddItemToArray(params, cJSON_CreateString(kind != NULL ? kind : ""));
  cJSON_AddItemToArray(params, cJSON_CreateString(text != NULL ? text : ""));
  cJSON_AddItemToArray(params, cJSON_CreateNumber((double)at_ms));
  return rpc_call("record", params, NULL);
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
    return hg_grid_local_record_fallen(world, name, room, at_ms);
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
    return hg_grid_local_record_rescued(world, name, saved_by, at_ms);
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
    return hg_grid_local_register_self();
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

int hg_grid_list_worlds(hg_grid_world_row *out, size_t cap, size_t *out_count) {
  if (out_count != NULL) {
    *out_count = 0;
  }
  if (out == NULL || cap == 0) {
    return -1;
  }
  int icap = (int)(cap > (size_t)HG_GRID_MAX_WORLDS ? HG_GRID_MAX_WORLDS
                                                    : cap);
  if (!g.remote) {
    char ids[8][48];
    char urls[8][160];
    long long seen[8];
    int n = hg_grid_local_list_worlds(&ids[0][0], &urls[0][0], seen,
                                      icap < 8 ? icap : 8);
    for (int i = 0; i < n; ++i) {
      safe_copy(out[i].id, sizeof(out[i].id), ids[i]);
      safe_copy(out[i].url, sizeof(out[i].url), urls[i]);
      out[i].last_seen = seen[i];
    }
    if (out_count != NULL) {
      *out_count = (size_t)n;
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
    if (n >= icap) {
      break;
    }
    safe_copy(out[n].id, sizeof(out[n].id), json_str(row, "id"));
    safe_copy(out[n].url, sizeof(out[n].url), json_str(row, "url"));
    out[n].last_seen = json_ll(row, "last_seen");
    n++;
  }
  cJSON_Delete(result);
  if (out_count != NULL) {
    *out_count = (size_t)n;
  }
  return n;
}

int hg_grid_fetch_character(const char *name, hg_grid_character_row *out) {
  if (out == NULL) {
    return -1;
  }
  memset(out, 0, sizeof(*out));
  if (!g.remote) {
    return 0;
  }
  cJSON *result = NULL;
  cJSON *params = cJSON_CreateArray();
  cJSON_AddItemToArray(params,
                       cJSON_CreateString(name != NULL ? name : ""));
  if (rpc_call("loadCharacter", params, &result) != 0) {
    cJSON_Delete(result);
    return -1;
  }
  if (!cJSON_IsObject(result)) {
    cJSON_Delete(result);
    return -1;
  }
  out->present = 1;
  out->level = json_num(result, "level", 1);
  out->xp = json_num(result, "xp", 0);
  out->gold = json_num(result, "gold", 20);
  out->morality = json_num(result, "morality", 0);
  safe_copy(out->faction, sizeof(out->faction), json_str(result, "faction"));
  safe_copy(out->title, sizeof(out->title), json_str(result, "title"));
  safe_copy(out->race, sizeof(out->race), json_str(result, "race"));
  const cJSON *ash = cJSON_GetObjectItemCaseSensitive(result, "ashsworn");
  out->ashsworn = cJSON_IsTrue(ash) ? 1 : 0;
  cJSON_Delete(result);
  return 0;
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
  hg_grid_world_row rows[HG_GRID_MAX_WORLDS];
  int n = hg_grid_list_worlds(rows, HG_GRID_MAX_WORLDS, NULL);
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

/* ---------- fmt: listen / ping ---------- */

int hg_grid_fmt_listen(char *buf, size_t cap) {
  size_t off = 0;
  int echo_n = hg_grid_local_echo_count();
  if (echo_n > 0) {
    const char *node = NULL;
    const char *kind = NULL;
    const char *etext = NULL;
    long long at = 0;
    int idx = rand() % echo_n;
    if (hg_grid_local_echo_ptrs(idx, &node, &kind, &etext, &at) != 0) {
      etext = "";
    }
    (void)node;
    (void)kind;
    char esc[220];
    json_escape(esc, sizeof(esc), etext);
    if (append(buf, cap, &off,
              "You go still and tune the dead frequencies. The static "
              "thins, and the network plays something back -- a memory it "
              "never let go of:\r\n  >> %s <<\r\n"
              "@event grid.transmission {\"kind\":\"echo\",\"text\":\"%s\"}\r\n",
              etext, esc) != 0) {
      return -1;
    }
    return (int)off;
  }
  char world[48] = {0};
  char node[64] = {0};
  char kind[24] = {0};
  char ttext[200] = {0};
  long long at = 0;
  int have = 0;
  if (g.remote) {
    cJSON *params = cJSON_CreateArray();
    cJSON_AddItemToArray(params, cJSON_CreateNumber(20));
    cJSON *result = NULL;
    if (rpc_call("recent", params, &result) == 0 && cJSON_IsArray(result)) {
      int count = cJSON_GetArraySize(result);
      const cJSON *row =
          count > 0 ? cJSON_GetArrayItem(result, rand() % count) : NULL;
      if (cJSON_IsObject(row)) {
        safe_copy(world, sizeof(world), json_str(row, "world"));
        safe_copy(node, sizeof(node), json_str(row, "node"));
        safe_copy(kind, sizeof(kind), json_str(row, "kind"));
        safe_copy(ttext, sizeof(ttext), json_str(row, "text"));
        at = json_ll(row, "at");
        if (ttext[0] != '\0') {
          have = 1;
        }
      }
    }
    cJSON_Delete(result);
  } else if (hg_grid_local_trace_count() > 0) {
    const char *w = NULL;
    const char *n = NULL;
    const char *k = NULL;
    const char *t = NULL;
    int idx = rand() % hg_grid_local_trace_count();
    if (hg_grid_local_trace_ptrs(idx, &w, &n, &k, &t, &at) == 0) {
      safe_copy(world, sizeof(world), w);
      safe_copy(node, sizeof(node), n);
      safe_copy(kind, sizeof(kind), k);
      safe_copy(ttext, sizeof(ttext), t);
      have = 1;
    }
  }
  (void)node;
  (void)kind;
  (void)at;
  if (have) {
    char esc[220];
    json_escape(esc, sizeof(esc), ttext);
    if (append(buf, cap, &off,
              "You go still and tune the dead frequencies. The static "
              "thins, and the network plays something back -- a memory it "
              "never let go of:\r\n  >> %s <<\r\n",
              ttext) != 0) {
      return -1;
    }
    if (strcmp(world, g.world_name) != 0 && world[0] != '\0') {
      if (append(buf, cap, &off,
                "  (...the signal carries from somewhere called %s)\r\n",
                world) != 0) {
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
  const char *texts[6];
  const char *kinds[6];
  long long ats[6];
  int n = 0;
  int echo_n = hg_grid_local_echo_count();
  for (int i = 0; i < echo_n && n < 6; ++i) {
    const char *node = NULL;
    const char *kind = NULL;
    const char *etext = NULL;
    long long at = 0;
    if (hg_grid_local_echo_ptrs(i, &node, &kind, &etext, &at) != 0) {
      continue;
    }
    if (node != NULL && room_id != NULL && strcmp(node, room_id) == 0) {
      texts[n] = etext;
      kinds[n] = kind;
      ats[n] = at;
      n++;
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
      if (append(buf, cap, &off, "  - %s\r\n", texts[i]) != 0) {
        return -1;
      }
      char esc[220];
      json_escape(esc, sizeof(esc), texts[i]);
      char kesc[32];
      json_escape(kesc, sizeof(kesc), kinds[i] != NULL ? kinds[i] : "");
      if (append(json, sizeof(json), &joff,
                "%s{\"kind\":\"%s\",\"text\":\"%s\",\"at\":%lld}",
                i == 0 ? "" : ",", kesc, esc, ats[i]) != 0) {
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
  char worlds[8][48];
  char nodes[8][64];
  char kinds[8][24];
  char texts[8][200];
  long long ats[8];
  int n = 0;
  if (!g.remote) {
    int tc = hg_grid_local_trace_count();
    for (int i = 0; i < tc && n < 8; ++i) {
      const char *w = NULL;
      const char *node = NULL;
      const char *kind = NULL;
      const char *t = NULL;
      long long at = 0;
      if (hg_grid_local_trace_ptrs(i, &w, &node, &kind, &t, &at) != 0) {
        continue;
      }
      if (w != NULL && strcmp(w, g.world_name) != 0) {
        safe_copy(worlds[n], sizeof(worlds[n]), w);
        safe_copy(nodes[n], sizeof(nodes[n]), node);
        safe_copy(kinds[n], sizeof(kinds[n]), kind);
        safe_copy(texts[n], sizeof(texts[n]), t);
        ats[n] = at;
        n++;
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
        safe_copy(worlds[n], sizeof(worlds[n]), json_str(row, "world"));
        safe_copy(nodes[n], sizeof(nodes[n]), json_str(row, "node"));
        safe_copy(kinds[n], sizeof(kinds[n]), json_str(row, "kind"));
        safe_copy(texts[n], sizeof(texts[n]), json_str(row, "text"));
        ats[n] = json_ll(row, "at");
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
    if (append(buf, cap, &off, "  - [%s] %s\r\n", worlds[i], texts[i]) != 0) {
      return -1;
    }
    char wesc[64];
    char nesc[80];
    char kesc[32];
    char tesc[220];
    json_escape(wesc, sizeof(wesc), worlds[i]);
    json_escape(nesc, sizeof(nesc), nodes[i]);
    json_escape(kesc, sizeof(kesc), kinds[i]);
    json_escape(tesc, sizeof(tesc), texts[i]);
    if (append(json, sizeof(json), &joff,
              "%s{\"world\":\"%s\",\"node\":\"%s\",\"kind\":\"%s\","
              "\"text\":\"%s\",\"at\":%lld}",
              i == 0 ? "" : ",", wesc, nesc, kesc, tesc, ats[i]) != 0) {
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

/* ---------- remaining RPC surface (tide, gridcast, ledger, presence) ---------- */

int hg_grid_tide(int *out_tide) {
  if (!g.remote) {
    return hg_grid_local_tide(out_tide);
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
    return hg_grid_local_shift_tide(delta, out_tide);
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
    return hg_grid_local_gridcast(sender, text);
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
    return hg_grid_local_casts_since(since_id, limit, out, cap, out_count);
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
    return hg_grid_local_recent_rescued(limit, out, cap, out_count);
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
    return hg_grid_local_recent_fallen(limit, out, cap, out_count);
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
    return hg_grid_local_ledger_stats(out, cap, out_count);
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
    return hg_grid_local_prune(removed);
  }
  cJSON *params = cJSON_CreateArray();
  cJSON *kinds = cJSON_CreateArray();
  int n = hg_prune_ambient_count();
  for (int i = 0; i < n; ++i) {
    const char *k = hg_prune_ambient_at(i);
    if (k != NULL) {
      cJSON_AddItemToArray(kinds, cJSON_CreateString(k));
    }
  }
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
