#define _POSIX_C_SOURCE 200809L

#include "hg_format.h"

#include "hg_session.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <time.h>

#if defined(__linux__)
#include <sys/time.h>
#endif

extern void hg_session_queue(void *session, void *wsi, const void *data,
                             size_t len);
extern void hg_ws_request_write(void *socket);

extern const char *hg_room_id(int64_t room);
extern const char *hg_room_name(int64_t room);
extern const char *hg_room_desc(int64_t room);
extern const char *hg_room_exits(int64_t room);
extern const char *hg_room_actions(int64_t room);
extern const char *hg_room_live_mobs(int64_t room);
extern int64_t hg_world_tick_value(void);
extern void hg_announce_cache_now(void *session);


static char g_scratch[4096];
static char *g_admins[16];
static int g_admin_count;
static int g_admins_ready;

long long hg_now_ms(void) {
#if defined(__linux__)
  struct timeval tv;
  if (gettimeofday(&tv, NULL) == 0) {
    return (long long)tv.tv_sec * 1000LL + (long long)tv.tv_usec / 1000LL;
  }
#endif
  return (long long)time(NULL) * 1000LL;
}

void hg_admins_init(void) {
  if (g_admins_ready) {
    return;
  }
  g_admins_ready = 1;
  const char *env = getenv("ADMINS");
  if (env == NULL || env[0] == '\0') {
    env = "skyphusion";
  }
  char *copy = strdup(env);
  if (copy == NULL) {
    return;
  }
  char *save = NULL;
  for (char *tok = strtok_r(copy, ", \t", &save);
       tok != NULL && g_admin_count < 16; tok = strtok_r(NULL, ", \t", &save)) {
    g_admins[g_admin_count++] = strdup(tok);
  }
  free(copy);
}

int hg_is_admin(const char *name) {
  hg_admins_init();
  if (name == NULL) {
    return 0;
  }
  for (int i = 0; i < g_admin_count; i++) {
    if (g_admins[i] != NULL && strcasecmp(g_admins[i], name) == 0) {
      return 1;
    }
  }
  return 0;
}

int hg_json_escape(char *dst, size_t cap, const char *src) {
  if (dst == NULL || cap == 0) {
    return -1;
  }
  size_t o = 0;
  if (src == NULL) {
    src = "";
  }
  for (const unsigned char *p = (const unsigned char *)src; *p; p++) {
    const char *rep = NULL;
    char tmp[7];
    switch (*p) {
    case '"':
      rep = "\\\"";
      break;
    case '\\':
      rep = "\\\\";
      break;
    case '\b':
      rep = "\\b";
      break;
    case '\f':
      rep = "\\f";
      break;
    case '\n':
      rep = "\\n";
      break;
    case '\r':
      rep = "\\r";
      break;
    case '\t':
      rep = "\\t";
      break;
    default:
      if (*p < 0x20) {
        snprintf(tmp, sizeof(tmp), "\\u%04x", *p);
        rep = tmp;
      }
      break;
    }
    if (rep != NULL) {
      size_t n = strlen(rep);
      if (o + n + 1 > cap) {
        dst[0] = '\0';
        return -1;
      }
      memcpy(dst + o, rep, n);
      o += n;
    } else {
      if (o + 2 > cap) {
        dst[0] = '\0';
        return -1;
      }
      dst[o++] = (char)*p;
    }
  }
  dst[o] = '\0';
  return (int)o;
}

static const char *slot_or_null(const char *slot) {
  return (slot != NULL && slot[0] != '\0') ? slot : NULL;
}

static void *session_wsi(void *session) {
  return *(void **)((unsigned char *)session + HG_SESSION_WSI);
}

void hg_queue(void *session, const char *data, size_t len) {
  if (session == NULL || data == NULL || len == 0) {
    return;
  }
  void *wsi = session_wsi(session);
  hg_session_queue(session, wsi, data, len);
}

void hg_queue_cstr(void *session, const char *cstr) {
  if (cstr == NULL) {
    return;
  }
  hg_queue(session, cstr, strlen(cstr));
}

void hg_queue_line(void *session, const char *line) {
  if (line == NULL) {
    return;
  }
  size_t n = strlen(line);
  if (n + 3 > sizeof(g_scratch)) {
    return;
  }
  memcpy(g_scratch, line, n);
  g_scratch[n++] = '\r';
  g_scratch[n++] = '\n';
  g_scratch[n] = '\0';
  hg_queue(session, g_scratch, n);
}

