#define _POSIX_C_SOURCE 200809L

#include "hg_format.h"

#include "hg_grid.h"
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
extern void hg_store_save(void *session);
extern int hg_dream_compose(const void *session, char *text, size_t tcap,
                            char *subject, size_t scap);
extern int hg_actions_json_for(void *session, char *buf, size_t cap);
extern const char *hg_brand_standing(const void *session);

extern void *find_player_prefix(int64_t room, const char *prefix,
                                const char *except);

static char g_scratch[4096];

long long hg_now_ms(void) {
#if defined(__linux__)
  struct timeval tv;
  if (gettimeofday(&tv, NULL) == 0) {
    return (long long)tv.tv_sec * 1000LL + (long long)tv.tv_usec / 1000LL;
  }
#endif
  return (long long)time(NULL) * 1000LL;
}

/* hg_is_admin / the ADMINS keeper list now live in asm (social_ledger.asm).
 * C no longer authors the admin gate for wall/gridstats/gridprune. */

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
  char text[512];
  char subject[40];
  subject[0] = '\0';
  int personal = hg_dream_compose(session, text, sizeof(text), subject,
                                  sizeof(subject));
  if (personal < 0) {
    return -1;
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

/* Dynamic room.actions JSON is authored in asm (hg_actions_json_for). */


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

/* --- social port wave 2: format-only emitters (rules live in asm) --- */

extern const char *hg_regard_of(const void *session);
extern int hg_deed_count_str(const char *player, const char *kind);

void hg_emit_room_actions_now(void *session) {
  char acts[1200];
  char evt[1400];
  int n = hg_actions_json_for(session, acts, sizeof(acts));
  const char *json = acts;
  if (n < 3) {
    json = hg_room_actions(hg_s_i64(session, HG_SESSION_ROOM));
    if (json == NULL || json[0] == '\0') {
      json = "[]";
    }
  }
  if (hg_fmt_room_actions(evt, sizeof(evt), json) < 0) {
    return;
  }
  hg_queue_cstr(session, evt);
}

void hg_emit_grid_who_now(void *session) {
  char json[2048];
  size_t o = 0;
  json[o++] = '[';
  int first = 1;
  const char *world = hg_grid_world_name();
  for (int i = 0; i < HG_MAX_SESSIONS; i++) {
    void *s = hg_session_at(i);
    if (s == NULL) {
      continue;
    }
    const char *name = hg_s_str(s, HG_SESSION_NAME);
    if (name == NULL || name[0] == '\0') {
      continue;
    }
    const char *title = hg_s_str(s, HG_SESSION_TITLE);
    const char *regard = hg_regard_of(s);
    char nesc[80], tesc[80], resc[40], wesc[40];
    if (hg_json_escape(nesc, sizeof(nesc), name) < 0 ||
        hg_json_escape(tesc, sizeof(tesc), title ? title : "") < 0 ||
        hg_json_escape(resc, sizeof(resc), regard) < 0 ||
        hg_json_escape(wesc, sizeof(wesc), world) < 0) {
      continue;
    }
    int w = snprintf(json + o, sizeof(json) - o,
                     "%s{\"world\":\"%s\",\"name\":\"%s\",\"regard\":\"%s\","
                     "\"here\":true,\"title\":\"%s\"}",
                     first ? "" : ",", wesc, nesc, resc, tesc);
    if (w < 0 || (size_t)w >= sizeof(json) - o) {
      break;
    }
    o += (size_t)w;
    first = 0;
  }
  hg_grid_presence_row remote[32];
  size_t remote_n = 0;
  if (hg_grid_presence(30000, remote, 32, &remote_n) == 0) {
    for (size_t i = 0; i < remote_n; i++) {
      if (remote[i].name[0] == '\0' ||
          strcmp(remote[i].world, world) == 0) {
        continue;
      }
      char nesc[80], tesc[80], resc[80], wesc[80];
      if (hg_json_escape(nesc, sizeof(nesc), remote[i].name) < 0 ||
          hg_json_escape(tesc, sizeof(tesc), remote[i].title) < 0 ||
          hg_json_escape(resc, sizeof(resc), remote[i].regard) < 0 ||
          hg_json_escape(wesc, sizeof(wesc), remote[i].world) < 0) {
        continue;
      }
      int w = snprintf(json + o, sizeof(json) - o,
                       "%s{\"world\":\"%s\",\"name\":\"%s\","
                       "\"regard\":\"%s\",\"here\":false,\"title\":\"%s\"}",
                       first ? "" : ",", wesc, nesc, resc, tesc);
      if (w < 0 || (size_t)w >= sizeof(json) - o) {
        break;
      }
      o += (size_t)w;
      first = 0;
    }
  }
  if (o + 2 < sizeof(json)) {
    json[o++] = ']';
    json[o] = '\0';
  } else {
    snprintf(json, sizeof(json), "[]");
  }
  char evt[2200];
  snprintf(evt, sizeof(evt), "@event grid.who {\"players\":%s}\r\n", json);
  hg_queue_cstr(session, evt);
  if (first) {
    hg_queue_line(session, "No one else walks the wastes right now.");
  } else {
    hg_queue_line(session, "Online: survivors walk the wastes.");
  }
}

/* hg_emit_char_reckoning_now now lives entirely in asm (social_ledger.asm):
 * the moral vocabulary (deed labels, standing names, narrative) and the
 * char.reckoning @event are authored there. C no longer owns any of it. */

void hg_emit_comm_gridcast_now(void *session, const char *text) {
  const char *self = hg_s_str(session, HG_SESSION_NAME);
  char line[280];
  snprintf(line, sizeof(line),
           "You cast your voice into the dead Grid, out across every node: "
           "\"%s\"",
           text ? text : "");
  hg_queue_line(session, line);
  char fesc[80], tesc[200], wesc[48];
  hg_json_escape(fesc, sizeof(fesc), self ? self : "");
  hg_json_escape(tesc, sizeof(tesc), text ? text : "");
  hg_json_escape(wesc, sizeof(wesc), hg_grid_world_name());
  char evt[400];
  snprintf(evt, sizeof(evt),
           "@event comm.gridcast "
           "{\"world\":\"%s\",\"from\":\"%s\",\"text\":\"%s\"}\r\n",
           wesc, fesc, tesc);
  hg_deliver_all(evt, NULL);
}

void hg_emit_saved_roll_now(void *session) {
  hg_grid_rescued_row rows[12];
  size_t n = 0;
  hg_grid_recent_rescued(12, rows, 12, &n);
  if (n == 0) {
    hg_queue_line(session,
                  "No one has been pulled from the cages yet, or the Grid has "
                  "forgotten. Find the Front's cages and change that.");
    return;
  }
  hg_queue_line(session, "The Grid keeps these, pulled back out of the cages:");
  char json[1200];
  size_t o = 0;
  json[o++] = '[';
  for (size_t i = 0; i < n; i++) {
    char line[160];
    snprintf(line, sizeof(line), "  - %s, freed by %s", rows[i].name,
             rows[i].saved_by);
    hg_queue_line(session, line);
    char nesc[40], sesc[40], wesc[48];
    hg_json_escape(nesc, sizeof(nesc), rows[i].name);
    hg_json_escape(sesc, sizeof(sesc), rows[i].saved_by);
    hg_json_escape(wesc, sizeof(wesc), rows[i].world);
    int w = snprintf(json + o, sizeof(json) - o,
                     "%s{\"world\":\"%s\",\"name\":\"%s\",\"savedBy\":\"%s\","
                     "\"at\":%lld}",
                     i ? "," : "", wesc, nesc, sesc, rows[i].at);
    if (w > 0) {
      o += (size_t)w;
    }
  }
  json[o++] = ']';
  json[o] = '\0';
  char evt[1400];
  snprintf(evt, sizeof(evt), "@event grid.rescued_roll {\"rescued\":%s}\r\n",
           json);
  hg_queue_cstr(session, evt);
}

static void emit_fallen_roll(void *session, const hg_grid_fallen_row *fallen,
                             size_t n) {
  if (n == 0) {
    hg_queue_line(session,
                  "The roll is empty for now. No one the Grid remembers has "
                  "fallen lately; may it stay that way.");
  } else {
    hg_queue_line(session,
                  "The Grid remembers these fallen. Speak a name to keep "
                  "them:  (witness <name>)");
    for (size_t j = 0; j < n; j++) {
      char line[160];
      snprintf(line, sizeof(line), "  %s  -- fell at %s", fallen[j].name,
               fallen[j].room);
      hg_queue_line(session, line);
    }
  }
  char json[1200];
  size_t o = 0;
  json[o++] = '[';
  for (size_t j = 0; j < n; j++) {
    char nesc[40], wesc[48], resc[40];
    hg_json_escape(nesc, sizeof(nesc), fallen[j].name);
    hg_json_escape(wesc, sizeof(wesc), fallen[j].world);
    hg_json_escape(resc, sizeof(resc), fallen[j].room);
    int w = snprintf(json + o, sizeof(json) - o,
                     "%s{\"name\":\"%s\",\"world\":\"%s\",\"room\":\"%s\","
                     "\"at\":%lld}",
                     j ? "," : "", nesc, wesc, resc, fallen[j].at);
    if (w > 0) {
      o += (size_t)w;
    }
  }
  json[o++] = ']';
  json[o] = '\0';
  char evt[1400];
  snprintf(evt, sizeof(evt), "@event grid.fallen {\"fallen\":%s}\r\n", json);
  hg_queue_cstr(session, evt);
}

void hg_emit_fallen_roll_now(void *session) {
  hg_grid_fallen_row fallen[12];
  size_t n = 0;
  if (hg_grid_recent_fallen(12, fallen, 12, &n) != 0) {
    n = 0;
  }
  emit_fallen_roll(session, fallen, n);
}

void hg_emit_gridstats_cmd_now(void *session) {
  hg_grid_ledger_row rows[32];
  size_t n = 0;
  if (hg_grid_ledger_stats(rows, 32, &n) != 0) {
    hg_queue_line(session,
                  "The hub is unreachable; the deep memory cannot be read.");
    return;
  }
  int total = 0;
  for (size_t i = 0; i < n; i++) {
    total += rows[i].count;
  }
  char kinds_json[800];
  size_t o = 0;
  kinds_json[o++] = '[';
  for (size_t i = 0; i < n; i++) {
    char kesc[40];
    hg_json_escape(kesc, sizeof(kesc), rows[i].kind);
    int w = snprintf(kinds_json + o, sizeof(kinds_json) - o,
                     "%s{\"kind\":\"%s\",\"count\":%d}", i ? "," : "", kesc,
                     rows[i].count);
    if (w > 0) {
      o += (size_t)w;
    }
  }
  kinds_json[o++] = ']';
  kinds_json[o] = '\0';
  char evt[900];
  snprintf(evt, sizeof(evt),
           "@event grid.ledger_stats {\"total\":%d,\"kinds\":%s}\r\n", total,
           kinds_json);
  hg_queue_cstr(session, evt);
  char line[160];
  snprintf(line, sizeof(line), "The Grid ledger holds %d trace(s):", total);
  hg_queue_line(session, line);
  for (size_t i = 0; i < n; i++) {
    snprintf(line, sizeof(line), "  %-10.32s %d", rows[i].kind, rows[i].count);
    hg_queue_line(session, line);
  }
}

void hg_emit_gridprune_cmd_now(void *session) {
  hg_grid_ledger_row before_rows[32];
  size_t before_n = 0;
  if (hg_grid_ledger_stats(before_rows, 32, &before_n) != 0) {
    hg_queue_line(session,
                  "The hub is unreachable; the deep memory cannot be tended.");
    return;
  }
  int before = 0;
  for (size_t i = 0; i < before_n; i++) {
    before += before_rows[i].count;
  }
  int removed = 0;
  if (hg_grid_prune_ledger(&removed) != 0) {
    hg_queue_line(session,
                  "The hub is unreachable; the deep memory cannot be tended.");
    return;
  }
  hg_grid_ledger_row after_rows[32];
  size_t after_n = 0;
  if (hg_grid_ledger_stats(after_rows, 32, &after_n) != 0) {
    after_n = 0;
  }
  int after = 0;
  for (size_t i = 0; i < after_n; i++) {
    after += after_rows[i].count;
  }
  char kinds_json[800];
  size_t o = 0;
  kinds_json[o++] = '[';
  for (size_t i = 0; i < after_n; i++) {
    char kesc[40];
    hg_json_escape(kesc, sizeof(kesc), after_rows[i].kind);
    int w = snprintf(kinds_json + o, sizeof(kinds_json) - o,
                     "%s{\"kind\":\"%s\",\"count\":%d}", i ? "," : "", kesc,
                     after_rows[i].count);
    if (w > 0) {
      o += (size_t)w;
    }
  }
  kinds_json[o++] = ']';
  kinds_json[o] = '\0';
  char evt[960];
  snprintf(evt, sizeof(evt),
           "@event grid.ledger_pruned "
           "{\"removed\":%d,\"before\":%d,\"after\":%d,\"kinds\":%s}\r\n",
           removed, before, after, kinds_json);
  hg_queue_cstr(session, evt);
  char line[160];
  snprintf(line, sizeof(line),
           "Pruned %d ambient trace(s) (ghost, passage, recall).", removed);
  hg_queue_line(session, line);
  snprintf(line, sizeof(line),
           "The ledger went from %d to %d trace(s); only meaningful memory "
           "remains.",
           before, after);
  hg_queue_line(session, line);
}

void hg_emit_forgiven_target_now(void *target, void *forgiver, int ashsworn,
                                 int redeemed_path) {
  const char *self = hg_s_str(forgiver, HG_SESSION_NAME);
  char push[280];
  snprintf(push, sizeof(push), "%s looks at you and chooses to forgive you.\r\n",
           self ? self : "");
  hg_queue_cstr(target, push);
  if (ashsworn) {
    hg_queue_cstr(
        target,
        "It reaches something in you. But the ash does not lift; it never "
        "will. You carry the mark and the mercy both. Some things are not "
        "forgotten, even when they are forgiven.\r\n");
    char byesc[80];
    hg_json_escape(byesc, sizeof(byesc), self ? self : "");
    char evt[240];
    snprintf(evt, sizeof(evt),
             "@event char.forgiven "
             "{\"by\":\"%s\",\"ashsworn\":true,\"redeemed\":false}\r\n",
             byesc);
    hg_queue_cstr(target, evt);
    return;
  }
  if (redeemed_path) {
    return;
  }
  char byesc[80];
  hg_json_escape(byesc, sizeof(byesc), self ? self : "");
  char evt[240];
  snprintf(evt, sizeof(evt),
           "@event char.forgiven "
           "{\"by\":\"%s\",\"ashsworn\":false,\"redeemed\":false}\r\n",
           byesc);
  hg_queue_cstr(target, evt);
  hg_queue_cstr(
      target,
      "It lands, and it stays with you. The road is still yours to walk, "
      "but you are not walking it unseen.\r\n");
}

void hg_emit_forgiven_redeemed_now(void *target, void *forgiver) {
  const char *self = hg_s_str(forgiver, HG_SESSION_NAME);
  const char *tname = hg_s_str(target, HG_SESSION_NAME);
  const char *title = hg_s_str(target, HG_SESSION_TITLE);
  char byesc[80], nesc[80], tesc[80];
  hg_json_escape(byesc, sizeof(byesc), self ? self : "");
  hg_json_escape(nesc, sizeof(nesc), tname ? tname : "");
  hg_json_escape(tesc, sizeof(tesc), title ? title : "");
  char evt[240];
  snprintf(evt, sizeof(evt),
           "@event char.forgiven "
           "{\"by\":\"%s\",\"ashsworn\":false,\"redeemed\":true}\r\n",
           byesc);
  hg_queue_cstr(target, evt);
  snprintf(evt, sizeof(evt),
           "@event grid.redemption {\"name\":\"%s\",\"title\":\"%s\"}\r\n",
           nesc, tesc);
  hg_queue_cstr(target, evt);
  hg_queue_cstr(
      target,
      "Something you had been carrying alone, you are not carrying alone "
      "anymore. You found your way back, and someone met you on the road. "
      "(you are the Returned)\r\n");
  hg_emit_affects_now(target);
}