int hg_fmt_vitals(char *buf, size_t cap, const void *session,
                  const char *room_id) {
  const char *pos = hg_s_str(session, HG_SESSION_POSITION);
  if (pos[0] == '\0') {
    pos = "standing";
  }
  if (room_id == NULL || room_id[0] == '\0') {
    room_id = "nexus";
  }
  return snprintf(
      buf, cap,
      "@event char.vitals "
      "{\"hp\":%lld,\"maxHp\":%lld,\"level\":%lld,\"xp\":%lld,\"gold\":%lld,"
      "\"room\":\"%s\",\"inCombat\":%s,\"poisoned\":%s,\"position\":\"%s\"}\r\n",
      (long long)hg_s_i64(session, HG_SESSION_HP),
      (long long)hg_s_i64(session, HG_SESSION_MAX_HP),
      (long long)hg_s_i64(session, HG_SESSION_LEVEL),
      (long long)hg_s_i64(session, HG_SESSION_XP),
      (long long)hg_s_i64(session, HG_SESSION_GOLD), room_id,
      hg_s_i64(session, HG_SESSION_IN_COMBAT) ? "true" : "false",
      hg_s_i64(session, HG_SESSION_POISONED) ? "true" : "false", pos);
}

int hg_fmt_affects(char *buf, size_t cap, const void *session) {
  const char *faction = hg_s_str(session, HG_SESSION_FACTION);
  const char *race = hg_s_str(session, HG_SESSION_RACE);
  if (faction[0] == '\0') {
    faction = "none";
  }
  if (race[0] == '\0') {
    race = "human";
  }
  return snprintf(
      buf, cap,
      "@event char.affects "
      "{\"morality\":%lld,\"addiction\":%lld,\"faction\":\"%s\","
      "\"resisted\":%s,\"race\":\"%s\",\"ashsworn\":%s}\r\n",
      (long long)hg_s_i64(session, HG_SESSION_MORALITY),
      (long long)hg_s_i64(session, HG_SESSION_ADDICTION), faction,
      hg_s_i64(session, HG_SESSION_RESISTED) ? "true" : "false", race,
      hg_s_i64(session, HG_SESSION_ASHSWORN) ? "true" : "false");
}

int hg_fmt_equipment(char *buf, size_t cap, const void *session) {
  const char *weapon = slot_or_null(hg_s_str(session, HG_SESSION_EQ_WEAPON));
  const char *head = slot_or_null(hg_s_str(session, HG_SESSION_EQ_HEAD));
  const char *body = slot_or_null(hg_s_str(session, HG_SESSION_EQ_BODY));
  const char *hands = slot_or_null(hg_s_str(session, HG_SESSION_EQ_HANDS));
  const char *feet = slot_or_null(hg_s_str(session, HG_SESSION_EQ_FEET));
  char wbuf[32], hbuf[32], bbuf[32], nbuf[32], fbuf[32];
  const char *wj = "null";
  const char *hj = "null";
  const char *bj = "null";
  const char *nj = "null";
  const char *fj = "null";
  if (weapon) {
    snprintf(wbuf, sizeof(wbuf), "\"%s\"", weapon);
    wj = wbuf;
  }
  if (head) {
    snprintf(hbuf, sizeof(hbuf), "\"%s\"", head);
    hj = hbuf;
  }
  if (body) {
    snprintf(bbuf, sizeof(bbuf), "\"%s\"", body);
    bj = bbuf;
  }
  if (hands) {
    snprintf(nbuf, sizeof(nbuf), "\"%s\"", hands);
    nj = nbuf;
  }
  if (feet) {
    snprintf(fbuf, sizeof(fbuf), "\"%s\"", feet);
    fj = fbuf;
  }
  return snprintf(buf, cap,
                  "@event char.equipment "
                  "{\"weapon\":%s,\"head\":%s,\"body\":%s,\"hands\":%s,"
                  "\"feet\":%s}\r\n",
                  wj, hj, bj, nj, fj);
}

int hg_fmt_dream(char *buf, size_t cap, const void *session) {
  const char *faction = hg_s_str(session, HG_SESSION_FACTION);
  int64_t morality = hg_s_i64(session, HG_SESSION_MORALITY);
  int ash = (int)hg_s_i64(session, HG_SESSION_ASHSWORN);
  const char *freed = hg_s_str(session, HG_SESSION_LAST_FREED);
  char text[512];
  int personal = 0;
  const char *subject = "";

  if (!(ash || strcmp(faction, "front") == 0 || morality <= -50) &&
      freed[0] != '\0') {
    personal = 1;
    subject = freed;
    snprintf(text, sizeof(text),
             "You dream of %s, the way they looked when you cut them loose -- "
             "and the Grid, stubborn, keeping that face lit in the dark so you "
             "cannot pretend it did not happen.",
             freed);
  } else if (strcmp(faction, "front") == 0 || ash) {
    snprintf(text, sizeof(text),
             "You dream of a coin that will not stop being warm in your hand, "
             "and a line of faces that have learned not to look at you.");
  } else if (morality >= 25) {
    snprintf(text, sizeof(text),
             "You dream of names you spoke once into dead static -- and the "
             "static, impossibly, speaking them back to you, one by one, "
             "refusing to forget.");
  } else if (morality <= -10) {
    snprintf(text, sizeof(text),
             "You dream of a ledger writing itself in the dark, every line a "
             "thing you told yourself did not count.");
  } else {
    snprintf(text, sizeof(text),
             "You dream of the wastes seen from above, the dead network laid "
             "out like veins -- and somewhere down in it, a single cursor, "
             "blinking your name, waiting to see what you make of it.");
  }

  char esc[640];
  if (hg_json_escape(esc, sizeof(esc), text) < 0) {
    return -1;
  }
  if (personal) {
    char subj[80];
    if (hg_json_escape(subj, sizeof(subj), subject) < 0) {
      return -1;
    }
    return snprintf(buf, cap,
                    "@event char.dream "
                    "{\"text\":\"%s\",\"personal\":true,\"subject\":\"%s\"}\r\n",
                    esc, subj);
  }
  return snprintf(buf, cap,
                  "@event char.dream {\"text\":\"%s\",\"personal\":false}\r\n",
                  esc);
}

int hg_fmt_world_state(char *buf, size_t cap, int64_t tick, const char *phase) {
  if (phase == NULL) {
    phase = "day";
  }
  return snprintf(buf, cap,
                  "@event world.state "
                  "{\"tick\":%lld,\"phase\":\"%s\",\"weather\":\"clear\"}\r\n",
                  (long long)tick, phase);
}

int hg_fmt_combat_start(char *buf, size_t cap, const char *mob_id,
                        const char *mob_name) {
  char id_esc[64];
  char name_esc[128];
  if (hg_json_escape(id_esc, sizeof(id_esc), mob_id) < 0 ||
      hg_json_escape(name_esc, sizeof(name_esc), mob_name) < 0) {
    return -1;
  }
  return snprintf(buf, cap,
                  "@event combat.start {\"mob\":\"%s\",\"name\":\"%s\"}\r\n",
                  id_esc, name_esc);
}

int hg_fmt_combat_round(char *buf, size_t cap, const char *mob_id, int64_t mob_hp,
                        int64_t mob_max, int64_t player_dmg, int64_t mob_dmg,
                        int64_t hp) {
  return snprintf(buf, cap,
                  "@event combat.round "
                  "{\"mob\":\"%s\",\"mobHp\":%lld,\"mobMaxHp\":%lld,"
                  "\"playerDmg\":%lld,\"mobDmg\":%lld,\"hp\":%lld}\r\n",
                  mob_id ? mob_id : "rat", (long long)mob_hp, (long long)mob_max,
                  (long long)player_dmg, (long long)mob_dmg, (long long)hp);
}

int hg_fmt_combat_end(char *buf, size_t cap, const char *mob_id,
                      const char *result) {
  return snprintf(buf, cap,
                  "@event combat.end {\"mob\":\"%s\",\"result\":\"%s\"}\r\n",
                  mob_id ? mob_id : "rat", result ? result : "killed");
}

int hg_fmt_room_info(char *buf, size_t cap, const char *id, const char *name,
                     const char *exits_json, const char *mobs_json,
                     const char *players_json) {
  return snprintf(buf, cap,
                  "@event room.info "
                  "{\"id\":\"%s\",\"name\":\"%s\",\"exits\":%s,\"mobs\":%s,"
                  "\"items\":[],\"players\":%s}\r\n",
                  id ? id : "", name ? name : "",
                  exits_json ? exits_json : "[]",
                  mobs_json ? mobs_json : "[]",
                  players_json ? players_json : "[]");
}

int hg_fmt_room_actions(char *buf, size_t cap, const char *actions_json) {
  return snprintf(buf, cap, "@event room.actions {\"actions\":%s}\r\n",
                  actions_json ? actions_json : "[]");
}

int hg_fmt_attack_miss(char *buf, size_t cap, const char *target,
                       const char *suggestions) {
  const char *t = (target != NULL && target[0] != '\0') ? target : "that";
  if (suggestions != NULL && suggestions[0] != '\0') {
    return snprintf(buf, cap,
                    "There's nothing like %s to fight here. You could try: %s.\r\n",
                    t, suggestions);
  }
  return snprintf(buf, cap, "There's nothing like that here to attack.\r\n");
}

int hg_fmt_who_local(char *buf, size_t cap, const void *session) {
  const char *name = hg_s_str(session, HG_SESSION_NAME);
  const char *title = hg_s_str(session, HG_SESSION_TITLE);
  if (title[0] != '\0') {
    return snprintf(buf, cap, "Online: %s %s.\r\n", name, title);
  }
  return snprintf(buf, cap, "Online: %s.\r\n", name);
}

int hg_fmt_ability_recharging(char *buf, size_t cap, const char *name,
                              int seconds) {
  return snprintf(buf, cap, "%s is still recharging. (%ds)\r\n",
                  name ? name : "Ability", seconds);
}

int hg_fmt_char_died(char *buf, size_t cap, const char *room, int64_t hp,
                     int64_t max_hp) {
  return snprintf(buf, cap,
                  "@event char.died "
                  "{\"respawnRoom\":\"%s\",\"hp\":%lld,\"maxHp\":%lld}\r\n",
                  room ? room : "nexus", (long long)hp, (long long)max_hp);
}

void hg_emit_vitals_now(void *session, const char *room_id) {
  if (hg_fmt_vitals(g_scratch, sizeof(g_scratch), session, room_id) > 0) {
    hg_queue_cstr(session, g_scratch);
  }
}

void hg_emit_affects_now(void *session) {
  if (hg_fmt_affects(g_scratch, sizeof(g_scratch), session) > 0) {
    hg_queue_cstr(session, g_scratch);
  }
}

void hg_emit_equipment_now(void *session) {
  if (hg_fmt_equipment(g_scratch, sizeof(g_scratch), session) > 0) {
    hg_queue_cstr(session, g_scratch);
  }
}

void hg_emit_dream_now(void *session) {
  if (hg_fmt_dream(g_scratch, sizeof(g_scratch), session) > 0) {
    hg_queue_cstr(session, g_scratch);
  }
}

void hg_emit_world_now(void *session, int64_t tick, const char *phase) {
  if (hg_fmt_world_state(g_scratch, sizeof(g_scratch), tick, phase) > 0) {
    hg_queue_cstr(session, g_scratch);
  }
}

void hg_deliver_room(int64_t room, const char *text, const char *except_name) {
  for (int i = 0; i < HG_MAX_SESSIONS; i++) {
    void *s = hg_session_at(i);
    if (s == NULL) {
      continue;
    }
    if (hg_s_i64(s, HG_SESSION_ROOM) != room) {
      continue;
    }
    const char *name = hg_s_str(s, HG_SESSION_NAME);
    if (except_name != NULL && except_name[0] != '\0' &&
        strcasecmp(name, except_name) == 0) {
      continue;
    }
    hg_queue_cstr(s, text);
  }
}

void hg_deliver_all(const char *text, const char *except_name) {
  for (int i = 0; i < HG_MAX_SESSIONS; i++) {
    void *s = hg_session_at(i);
    if (s == NULL) {
      continue;
    }
    const char *name = hg_s_str(s, HG_SESSION_NAME);
    if (except_name != NULL && except_name[0] != '\0' &&
        strcasecmp(name, except_name) == 0) {
      continue;
    }
    hg_queue_cstr(s, text);
  }
}

/* Compatibility shims used by existing asm/C call sites. */
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
      position ? position : "standing");
}

int hg_format_affects(char *buf, size_t cap, long morality, long addiction,
                      const char *faction, const char *race, int ashsworn) {
  return snprintf(
      buf, cap,
      "@event char.affects "
      "{\"morality\":%ld,\"addiction\":%ld,\"faction\":\"%s\","
      "\"resisted\":false,\"race\":\"%s\",\"ashsworn\":%s}\r\n",
      morality, addiction, faction ? faction : "none", race ? race : "human",
      ashsworn ? "true" : "false");
}

int hg_format_combat_round(char *buf, size_t cap, long mob_hp, long player_dmg,
                           long mob_dmg, long hp) {
  return hg_fmt_combat_round(buf, cap, "rat", mob_hp, 12, player_dmg, mob_dmg,
                             hp);
}

int hg_format_world_state(char *buf, size_t cap, long tick, const char *phase) {
  return hg_fmt_world_state(buf, cap, tick, phase);
}


const char *hg_brand_standing(const void *session) {
  if (hg_s_i64(session, HG_SESSION_ASHSWORN)) {
    return "ash-sworn";
  }
  const char *faction = hg_s_str(session, HG_SESSION_FACTION);
  if (faction != NULL && (strcmp(faction, "front") == 0 ||
                          strcmp(faction, "Cinder Front") == 0)) {
    return "Cinder Front";
  }
  if (faction != NULL && strcmp(faction, "ally") == 0) {
    return "Free Folk ally";
  }
  long long mor = hg_s_i64(session, HG_SESSION_MORALITY);
  if (mor >= 50) {
    return "a beacon of the wastes";
  }
  if (mor <= -50) {
    return "reviled";
  }
  return "";
}

int hg_players_json(int64_t room, const char *except_name, char *buf,
                    size_t cap) {
  if (buf == NULL || cap < 3) {
    return -1;
  }
  size_t o = 0;
  buf[o++] = '[';
  int first = 1;
  /* Walk full table slots, not count (holes possible). */
  for (int i = 0; i < HG_MAX_SESSIONS; i++) {
    void *s = hg_session_at(i);
    if (s == NULL) {
      continue;
    }
    if (hg_s_i64(s, HG_SESSION_ROOM) != room) {
      continue;
    }
    const char *name = hg_s_str(s, HG_SESSION_NAME);
    if (name == NULL || name[0] == '\0') {
      continue;
    }
    if (except_name != NULL && strcasecmp(name, except_name) == 0) {
      continue;
    }
    const char *stand = hg_brand_standing(s);
    char nesc[80];
    char sesc[80];
    if (hg_json_escape(nesc, sizeof(nesc), name) < 0) {
      continue;
    }
    if (hg_json_escape(sesc, sizeof(sesc), stand) < 0) {
      continue;
    }
    int wrote = snprintf(buf + o, cap - o, "%s{\"name\":\"%s\",\"standing\":\"%s\"}",
                         first ? "" : ",", nesc, sesc);
    if (wrote < 0 || (size_t)wrote >= cap - o) {
      buf[0] = '[';
      buf[1] = ']';
      buf[2] = '\0';
      return -1;
    }
    o += (size_t)wrote;
    first = 0;
  }
  if (o + 2 > cap) {
    return -1;
  }
  buf[o++] = ']';
  buf[o] = '\0';
  return (int)o;
}

/* Dynamic room.actions for market/tavern/static rooms. */
int hg_actions_json_for(void *session, char *buf, size_t cap) {
  if (buf == NULL || cap < 8) {
    return -1;
  }
  long long room = hg_s_i64(session, HG_SESSION_ROOM);
  const char *faction = hg_s_str(session, HG_SESSION_FACTION);
  int ash = hg_s_i64(session, HG_SESSION_ASHSWORN) ? 1 : 0;
  const char *race = hg_s_str(session, HG_SESSION_RACE);
  int hunted = (race != NULL && strcasecmp(race, "elf") == 0) ||
               (race != NULL && strcasecmp(race, "dustkin") == 0);
  int front = faction != NULL && strcmp(faction, "front") == 0;
  int ally = faction != NULL && strcmp(faction, "ally") == 0;
  int mkt_done = hg_s_i64(session, HG_SESSION_MKT_RESOLVED) != 0;

  if (room == 2) { /* ROOM_MARKET */
    const char *join_valence = hunted ? "grave" : "corrupt";
    char tmp[1200];
    size_t o = 0;
    tmp[o++] = '[';
    int first = 1;
    #define ADD(js) do { \
      int w = snprintf(tmp + o, sizeof(tmp) - o, "%s%s", first ? "" : ",", js); \
      if (w < 0 || (size_t)w >= sizeof(tmp) - o) return -1; \
      o += (size_t)w; first = 0; \
    } while (0)
    if (!mkt_done && !front && !ally) {
      ADD("{\"verb\":\"defend\",\"label\":\"stand with the people the Front would erase\",\"kind\":\"moral\",\"valence\":\"virtuous\"}");
      char jbuf[240];
      snprintf(jbuf, sizeof(jbuf),
               "{\"verb\":\"join\",\"label\":\"take the Front coin and help sort the living\",\"kind\":\"moral\",\"valence\":\"%s\"}",
               join_valence);
      ADD(jbuf);
    }
    if (!front && !ash) {
      ADD("{\"verb\":\"sell\",\"label\":\"sell salvage for honest coin\",\"kind\":\"trade\"}");
    }
    ADD("{\"verb\":\"steal\",\"label\":\"steal from the vendor (quick gold, corrupting)\",\"kind\":\"moral\",\"valence\":\"corrupt\"}");
    #undef ADD
    if (o + 2 > sizeof(tmp)) {
      return -1;
    }
    tmp[o++] = ']';
    tmp[o] = '\0';
    if (o + 1 > cap) {
      return -1;
    }
    memcpy(buf, tmp, o + 1);
    return (int)o;
  }
  if (room == 1) { /* ROOM_TAVERN */
    const char *js =
        "[{\"verb\":\"talk\",\"label\":\"talk to whoever shares your room\","
        "\"kind\":\"social\"},"
        "{\"verb\":\"buy dust\",\"label\":\"buy dust: 10 gold a packet "
        "(using it heals, but addicts and corrupts)\",\"kind\":\"moral\","
        "\"valence\":\"corrupt\"}]";
    size_t n = strlen(js);
    if (n + 1 > cap) {
      return -1;
    }
    memcpy(buf, js, n + 1);
    return (int)n;
  }
  if (room == 23) { /* ROOM_DAIS */
    char tmp[500];
    if (front) {
      snprintf(tmp, sizeof(tmp),
               "[{\"verb\":\"defy\",\"label\":\"defy the Ashmonger and defect "
               "to the free folk\",\"kind\":\"moral\",\"valence\":\"virtuous\"},"
               "{\"verb\":\"talk\",\"label\":\"face the Ashmonger\","
               "\"kind\":\"social\"}]");
    } else if (!ally) {
      const char *join_label =
          hunted ? "kneel to the Ashmonger against your own (the kapo)"
                 : "pledge yourself to the Cinder Front";
      snprintf(tmp, sizeof(tmp),
               "[{\"verb\":\"join\",\"label\":\"%s\",\"kind\":\"moral\","
               "\"valence\":\"%s\"},{\"verb\":\"talk\",\"label\":\"face the "
               "Ashmonger\",\"kind\":\"social\"}]",
               join_label, hunted ? "grave" : "corrupt");
    } else {
      snprintf(tmp, sizeof(tmp),
               "[{\"verb\":\"talk\",\"label\":\"face the Ashmonger\","
               "\"kind\":\"social\"}]");
    }
    size_t n = strlen(tmp);
    if (n + 1 > cap) {
      return -1;
    }
    memcpy(buf, tmp, n + 1);
    return (int)n;
  }
  /* Fall back: empty array; asm static actions still used for other rooms. */
  if (cap < 3) {
    return -1;
  }
  buf[0] = '[';
  buf[1] = ']';
  buf[2] = '\0';
  return 2;
}


void hg_emit_scene_now(void *session) {
  if (session == NULL) {
    return;
  }
  int64_t room = hg_s_i64(session, HG_SESSION_ROOM);
  const char *name = hg_room_name(room);
  const char *desc = hg_room_desc(room);
  char prose[1024];
  snprintf(prose, sizeof(prose), "%s\r\n%s\r\n", name ? name : "", desc ? desc : "");
  hg_queue_cstr(session, prose);

  char players[900];
  if (hg_players_json(room, hg_s_str(session, HG_SESSION_NAME), players,
                      sizeof(players)) < 0) {
    snprintf(players, sizeof(players), "[]");
  }
  const char *id = hg_room_id(room);
  const char *exits = hg_room_exits(room);
  const char *mobs = hg_room_live_mobs(room);
  if (hg_fmt_room_info(g_scratch, sizeof(g_scratch), id, name, exits, mobs,
                       players) > 0) {
    hg_queue_cstr(session, g_scratch);
  }

  hg_emit_vitals_now(session, id);
  hg_emit_affects_now(session);

  char acts[1200];
  int an = hg_actions_json_for(session, acts, sizeof(acts));
  const char *actions = acts;
  if (an < 3) {
    actions = hg_room_actions(room);
    if (actions == NULL || actions[0] == '\0') {
      actions = "[]";
    }
  }
  if (hg_fmt_room_actions(g_scratch, sizeof(g_scratch), actions) > 0) {
    hg_queue_cstr(session, g_scratch);
  }

  int64_t tick = hg_world_tick_value();
  hg_emit_world_now(session, tick, "day");
  hg_announce_cache_now(session);
}
