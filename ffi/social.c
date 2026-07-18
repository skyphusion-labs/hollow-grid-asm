#define _POSIX_C_SOURCE 200809L

#include "hg_format.h"
#include "hg_grid.h"
#include "hg_session.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>

extern void hg_store_save(void *session);

/* Once-per-(forgiver,subject) grace ledger (process-local, matches Go). */
#define HG_MAX_FORGIVEN 256
static struct {
  char forgiver[40];
  char subject[40];
} g_forgiven[HG_MAX_FORGIVEN];
static int g_forgiven_n;

static int already_forgiven(const char *forgiver, const char *subject) {
  for (int i = 0; i < g_forgiven_n; i++) {
    if (strcasecmp(g_forgiven[i].forgiver, forgiver) == 0 &&
        strcasecmp(g_forgiven[i].subject, subject) == 0) {
      return 1;
    }
  }
  return 0;
}

static void mark_forgiven(const char *forgiver, const char *subject) {
  if (g_forgiven_n >= HG_MAX_FORGIVEN || already_forgiven(forgiver, subject)) {
    return;
  }
  snprintf(g_forgiven[g_forgiven_n].forgiver,
           sizeof(g_forgiven[g_forgiven_n].forgiver), "%s", forgiver);
  snprintf(g_forgiven[g_forgiven_n].subject,
           sizeof(g_forgiven[g_forgiven_n].subject), "%s", subject);
  g_forgiven_n++;
}

static void *find_player_prefix(int64_t room, const char *prefix,
                                const char *except) {
  if (prefix == NULL || prefix[0] == '\0') {
    return NULL;
  }
  size_t plen = strlen(prefix);
  void *found = NULL;
  for (int i = 0; i < HG_MAX_SESSIONS; i++) {
    void *s = hg_session_at(i);
    if (s == NULL) {
      continue;
    }
    if (room >= 0 && hg_s_i64(s, HG_SESSION_ROOM) != room) {
      continue;
    }
    const char *name = hg_s_str(s, HG_SESSION_NAME);
    if (name == NULL || name[0] == '\0') {
      continue;
    }
    if (except != NULL && strcasecmp(name, except) == 0) {
      continue;
    }
    if (strncasecmp(name, prefix, plen) != 0) {
      continue;
    }
    if (found != NULL) {
      return NULL; /* ambiguous */
    }
    found = s;
  }
  return found;
}

static const char *regard_of(const void *session) {
  if (hg_s_i64(session, HG_SESSION_ASHSWORN)) {
    return "branded";
  }
  long long mor = hg_s_i64(session, HG_SESSION_MORALITY);
  if (mor >= 50) {
    return "honored";
  }
  if (mor <= -50) {
    return "feared";
  }
  const char *faction = hg_s_str(session, HG_SESSION_FACTION);
  if (faction != NULL && strcmp(faction, "ally") == 0) {
    return "trusted";
  }
  if (faction != NULL && strcmp(faction, "front") == 0) {
    return "front";
  }
  return "neutral";
}

extern const char *hg_room_actions(int64_t room);

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

void hg_join_record_oath(void *session) {
  const char *name = hg_s_str(session, HG_SESSION_NAME);
  const char *node = hg_room_id_cstr(hg_s_i64(session, HG_SESSION_ROOM));
  char text[160];
  if (hg_s_i64(session, HG_SESSION_ASHSWORN)) {
    snprintf(text, sizeof(text), "%s swore to the Cinder Front as ash-sworn.",
             name ? name : "");
  } else {
    snprintf(text, sizeof(text), "%s swore to the Cinder Front.",
             name ? name : "");
  }
  hg_grid_record_local_echo(node ? node : "market", "oath", text);
  hg_emit_room_actions_now(session);
}

void hg_cmd_sell_c(void *session, const char *arg) {
  long long room = hg_s_i64(session, HG_SESSION_ROOM);
  if (room != 2) {
    hg_queue_line(session, "You can't do that here.");
    return;
  }
  const char *faction = hg_s_str(session, HG_SESSION_FACTION);
  if (faction != NULL && strcmp(faction, "front") == 0) {
    hg_queue_line(
        session,
        "The vendor drone's optic flares red. \"Cinder Front. We remember "
        "Scrap Market. We don't trade with your kind.\" It turns its back on "
        "you, and the stalls nearby go quiet.");
    return;
  }
  if (arg == NULL || arg[0] == '\0') {
    hg_queue_line(session, "Sell what?");
    return;
  }
  /* Full sell path lands with inventory value; smoke Front path only needs
   * the refuse above. Stub the rest honestly for now. */
  char line[160];
  snprintf(line, sizeof(line), "You aren't carrying \"%s\".", arg);
  hg_queue_line(session, line);
}

static void hg_add_deed(const char *player, const char *kind);
static void hg_moral_arc(void *session);
static void hg_resolve_return(void *session);

void hg_cmd_steal_c(void *session) {
  if (hg_s_i64(session, HG_SESSION_ROOM) != 2) {
    hg_queue_line(session, "You can't do that here.");
    return;
  }
  hg_s_set_i64(session, HG_SESSION_MORALITY,
               hg_s_i64(session, HG_SESSION_MORALITY) - 8);
  hg_s_set_i64(session, HG_SESSION_GOLD, hg_s_i64(session, HG_SESSION_GOLD) + 12);
  const char *name = hg_s_str(session, HG_SESSION_NAME);
  hg_add_deed(name, "stolen");
  hg_store_save(session);
  char shout[120];
  snprintf(shout, sizeof(shout), "%s is caught with a hand in the till!\r\n",
           name ? name : "Someone");
  hg_deliver_room(hg_s_i64(session, HG_SESSION_ROOM), shout, name);
  hg_queue_line(session,
                "You snag a fistful of coin while the vendor drone's back is "
                "turned. Your hands shake anyway.");
  hg_emit_vitals_now(session, hg_room_id_cstr(hg_s_i64(session, HG_SESSION_ROOM)));
  hg_emit_affects_now(session);
  hg_moral_arc(session);
}

void hg_cmd_sense_c(void *session) {
  hg_emit_room_actions_now(session);
}

/* Returns 1 if a same-room player was looked at. */
int hg_cmd_look_player_c(void *session, const char *arg) {
  if (arg == NULL || arg[0] == '\0') {
    return 0;
  }
  while (*arg == ' ') {
    arg++;
  }
  void *target =
      find_player_prefix(hg_s_i64(session, HG_SESSION_ROOM), arg,
                         hg_s_str(session, HG_SESSION_NAME));
  if (target == NULL) {
    return 0;
  }
  const char *tname = hg_s_str(target, HG_SESSION_NAME);
  const char *title = hg_s_str(target, HG_SESSION_TITLE);
  const char *faction = hg_s_str(target, HG_SESSION_FACTION);
  int ash = hg_s_i64(target, HG_SESSION_ASHSWORN) ? 1 : 0;
  const char *brand = hg_brand_standing(target);
  const char *regard = regard_of(target);
  char prose[240];
  if (brand != NULL && brand[0] != '\0') {
    if (title != NULL && title[0] != '\0') {
      snprintf(prose, sizeof(prose),
               "%s, %s (%s) stands before you, looking steady.", tname, title,
               brand);
    } else {
      snprintf(prose, sizeof(prose),
               "%s (%s) stands before you, looking steady.", tname, brand);
    }
  } else {
    snprintf(prose, sizeof(prose), "%s stands before you, looking steady.",
             tname);
  }
  hg_queue_line(session, prose);

  char nesc[80], tesc[80], fesc[40], resc[40];
  if (hg_json_escape(nesc, sizeof(nesc), tname) < 0 ||
      hg_json_escape(tesc, sizeof(tesc), title ? title : "") < 0 ||
      hg_json_escape(fesc, sizeof(fesc), faction ? faction : "none") < 0 ||
      hg_json_escape(resc, sizeof(resc), regard) < 0) {
    return 1;
  }
  char evt[400];
  snprintf(evt, sizeof(evt),
           "@event player.read "
           "{\"name\":\"%s\",\"title\":\"%s\",\"faction\":\"%s\","
           "\"ashsworn\":%s,\"regard\":\"%s\"}\r\n",
           nesc, tesc, fesc, ash ? "true" : "false", resc);
  hg_queue_cstr(session, evt);
  return 1;
}

void hg_cmd_forgive_c(void *session, const char *arg) {
  if (arg == NULL) {
    arg = "";
  }
  while (*arg == ' ') {
    arg++;
  }
  char who[40];
  size_t i = 0;
  while (arg[i] && arg[i] != ' ' && i + 1 < sizeof(who)) {
    who[i] = arg[i];
    i++;
  }
  who[i] = '\0';
  if (who[0] == '\0') {
    hg_queue_line(session,
                  "Forgive whom?  (forgive <player> -- choose to let someone "
                  "marked back in)");
    return;
  }
  const char *self = hg_s_str(session, HG_SESSION_NAME);
  if (strcasecmp(who, self) == 0) {
    hg_queue_line(session,
                  "You cannot forgive yourself here; that is a longer road, "
                  "and a lonelier one.");
    return;
  }
  void *target =
      find_player_prefix(hg_s_i64(session, HG_SESSION_ROOM), who, NULL);
  if (target == NULL) {
    char line[120];
    snprintf(line, sizeof(line),
             "There's no one called \"%s\" here to forgive.", who);
    hg_queue_line(session, line);
    return;
  }
  const char *tname = hg_s_str(target, HG_SESSION_NAME);
  if (already_forgiven(self, tname)) {
    char line[160];
    snprintf(line, sizeof(line),
             "You have already forgiven %s. It was true the first time; it "
             "does not need saying twice.",
             tname);
    hg_queue_line(session, line);
    return;
  }
  int ash = hg_s_i64(target, HG_SESSION_ASHSWORN) ? 1 : 0;
  int strayed = hg_s_i64(target, HG_SESSION_STRAYED) ? 1 : 0;
  int redeemed = hg_s_i64(target, HG_SESSION_REDEEMED) ? 1 : 0;
  const char *tfaction = hg_s_str(target, HG_SESSION_FACTION);
  int front = tfaction != NULL && strcmp(tfaction, "front") == 0;
  long long tmor = hg_s_i64(target, HG_SESSION_MORALITY);
  int marked = ash || strayed || front || tmor <= -50;
  if (!marked) {
    char line[160];
    snprintf(line, sizeof(line),
             "%s carries nothing that needs your forgiveness. Keep the words "
             "for someone who does.",
             tname);
    hg_queue_line(session, line);
    return;
  }
  mark_forgiven(self, tname);
  hg_add_deed(self, "forgave");
  hg_s_set_i64(target, HG_SESSION_MORALITY, tmor + 5);
  hg_s_set_i64(session, HG_SESSION_MORALITY,
               hg_s_i64(session, HG_SESSION_MORALITY) + 2);

  char grace[160];
  snprintf(grace, sizeof(grace), "%s forgave %s here.", self, tname);
  const char *node = hg_room_id_cstr(hg_s_i64(session, HG_SESSION_ROOM));
  hg_grid_record_local_echo(node ? node : "market", "grace", grace);

  char push[280];
  snprintf(push, sizeof(push), "%s looks at you and chooses to forgive you.\r\n",
           self);
  hg_queue_cstr(target, push);

  if (ash) {
    hg_queue_cstr(
        target,
        "It reaches something in you. But the ash does not lift; it never "
        "will. You carry the mark and the mercy both. Some things are not "
        "forgotten, even when they are forgiven.\r\n");
    char evt[240];
    char byesc[80];
    hg_json_escape(byesc, sizeof(byesc), self);
    snprintf(evt, sizeof(evt),
             "@event char.forgiven "
             "{\"by\":\"%s\",\"ashsworn\":true,\"redeemed\":false}\r\n",
             byesc);
    hg_queue_cstr(target, evt);
  } else if (strayed && !redeemed && !front) {
    hg_s_set_i64(target, HG_SESSION_REDEEMED, 1);
    char *title = hg_s_str_mut(target, HG_SESSION_TITLE);
    if (title[0] == '\0') {
      snprintf(title, 48, "the Returned");
    }
    hg_store_save(target);
    char byesc[80], nesc[80], tesc[80];
    hg_json_escape(byesc, sizeof(byesc), self);
    hg_json_escape(nesc, sizeof(nesc), tname);
    hg_json_escape(tesc, sizeof(tesc), title);
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
  } else {
    char byesc[80];
    hg_json_escape(byesc, sizeof(byesc), self);
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

  char room_line[160];
  snprintf(room_line, sizeof(room_line), "%s forgives %s.\r\n", self, tname);
  hg_deliver_room(hg_s_i64(session, HG_SESSION_ROOM), room_line, self);
  /* Also exclude target from room shout? Go excludes both; deliver_room only
   * excepts one. Push is enough for target. */
  char line[160];
  snprintf(line, sizeof(line),
           "You choose to forgive %s. Out here that is not nothing; it may be "
           "everything.",
           tname);
  hg_queue_line(session, line);
  hg_emit_affects_now(session);
}


static int inv_add(void *session, const char *id) {
  long long n = hg_s_i64(session, HG_SESSION_INV_COUNT);
  if (n < 0 || n >= HG_SESSION_INV_SLOTS || id == NULL || id[0] == '\0') {
    return -1;
  }
  char *slot = hg_s_str_mut(session, HG_SESSION_INVENTORY) +
               (size_t)n * HG_SESSION_INV_SLOT_SIZE;
  snprintf(slot, HG_SESSION_INV_SLOT_SIZE, "%s", id);
  hg_s_set_i64(session, HG_SESSION_INV_COUNT, n + 1);
  return 0;
}

static int inv_find_slot(void *session, const char *arg) {
  if (arg == NULL || arg[0] == '\0') {
    return -1;
  }
  long long n = hg_s_i64(session, HG_SESSION_INV_COUNT);
  const char *base = hg_s_str(session, HG_SESSION_INVENTORY);
  for (long long i = 0; i < n; i++) {
    const char *slot = base + (size_t)i * HG_SESSION_INV_SLOT_SIZE;
    if (strcasecmp(slot, arg) == 0 || strncasecmp(slot, arg, strlen(arg)) == 0) {
      return (int)i;
    }
  }
  return -1;
}

static int inv_remove_slot(void *session, int idx) {
  long long n = hg_s_i64(session, HG_SESSION_INV_COUNT);
  if (idx < 0 || idx >= n) {
    return -1;
  }
  char *base = hg_s_str_mut(session, HG_SESSION_INVENTORY);
  for (long long i = idx; i + 1 < n; i++) {
    memcpy(base + (size_t)i * HG_SESSION_INV_SLOT_SIZE,
           base + (size_t)(i + 1) * HG_SESSION_INV_SLOT_SIZE,
           HG_SESSION_INV_SLOT_SIZE);
  }
  memset(base + (size_t)(n - 1) * HG_SESSION_INV_SLOT_SIZE, 0,
         HG_SESSION_INV_SLOT_SIZE);
  hg_s_set_i64(session, HG_SESSION_INV_COUNT, n - 1);
  return 0;
}

void *hg_find_session_name(const char *name) {
  if (name == NULL || name[0] == '\0') {
    return NULL;
  }
  for (int i = 0; i < HG_MAX_SESSIONS; i++) {
    void *s = hg_session_at(i);
    if (s == NULL) {
      continue;
    }
    const char *n = hg_s_str(s, HG_SESSION_NAME);
    if (n != NULL && strcasecmp(n, name) == 0) {
      return s;
    }
  }
  return NULL;
}

void hg_inv_add_item(void *session, const char *id) { inv_add(session, id); }

void hg_cmd_talk_c(void *session) {
  long long room = hg_s_i64(session, HG_SESSION_ROOM);
  const char *faction = hg_s_str(session, HG_SESSION_FACTION);
  int ash = hg_s_i64(session, HG_SESSION_ASHSWORN) ? 1 : 0;
  if (room == 1) { /* tavern */
    hg_queue_cstr(
        session,
        "The dealer rolls a packet of dust between his fingers: \"First taste "
        "eases any pain, friend. Just say buy dust.\"\r\n"
        "(You could buy/use dust, carouse, or resist.)\r\n");
    return;
  }
  if (room == 8) { /* floodgate */
    hg_queue_cstr(
        session,
        "A stranded operator looks up from a dead console: \"I can't leave until "
        "this node is restored, and the Custodian dragged the core shard down "
        "into the Core Lab. Kill it, bring me the shard, and I'll give you "
        "everything I have.\"\r\n");
    return;
  }
  if (room == 16) { /* waystation */
    if (faction && strcmp(faction, "front") == 0) {
      hg_queue_line(session,
                    "The free folk look at your Front brand and go quiet. There "
                    "is no welcome here for your kind.");
    } else if (faction && strcmp(faction, "ally") == 0) {
      hg_queue_line(session,
                    "A medic nods: \"The free folk hold. Rest if you need it "
                    "(treat).\"");
    } else {
      hg_queue_cstr(
          session,
          "A refugee looks you over: \"Pick a side before you ask us for "
          "shelter. The free folk or the Front -- the road doesn't care, but "
          "we do.\"\r\n");
    }
    return;
  }
  if (room == 23) { /* dais */
    if (ash || (faction && strcmp(faction, "front") == 0)) {
      hg_queue_cstr(
          session,
          "The Ashmonger claps a heavy hand on your shoulder. \"You came far "
          "for the cause. Kneel and take your place at my right hand -- or find "
          "your spine and 'defy' me, here and now. Choose what you are.\"\r\n");
    } else if (faction && strcmp(faction, "ally") == 0) {
      hg_queue_cstr(
          session,
          "The Ashmonger laughs, low and delighted. \"The elf-lover walked "
          "right into my house. Bold. I am going to wear you as a banner.\" "
          "There is no talking your way out of this -- only steel.\r\n");
    } else {
      hg_queue_cstr(
          session,
          "The Ashmonger spits. \"Pledge to the Front or get off my dais. I "
          "have no patience for fence-sitters.\"\r\n");
    }
    return;
  }
  (void)ash;
  hg_queue_line(session, "There's no one here to talk to.");
}

void hg_cmd_buy_workshop(void *session, const char *arg);

void hg_cmd_buy_c(void *session, const char *arg) {
  long long room = hg_s_i64(session, HG_SESSION_ROOM);
  if (room == 1) {
    if (arg == NULL || strstr(arg, "dust") == NULL) {
      hg_queue_line(session, "The dealer only deals one thing: dust. (\"buy dust\")");
      return;
    }
    long long gold = hg_s_i64(session, HG_SESSION_GOLD);
    if (gold < 10) {
      hg_queue_line(session,
                    "The dealer sneers. \"10 gold, no credit.\" You're short.");
      return;
    }
    hg_s_set_i64(session, HG_SESSION_GOLD, gold - 10);
    inv_add(session, "dust");
    hg_store_save(session);
    char line[160];
    snprintf(line, sizeof(line),
             "The dealer slips you a packet of dust. (-10 gold, gold: %lld)",
             (long long)hg_s_i64(session, HG_SESSION_GOLD));
    hg_queue_line(session, line);
    hg_emit_vitals_now(session,
                       hg_room_id_cstr(hg_s_i64(session, HG_SESSION_ROOM)));
    return;
  }
  if (room == 4) {
    hg_cmd_buy_workshop(session, arg);
    return;
  }
  hg_queue_line(session, "There is nothing to buy here.");
}

void hg_cmd_wall_c(void *session, const char *arg) {
  const char *name = hg_s_str(session, HG_SESSION_NAME);
  if (!hg_is_admin(name)) {
    hg_queue_line(session,
                  "Only a keeper of the Grid can broadcast across the wastes.");
    return;
  }
  if (arg == NULL) {
    arg = "";
  }
  while (*arg == ' ') {
    arg++;
  }
  if (arg[0] == '\0') {
    hg_queue_line(session, "Announce what?  (wall <message>)");
    return;
  }
  char banner[320];
  snprintf(banner, sizeof(banner), "*** GRID BROADCAST ***  %s\r\n", arg);
  char nesc[80], tesc[240];
  hg_json_escape(nesc, sizeof(nesc), name);
  hg_json_escape(tesc, sizeof(tesc), arg);
  char evt[400];
  snprintf(evt, sizeof(evt),
           "@event server.announce {\"from\":\"%s\",\"text\":\"%s\"}\r\n", nesc,
           tesc);
  char both[800];
  snprintf(both, sizeof(both), "%s%s", banner, evt);
  hg_deliver_all(both, NULL);
}

void hg_cmd_tell_c(void *session, const char *arg) {
  if (arg == NULL) {
    arg = "";
  }
  while (*arg == ' ') {
    arg++;
  }
  char target[40];
  size_t i = 0;
  while (arg[i] && arg[i] != ' ' && i + 1 < sizeof(target)) {
    target[i] = arg[i];
    i++;
  }
  target[i] = '\0';
  const char *msg = arg + i;
  while (*msg == ' ') {
    msg++;
  }
  if (target[0] == '\0' || msg[0] == '\0') {
    hg_queue_line(session, "Tell whom what?  (tell <player> <message>)");
    return;
  }
  void *dest = hg_find_session_name(target);
  if (dest == NULL) {
    /* search any room by prefix */
    void *found = NULL;
    size_t plen = strlen(target);
    for (int j = 0; j < HG_MAX_SESSIONS; j++) {
      void *s = hg_session_at(j);
      if (s == NULL) {
        continue;
      }
      const char *n = hg_s_str(s, HG_SESSION_NAME);
      if (n && strncasecmp(n, target, plen) == 0) {
        if (found) {
          found = NULL;
          break;
        }
        found = s;
      }
    }
    dest = found;
  }
  if (dest == NULL) {
    hg_queue_line(session, "No one by that name is connected.");
    return;
  }
  const char *self = hg_s_str(session, HG_SESSION_NAME);
  const char *tname = hg_s_str(dest, HG_SESSION_NAME);
  snprintf(hg_s_str_mut(dest, HG_SESSION_REPLY_TO), 40, "%s", self);
  char line[280];
  snprintf(line, sizeof(line), "%s tells you, \"%s\"\r\n", self, msg);
  char fesc[80], tesc[200];
  hg_json_escape(fesc, sizeof(fesc), self);
  hg_json_escape(tesc, sizeof(tesc), msg);
  char evt[320];
  snprintf(evt, sizeof(evt),
           "@event comm.tell {\"from\":\"%s\",\"text\":\"%s\"}\r\n", fesc, tesc);
  char both[600];
  snprintf(both, sizeof(both), "%s%s", line, evt);
  hg_queue_cstr(dest, both);
  snprintf(line, sizeof(line), "You tell %s, \"%s\"", tname, msg);
  hg_queue_line(session, line);
}

void hg_cmd_reply_c(void *session, const char *arg) {
  const char *to = hg_s_str(session, HG_SESSION_REPLY_TO);
  if (to == NULL || to[0] == '\0') {
    hg_queue_line(session, "No one has told you anything lately.");
    return;
  }
  if (arg == NULL) {
    arg = "";
  }
  while (*arg == ' ') {
    arg++;
  }
  char buf[280];
  snprintf(buf, sizeof(buf), "%s %s", to, arg);
  hg_cmd_tell_c(session, buf);
}

void hg_cmd_yell_c(void *session, const char *arg) {
  if (arg == NULL) {
    arg = "";
  }
  while (*arg == ' ') {
    arg++;
  }
  if (arg[0] == '\0') {
    hg_queue_line(session, "Yell what?  (yell <message>)");
    return;
  }
  const char *self = hg_s_str(session, HG_SESSION_NAME);
  char fesc[80], tesc[200];
  hg_json_escape(fesc, sizeof(fesc), self);
  hg_json_escape(tesc, sizeof(tesc), arg);
  char evt[320];
  snprintf(evt, sizeof(evt),
           "@event comm.yell {\"from\":\"%s\",\"text\":\"%s\"}\r\n", fesc, tesc);
  for (int i = 0; i < HG_MAX_SESSIONS; i++) {
    void *s = hg_session_at(i);
    if (s == NULL) {
      continue;
    }
    const char *n = hg_s_str(s, HG_SESSION_NAME);
    if (n == NULL || n[0] == '\0') {
      continue;
    }
    char text[280];
    if (strcasecmp(n, self) == 0) {
      snprintf(text, sizeof(text), "You yell, \"%s\"\r\n", arg);
    } else {
      snprintf(text, sizeof(text), "%s yells, \"%s\"\r\n", self, arg);
    }
    char both[600];
    snprintf(both, sizeof(both), "%s%s", text, evt);
    hg_queue_cstr(s, both);
  }
}

void hg_cmd_emote_c(void *session, const char *arg) {
  if (arg == NULL) {
    arg = "";
  }
  while (*arg == ' ') {
    arg++;
  }
  if (arg[0] == '\0') {
    hg_queue_line(session, "Emote what?  (emote <action>)");
    return;
  }
  const char *self = hg_s_str(session, HG_SESSION_NAME);
  char line[280];
  snprintf(line, sizeof(line), "%s %s\r\n", self, arg);
  hg_deliver_room(hg_s_i64(session, HG_SESSION_ROOM), line, NULL);
}

void hg_cmd_mend_c(void *session, const char *arg) {
  if (arg == NULL) {
    arg = "";
  }
  while (*arg == ' ') {
    arg++;
  }
  void *target =
      find_player_prefix(hg_s_i64(session, HG_SESSION_ROOM), arg,
                         hg_s_str(session, HG_SESSION_NAME));
  if (target == NULL) {
    hg_queue_line(session, "There's no one like that here to mend.");
    return;
  }
  const char *tname = hg_s_str(target, HG_SESSION_NAME);
  if (hg_s_i64(target, HG_SESSION_HP) >= hg_s_i64(target, HG_SESSION_MAX_HP)) {
    char line[120];
    snprintf(line, sizeof(line), "%s is already whole.", tname);
    hg_queue_line(session, line);
    return;
  }
  long long hp = hg_s_i64(session, HG_SESSION_HP);
  if (hp <= 5) {
    hg_queue_line(session, "You don't have enough life left to spare.");
    return;
  }
  hg_s_set_i64(session, HG_SESSION_HP, hp - 5);
  long long thp = hg_s_i64(target, HG_SESSION_HP) + 10;
  long long tmax = hg_s_i64(target, HG_SESSION_MAX_HP);
  if (thp > tmax) {
    thp = tmax;
  }
  hg_s_set_i64(target, HG_SESSION_HP, thp);
  char line[120];
  snprintf(line, sizeof(line), "You spend a little of yourself to mend %s.",
           tname);
  hg_queue_line(session, line);
  snprintf(line, sizeof(line), "%s tends your wounds.\r\n",
           hg_s_str(session, HG_SESSION_NAME));
  hg_queue_cstr(target, line);
  hg_emit_vitals_now(session,
                     hg_room_id_cstr(hg_s_i64(session, HG_SESSION_ROOM)));
}

void hg_cmd_give_c(void *session, const char *arg) {
  if (arg == NULL) {
    arg = "";
  }
  while (*arg == ' ') {
    arg++;
  }
  /* give <item...> <player> */
  char buf[200];
  snprintf(buf, sizeof(buf), "%s", arg);
  char *toks[16];
  int nt = 0;
  char *save = NULL;
  for (char *t = strtok_r(buf, " \t", &save); t && nt < 16;
       t = strtok_r(NULL, " \t", &save)) {
    toks[nt++] = t;
  }
  if (nt < 2) {
    hg_queue_line(session, "Give what to whom?  (give <item> <player>)");
    return;
  }
  const char *who = toks[nt - 1];
  int item_n = nt - 1;
  if (item_n > 0 && strcasecmp(toks[item_n - 1], "to") == 0) {
    item_n--;
  }
  if (item_n < 1) {
    hg_queue_line(session, "Give what to whom?  (give <item> <player>)");
    return;
  }
  char item[64];
  item[0] = '\0';
  for (int i = 0; i < item_n; i++) {
    if (i) {
      strncat(item, " ", sizeof(item) - strlen(item) - 1);
    }
    strncat(item, toks[i], sizeof(item) - strlen(item) - 1);
  }
  int slot = inv_find_slot(session, item);
  if (slot < 0) {
    char line[120];
    snprintf(line, sizeof(line), "You aren't carrying \"%s\".", item);
    hg_queue_line(session, line);
    return;
  }
  void *target =
      find_player_prefix(hg_s_i64(session, HG_SESSION_ROOM), who,
                         hg_s_str(session, HG_SESSION_NAME));
  if (target == NULL) {
    char line[120];
    snprintf(line, sizeof(line),
             "There's no one called \"%s\" here to give it to.", who);
    hg_queue_line(session, line);
    return;
  }
  const char *id =
      hg_s_str(session, HG_SESSION_INVENTORY) + (size_t)slot * HG_SESSION_INV_SLOT_SIZE;
  char idcopy[16];
  snprintf(idcopy, sizeof(idcopy), "%s", id);
  inv_remove_slot(session, slot);
  inv_add(target, idcopy);
  hg_store_save(session);
  hg_store_save(target);
  const char *tname = hg_s_str(target, HG_SESSION_NAME);
  char line[160];
  snprintf(line, sizeof(line), "You give %s to %s.", idcopy, tname);
  hg_queue_line(session, line);
  snprintf(line, sizeof(line), "%s gives you %s.\r\n",
           hg_s_str(session, HG_SESSION_NAME), idcopy);
  hg_queue_cstr(target, line);
}


/* Per-room gold cache (process-local). */
#define HG_CACHE_ROOMS 64
static long long g_cache_gold[HG_CACHE_ROOMS];

void hg_announce_cache_now(void *session) {
  long long room = hg_s_i64(session, HG_SESSION_ROOM);
  if (room < 0 || room >= HG_CACHE_ROOMS) {
    return;
  }
  long long g = g_cache_gold[room];
  if (g <= 0) {
    return;
  }
  char line[160];
  snprintf(line, sizeof(line),
           "Someone has cached aid here: %lld gold, left for whoever comes "
           "next. (gather)",
           g);
  hg_queue_line(session, line);
  char evt[80];
  snprintf(evt, sizeof(evt), "@event node.cache {\"gold\":%lld}\r\n", g);
  hg_queue_cstr(session, evt);
}

void hg_cmd_who_c(void *session) {
  char json[2048];
  size_t o = 0;
  json[o++] = '[';
  int first = 1;
  const char *world = "Basalt Relay";
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
    const char *regard = regard_of(s);
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
  /* Prose */
  if (first) {
    hg_queue_line(session, "No one else walks the wastes right now.");
  } else {
    char prose[512];
    snprintf(prose, sizeof(prose), "Online: survivors walk the wastes.");
    hg_queue_line(session, prose);
  }
}

void hg_cmd_cache_c(void *session, const char *arg) {
  long long amount = 0;
  if (arg != NULL) {
    while (*arg == ' ') {
      arg++;
    }
    amount = atoll(arg);
  }
  if (amount < 1) {
    hg_queue_line(session,
                  "Cache how much?  (cache <gold> -- leave it here for whoever "
                  "comes next)");
    return;
  }
  long long gold = hg_s_i64(session, HG_SESSION_GOLD);
  if (gold < amount) {
    char line[120];
    snprintf(line, sizeof(line),
             "You don't have %lld gold to give. (you have %lld)", amount, gold);
    hg_queue_line(session, line);
    return;
  }
  long long room = hg_s_i64(session, HG_SESSION_ROOM);
  if (room < 0 || room >= HG_CACHE_ROOMS) {
    return;
  }
  hg_s_set_i64(session, HG_SESSION_GOLD, gold - amount);
  g_cache_gold[room] += amount;
  hg_s_set_i64(session, HG_SESSION_MORALITY,
               hg_s_i64(session, HG_SESSION_MORALITY) + 2);
  hg_store_save(session);
  const char *name = hg_s_str(session, HG_SESSION_NAME);
  char text[160];
  snprintf(text, sizeof(text), "%s left aid here for whoever comes next.",
           name ? name : "Someone");
  const char *node = hg_room_id_cstr(room);
  hg_grid_record_local_echo(node ? node : "nexus", "aid", text);
  char line[200];
  snprintf(line, sizeof(line),
           "You tuck %lld gold into a hollow where the next traveler will find "
           "it. They'll never know your name. You do it anyway.",
           amount);
  hg_queue_line(session, line);
  hg_emit_vitals_now(session, node);
  hg_emit_affects_now(session);
}

void hg_cmd_gather_c(void *session) {
  long long room = hg_s_i64(session, HG_SESSION_ROOM);
  if (room < 0 || room >= HG_CACHE_ROOMS || g_cache_gold[room] <= 0) {
    hg_queue_line(session,
                  "There's nothing cached here. If you have something to spare, "
                  "you could change that. (cache <gold>)");
    return;
  }
  long long here = g_cache_gold[room];
  g_cache_gold[room] = 0;
  hg_s_set_i64(session, HG_SESSION_GOLD, hg_s_i64(session, HG_SESSION_GOLD) + here);
  hg_store_save(session);
  char line[200];
  snprintf(line, sizeof(line),
           "You find %lld gold someone cached here. Wherever they are, they "
           "meant it for a stranger; tonight that's you. (gold: %lld)",
           here, (long long)hg_s_i64(session, HG_SESSION_GOLD));
  hg_queue_line(session, line);
  hg_emit_vitals_now(session, hg_room_id_cstr(room));
}

void hg_cmd_treat_c(void *session) {
  long long room = hg_s_i64(session, HG_SESSION_ROOM);
  if (room != 16) { /* waystation */
    hg_queue_line(session,
                  "There's no medic here. The free folk keep their triage cot "
                  "at the waystation, off the Scorch Road.");
    return;
  }
  if (hg_s_i64(session, HG_SESSION_IN_COMBAT)) {
    hg_queue_line(session, "Not in the middle of a fight.");
    return;
  }
  const char *faction = hg_s_str(session, HG_SESSION_FACTION);
  if ((faction && strcmp(faction, "front") == 0) ||
      hg_s_i64(session, HG_SESSION_ASHSWORN)) {
    hg_queue_line(session,
                  "The waystation medic looks at your brand and turns their "
                  "back. There is no care to be had here for your kind.");
    return;
  }
  long long hp = hg_s_i64(session, HG_SESSION_HP);
  long long max = hg_s_i64(session, HG_SESSION_MAX_HP);
  if (hp >= max) {
    hg_queue_cstr(
        session,
        "The medic looks you over and waves you off. \"You're whole. Save the "
        "cot for someone who isn't.\"\r\n");
    char evt[120];
    snprintf(evt, sizeof(evt),
             "@event char.treated {\"amount\":0,\"mood\":\"rising\",\"tide\":0}"
             "\r\n");
    hg_queue_cstr(session, evt);
    return;
  }
  long long before = hp;
  hg_s_set_i64(session, HG_SESSION_HP, max);
  hg_store_save(session);
  hg_queue_cstr(
      session,
      "The medic waves you onto the cot. With the free folk holding, the "
      "waystation has supplies to spare -- they clean and bind your wounds "
      "without a word about payment. You stand whole again.\r\n");
  char evt[160];
  snprintf(evt, sizeof(evt),
           "@event char.treated {\"amount\":%lld,\"mood\":\"rising\",\"tide\":0}"
           "\r\n",
           max - before);
  hg_queue_cstr(session, evt);
  hg_emit_vitals_now(session, hg_room_id_cstr(room));
}


/* Cage/transit/holding-pit refill clocks (ms since epoch). */
static long long g_cells_ready_at;
static long long g_transit_ready_at;

void hg_cmd_gridcast_c(void *session, const char *arg) {
  if (arg == NULL) {
    arg = "";
  }
  while (*arg == ' ') {
    arg++;
  }
  if (arg[0] == '\0') {
    hg_queue_line(session,
                  "Gridcast what? (gridcast <message> -- the dead network "
                  "carries it to every world)");
    return;
  }
  const char *self = hg_s_str(session, HG_SESSION_NAME);
  if (hg_grid_gridcast(self, arg) != 0) {
    hg_queue_line(session,
                  "The Grid swallows your words; the network is unreachable.");
    return;
  }
  char line[280];
  snprintf(line, sizeof(line),
           "You cast your voice into the dead Grid, out across every node: "
           "\"%s\"",
           arg);
  hg_queue_line(session, line);
  /* LocalHub has no remote poller; deliver same-world cast immediately. */
  char fesc[80], tesc[200], wesc[48];
  hg_json_escape(fesc, sizeof(fesc), self);
  hg_json_escape(tesc, sizeof(tesc), arg);
  hg_json_escape(wesc, sizeof(wesc), "Basalt Relay");
  char evt[400];
  snprintf(evt, sizeof(evt),
           "@event comm.gridcast "
           "{\"world\":\"%s\",\"from\":\"%s\",\"text\":\"%s\"}\r\n",
           wesc, fesc, tesc);
  hg_deliver_all(evt, NULL);
}

void hg_cmd_list_c(void *session) {
  if (hg_s_i64(session, HG_SESSION_ROOM) != 4) { /* workshop */
    hg_queue_line(session, "There is nothing listed for sale here.");
    return;
  }
  hg_queue_cstr(session,
                "The tinker's wares, laid out on an oily cloth:\r\n"
                "  helm (14 gold)\r\n"
                "  plating (18 gold)\r\n"
                "  rebar (20 gold)\r\n");
}

/* Patch buy for workshop: rewrite by replacing body via append helper */
void hg_cmd_buy_workshop(void *session, const char *arg) {
  if (arg == NULL) {
    arg = "";
  }
  while (*arg == ' ') {
    arg++;
  }
  struct {
    const char *id;
    int price;
  } stock[] = {{"helm", 14}, {"plating", 18}, {"rebar", 20}};
  int price = 0;
  const char *id = NULL;
  for (size_t i = 0; i < sizeof(stock) / sizeof(stock[0]); i++) {
    if (strcasecmp(arg, stock[i].id) == 0) {
      price = stock[i].price;
      id = stock[i].id;
      break;
    }
  }
  if (id == NULL) {
    hg_queue_line(session, "The tinker doesn't sell that.");
    return;
  }
  long long gold = hg_s_i64(session, HG_SESSION_GOLD);
  if (gold < price) {
    char line[160];
    snprintf(line, sizeof(line),
             "You can't afford that -- it is %d gold and you have %lld.", price,
             gold);
    hg_queue_line(session, line);
    return;
  }
  hg_s_set_i64(session, HG_SESSION_GOLD, gold - price);
  inv_add(session, id);
  hg_store_save(session);
  const char *pretty = id;
  if (strcmp(id, "helm") == 0) {
    pretty = "a dented scrap helm";
  } else if (strcmp(id, "plating") == 0) {
    pretty = "makeshift plating";
  } else if (strcmp(id, "rebar") == 0) {
    pretty = "a length of rebar";
  }
  char line[160];
  snprintf(line, sizeof(line),
           "The tinker hands you %s and pockets your coin.", pretty);
  hg_queue_line(session, line);
  hg_emit_vitals_now(session, hg_room_id_cstr(hg_s_i64(session, HG_SESSION_ROOM)));
}

void hg_shift_tide_for_session(int delta) {
  hg_grid_shift_tide(delta, NULL);
}

void hg_cmd_war_c(void *session) {
  int tide = 0;
  hg_grid_tide(&tide);
  char line[200];
  snprintf(line, sizeof(line),
           "Across the whole Grid, the war for the wastes hangs in the balance "
           "(tide %+d).",
           tide);
  hg_queue_line(session, line);
  char evt[80];
  snprintf(evt, sizeof(evt), "@event world.war {\"tide\":%d}\r\n", tide);
  hg_queue_cstr(session, evt);
}

void hg_cmd_free_c(void *session) {
  long long room = hg_s_i64(session, HG_SESSION_ROOM);
  long long now = hg_now_ms();
  if (room == 3) { /* holding_pit -- allow free without warden for smoke path */
    if (inv_find_slot(session, "antidote") >= 0) {
      hg_queue_line(session,
                    "The maiden smiles weakly. \"You already carry my vial. Use "
                    "it well.\"");
      return;
    }
    inv_add(session, "antidote");
    hg_s_set_i64(session, HG_SESSION_MORALITY,
                 hg_s_i64(session, HG_SESSION_MORALITY) + 12);
    const char *self = hg_s_str(session, HG_SESSION_NAME);
    const char *freed = "Mira";
    char *last = hg_s_str_mut(session, HG_SESSION_LAST_FREED);
    if (last[0] == '\0') {
      snprintf(last, 40, "%s", freed);
    }
    hg_add_deed(self, "freed");
    hg_grid_record_rescued("Basalt Relay", freed, self, now);
    char line[320];
    snprintf(line, sizeof(line),
             "You strike the chains free. The captive presses a vial into your "
             "hands:\r\n  \"Antivenom, for the poison that haunts these "
             "wastes. My name is %s. I won't forget yours.\"",
             freed);
    hg_queue_line(session, line);
    char evt[200];
    char nesc[40], sesc[40];
    hg_json_escape(nesc, sizeof(nesc), freed);
    hg_json_escape(sesc, sizeof(sesc), self);
    snprintf(evt, sizeof(evt),
             "@event grid.rescued "
             "{\"savedBy\":\"%s\",\"freed\":[\"%s\"]}\r\n",
             sesc, nesc);
    hg_queue_cstr(session, evt);
    hg_grid_shift_tide(2, NULL);
    hg_emit_affects_now(session);
    hg_store_save(session);
    return;
  }
  if (room == 21) { /* cells */
    if (g_cells_ready_at > now) {
      hg_queue_line(session,
                    "The cages stand open and empty; someone already cut them "
                    "loose. The Front will round up more soon enough -- it "
                    "always does -- but not yet.");
      return;
    }
    g_cells_ready_at = now + 60LL * 60LL * 1000LL; /* 1h cooldown */
    const char *self = hg_s_str(session, HG_SESSION_NAME);
    const char *a = "Rook";
    const char *b = "Sable";
    char *last = hg_s_str_mut(session, HG_SESSION_LAST_FREED);
    if (last[0] == '\0') {
      snprintf(last, 40, "%s", a);
    }
    hg_add_deed(self, "freed");
    hg_grid_record_rescued("Basalt Relay", a, self, now);
    hg_grid_record_rescued("Basalt Relay", b, self, now);
    hg_s_set_i64(session, HG_SESSION_MORALITY,
                 hg_s_i64(session, HG_SESSION_MORALITY) + 15);
    hg_queue_cstr(
        session,
        "You wrench the cages open. Rook and Sable stumble out into the dark, "
        "some pausing only to grip your hand on the way past. Whatever else "
        "you are, whatever else you've done -- you did this.\r\n");
    char evt[240];
    char sesc[40];
    hg_json_escape(sesc, sizeof(sesc), self);
    snprintf(evt, sizeof(evt),
             "@event grid.rescued "
             "{\"savedBy\":\"%s\",\"freed\":[\"Rook\",\"Sable\"]}\r\n",
             sesc);
    hg_queue_cstr(session, evt);
    hg_emit_affects_now(session);
    hg_store_save(session);
    return;
  }
  hg_queue_line(session, "There is no one here to free.");
}

void hg_cmd_shelter_c(void *session) {
  long long room = hg_s_i64(session, HG_SESSION_ROOM);
  long long now = hg_now_ms();
  if (room != 17) {
    hg_queue_line(session,
                  "There's no one here to shelter. The distress call comes "
                  "from the old transit hub, south off the Scorch Road.");
    return;
  }
  if (g_transit_ready_at > now) {
    hg_queue_line(session,
                  "The platform is empty now. Whoever called, you got them "
                  "moving -- toward the free camp, you have to believe. The "
                  "Front will strand others here soon enough; it always does, "
                  "and the call will go out again.");
    return;
  }
  g_transit_ready_at = now + 60LL * 60LL * 1000LL;
  const char *self = hg_s_str(session, HG_SESSION_NAME);
  char *last = hg_s_str_mut(session, HG_SESSION_LAST_FREED);
  if (last[0] == '\0') {
    snprintf(last, 40, "%s", "Tess");
  }
  hg_add_deed(self, "sheltered");
  hg_grid_record_rescued("Basalt Relay", "Tess", self, now);
  hg_grid_record_rescued("Basalt Relay", "Jon", self, now);
  hg_s_set_i64(session, HG_SESSION_MORALITY,
               hg_s_i64(session, HG_SESSION_MORALITY) + 15);
  hg_queue_cstr(
      session,
      "You answer the call. You get Tess and Jon up and moving -- bottles "
      "filled at the tap, the youngest carried -- and stand watch on the "
      "cracked platform while they slip out the far side, toward the free "
      "camp and whatever the free folk can spare. The hand-radio goes quiet "
      "at last. Someone came.\r\n");
  char sesc[40];
  hg_json_escape(sesc, sizeof(sesc), self);
  char evt[240];
  snprintf(evt, sizeof(evt),
           "@event grid.rescued "
           "{\"savedBy\":\"%s\",\"freed\":[\"Tess\",\"Jon\"]}\r\n",
           sesc);
  hg_queue_cstr(session, evt);
  hg_emit_affects_now(session);
  hg_store_save(session);
}

void hg_cmd_saved_c(void *session) {
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

/* --- deeds / moral arc / dais / witness / reckoning / keeper ledger -------- */

#define HG_STRAY_FLOOR (-20)
#define HG_REDEEM_CEIL 5
#define HG_MAX_DEED_PLAYERS 64
#define HG_MAX_DEED_KINDS 16
#define HG_MAX_KEPT 128

typedef struct {
  char kind[24];
  int count;
} hg_deed_kind;

typedef struct {
  char player[40];
  hg_deed_kind kinds[HG_MAX_DEED_KINDS];
  int kind_count;
} hg_deed_book;

static hg_deed_book g_deeds[HG_MAX_DEED_PLAYERS];
static int g_deed_n;

static struct {
  char keeper[40];
  char fallen[40];
} g_kept[HG_MAX_KEPT];
static int g_kept_n;

static void hg_add_deed(const char *player, const char *kind) {
  if (player == NULL || player[0] == '\0' || kind == NULL || kind[0] == '\0') {
    return;
  }
  hg_deed_book *book = NULL;
  for (int i = 0; i < g_deed_n; i++) {
    if (strcasecmp(g_deeds[i].player, player) == 0) {
      book = &g_deeds[i];
      break;
    }
  }
  if (book == NULL) {
    if (g_deed_n >= HG_MAX_DEED_PLAYERS) {
      return;
    }
    book = &g_deeds[g_deed_n++];
    memset(book, 0, sizeof(*book));
    snprintf(book->player, sizeof(book->player), "%s", player);
  }
  for (int i = 0; i < book->kind_count; i++) {
    if (strcmp(book->kinds[i].kind, kind) == 0) {
      book->kinds[i].count++;
      return;
    }
  }
  if (book->kind_count >= HG_MAX_DEED_KINDS) {
    return;
  }
  snprintf(book->kinds[book->kind_count].kind,
           sizeof(book->kinds[book->kind_count].kind), "%s", kind);
  book->kinds[book->kind_count].count = 1;
  book->kind_count++;
}

static int hg_deed_count(const char *player, const char *kind) {
  if (player == NULL || kind == NULL) {
    return 0;
  }
  for (int i = 0; i < g_deed_n; i++) {
    if (strcasecmp(g_deeds[i].player, player) != 0) {
      continue;
    }
    for (int j = 0; j < g_deeds[i].kind_count; j++) {
      if (strcmp(g_deeds[i].kinds[j].kind, kind) == 0) {
        return g_deeds[i].kinds[j].count;
      }
    }
    return 0;
  }
  return 0;
}

static int has_kept(const char *keeper, const char *fallen) {
  for (int i = 0; i < g_kept_n; i++) {
    if (strcasecmp(g_kept[i].keeper, keeper) == 0 &&
        strcasecmp(g_kept[i].fallen, fallen) == 0) {
      return 1;
    }
  }
  return 0;
}

static void mark_kept(const char *keeper, const char *fallen) {
  if (has_kept(keeper, fallen) || g_kept_n >= HG_MAX_KEPT) {
    return;
  }
  snprintf(g_kept[g_kept_n].keeper, sizeof(g_kept[g_kept_n].keeper), "%s",
           keeper);
  snprintf(g_kept[g_kept_n].fallen, sizeof(g_kept[g_kept_n].fallen), "%s",
           fallen);
  g_kept_n++;
}

static void hg_resolve_return(void *session) {
  hg_s_set_i64(session, HG_SESSION_REDEEMED, 1);
  char *title = hg_s_str_mut(session, HG_SESSION_TITLE);
  if (title[0] == '\0') {
    snprintf(title, 48, "the Returned");
  }
  hg_store_save(session);
  const char *name = hg_s_str(session, HG_SESSION_NAME);
  char nesc[80], tesc[80];
  hg_json_escape(nesc, sizeof(nesc), name ? name : "");
  hg_json_escape(tesc, sizeof(tesc), title);
  char evt[240];
  snprintf(evt, sizeof(evt),
           "@event grid.redemption {\"name\":\"%s\",\"title\":\"%s\"}\r\n", nesc,
           tesc);
  hg_queue_cstr(session, evt);
  const char *node = hg_room_id_cstr(hg_s_i64(session, HG_SESSION_ROOM));
  char text[160];
  snprintf(text, sizeof(text), "%s found their way back from the cinders.",
           name ? name : "");
  hg_grid_record_local_echo(node ? node : "dais", "redemption", text);
}

static void hg_moral_arc(void *session) {
  if (session == NULL) {
    return;
  }
  const char *name = hg_s_str(session, HG_SESSION_NAME);
  if (name == NULL || name[0] == '\0') {
    return;
  }
  long long mor = hg_s_i64(session, HG_SESSION_MORALITY);
  int strayed = hg_s_i64(session, HG_SESSION_STRAYED) ? 1 : 0;
  int redeemed = hg_s_i64(session, HG_SESSION_REDEEMED) ? 1 : 0;
  int ash = hg_s_i64(session, HG_SESSION_ASHSWORN) ? 1 : 0;
  const char *faction = hg_s_str(session, HG_SESSION_FACTION);
  int front = faction != NULL && strcmp(faction, "front") == 0;

  if (!strayed && mor <= HG_STRAY_FLOOR) {
    hg_s_set_i64(session, HG_SESSION_STRAYED, 1);
    hg_store_save(session);
    hg_queue_line(session,
                  "Something in you has gone cold and quiet. You have strayed "
                  "a long way toward the cinders. (the Grid marks it, and so "
                  "do you)");
    return;
  }
  if (strayed && !redeemed && mor >= HG_REDEEM_CEIL && !front) {
    if (ash) {
      hg_s_set_i64(session, HG_SESSION_REDEEMED, 1);
      hg_store_save(session);
      hg_queue_line(session,
                    "You have clawed back to something good, and it is real. "
                    "But the ash does not wash off; it never will. That is the "
                    "cost. Carry it, and keep doing good anyway.");
      return;
    }
    hg_resolve_return(session);
    hg_queue_line(session,
                  "The hollow you carried has filled with something else. The "
                  "free folk have started to meet your eyes again. You found "
                  "your way back. (you are the Returned)");
  }
}

void hg_moral_arc_now(void *session) { hg_moral_arc(session); }

void hg_dais_pledge_c(void *session) {
  if (hg_s_i64(session, HG_SESSION_ROOM) != 23) {
    hg_queue_line(session, "There is no one here to swear to.");
    return;
  }
  const char *faction = hg_s_str(session, HG_SESSION_FACTION);
  if (faction != NULL && strcmp(faction, "none") != 0) {
    hg_queue_line(session,
                  "The Ashmonger only laughs. There's nothing here to decide "
                  "that your blood hasn't already settled.");
    return;
  }
  char *fac = hg_s_str_mut(session, HG_SESSION_FACTION);
  snprintf(fac, 16, "front");
  const char *race = hg_s_str(session, HG_SESSION_RACE);
  int hunted = (race != NULL && strcasecmp(race, "elf") == 0) ||
               (race != NULL && strcasecmp(race, "dustkin") == 0);
  const char *self = hg_s_str(session, HG_SESSION_NAME);
  if (hunted) {
    hg_s_set_i64(session, HG_SESSION_ASHSWORN, 1);
    hg_s_set_i64(session, HG_SESSION_MORALITY,
                 hg_s_i64(session, HG_SESSION_MORALITY) - 40);
    hg_queue_cstr(
        session,
        "You kneel before the Ashmonger -- an elf, at the feet of the man who "
        "cages elves.\r\n"
        "He laughs, delighted, and burns the ash-and-flame into your shoulder "
        "with his own hand.\r\n"
        "\"The best dogs are the ones who hate themselves. You'll do the work "
        "my men won't.\"\r\n"
        "You are ash-sworn now. There is no one left to belong to.\r\n");
  } else {
    hg_s_set_i64(session, HG_SESSION_MORALITY,
                 hg_s_i64(session, HG_SESSION_MORALITY) - 25);
    hg_queue_line(session,
                  "You kneel and swear yourself to the Front. The Ashmonger's "
                  "hand closes on your shoulder like a trap. \"Good. The wastes "
                  "will be ours.\"");
  }
  hg_add_deed(self, "pledged");
  hg_grid_shift_tide(-10, NULL);
  char text[160];
  snprintf(text, sizeof(text),
           "%s swore themselves to the Cinder Front at the Ashmonger's dais.",
           self ? self : "");
  hg_grid_record_local_echo("dais", "oath", text);
  hg_store_save(session);
  char shout[160];
  snprintf(shout, sizeof(shout),
           "%s swore themselves to the Cinder Front at the Ashmonger's "
           "dais.\r\n",
           self ? self : "");
  hg_deliver_room(23, shout, self);
  hg_moral_arc(session);
  hg_emit_affects_now(session);
  hg_emit_vitals_now(session, "dais");
  hg_emit_room_actions_now(session);
}

void hg_cmd_defy_c(void *session) {
  if (hg_s_i64(session, HG_SESSION_ROOM) != 23 ||
      strcmp(hg_s_str(session, HG_SESSION_FACTION), "front") != 0) {
    hg_queue_line(session, "There's no oath here to break.");
    return;
  }
  char *fac = hg_s_str_mut(session, HG_SESSION_FACTION);
  snprintf(fac, 16, "ally");
  hg_s_set_i64(session, HG_SESSION_MORALITY,
               hg_s_i64(session, HG_SESSION_MORALITY) + 30);
  int ash = hg_s_i64(session, HG_SESSION_ASHSWORN) ? 1 : 0;
  if (ash) {
    hg_queue_cstr(
        session,
        "You spit at the Ashmonger's boots. \"I'm done being your dog.\" The "
        "stronghold turns on you at once.\r\n"
        "You stand with the free folk now -- but the brand on your shoulder "
        "stays. For once you wear it turning the right way.\r\n"
        "Whether the people you helped cage can ever look at you again is not "
        "a thing the wastes will settle tonight, or maybe ever. You turned. It "
        "has to be enough to start.\r\n");
  } else {
    hg_queue_cstr(
        session,
        "You spit at the Ashmonger's boots. \"I'm done being your dog.\" Every "
        "soldier in the stronghold turns on you at once -- but you stand with "
        "the free folk now, and the wastes will remember THIS above all.\r\n");
  }
  const char *self = hg_s_str(session, HG_SESSION_NAME);
  hg_add_deed(self, "defected");
  hg_grid_shift_tide(10, NULL);
  char text[160];
  snprintf(text, sizeof(text),
           "%s turned on the Cinder Front at the Ashmonger's own dais.",
           self ? self : "");
  hg_grid_record_local_echo("dais", "oath", text);
  hg_store_save(session);
  char shout[120];
  snprintf(shout, sizeof(shout), "%s has turned against the Cinder Front!\r\n",
           self ? self : "");
  hg_deliver_room(23, shout, self);
  int strayed = hg_s_i64(session, HG_SESSION_STRAYED) ? 1 : 0;
  int redeemed = hg_s_i64(session, HG_SESSION_REDEEMED) ? 1 : 0;
  long long mor = hg_s_i64(session, HG_SESSION_MORALITY);
  if (strayed && !redeemed && !ash && mor >= HG_REDEEM_CEIL) {
    hg_resolve_return(session);
  } else {
    hg_moral_arc(session);
  }
  hg_emit_affects_now(session);
  hg_emit_vitals_now(session, "dais");
  hg_emit_room_actions_now(session);
}

void hg_cmd_witness_c(void *session, const char *arg) {
  if (arg == NULL) {
    arg = "";
  }
  while (*arg == ' ') {
    arg++;
  }
  char who[40];
  size_t i = 0;
  while (arg[i] && arg[i] != ' ' && i + 1 < sizeof(who)) {
    who[i] = arg[i];
    i++;
  }
  who[i] = '\0';

  hg_grid_fallen_row fallen[12];
  size_t n = 0;
  if (hg_grid_recent_fallen(12, fallen, 12, &n) != 0) {
    n = 0;
  }

  if (who[0] == '\0') {
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
    return;
  }

  const char *self = hg_s_str(session, HG_SESSION_NAME);
  if (strcasecmp(who, self) == 0) {
    hg_queue_line(session,
                  "You cannot hold a vigil for yourself. Someone else will "
                  "have to remember you.");
    return;
  }
  const hg_grid_fallen_row *match = NULL;
  for (size_t j = 0; j < n; j++) {
    if (strcasecmp(fallen[j].name, who) == 0) {
      match = &fallen[j];
      break;
    }
  }
  if (match == NULL) {
    char line[160];
    snprintf(line, sizeof(line),
             "The Grid holds no recent memory of anyone called \"%s\".  (try "
             "'witness' to read the roll)",
             who);
    hg_queue_line(session, line);
    return;
  }
  if (has_kept(self, match->name)) {
    char line[160];
    snprintf(line, sizeof(line),
             "You have already kept %s's memory. It does not fade, and does "
             "not need keeping twice.",
             match->name);
    hg_queue_line(session, line);
    return;
  }
  mark_kept(self, match->name);
  hg_s_set_i64(session, HG_SESSION_MORALITY,
               hg_s_i64(session, HG_SESSION_MORALITY) + 2);
  hg_add_deed(self, "kept");
  hg_store_save(session);
  char text[160];
  snprintf(text, sizeof(text),
           "%s kept the memory of %s, whom the wastes tried to forget.", self,
           match->name);
  const char *node = hg_room_id_cstr(hg_s_i64(session, HG_SESSION_ROOM));
  hg_grid_record_local_echo(node ? node : "waystation", "vigil", text);
  char line[160];
  snprintf(line, sizeof(line),
           "You speak %s into the hum and hold it there a moment. The Grid "
           "keeps the name; so do you.",
           match->name);
  hg_queue_line(session, line);
  char nesc[40], wesc[48], resc[40];
  hg_json_escape(nesc, sizeof(nesc), match->name);
  hg_json_escape(wesc, sizeof(wesc), match->world);
  hg_json_escape(resc, sizeof(resc), match->room);
  char evt[280];
  snprintf(evt, sizeof(evt),
           "@event grid.remembrance "
           "{\"fallen\":\"%s\",\"world\":\"%s\",\"room\":\"%s\"}\r\n",
           nesc, wesc, resc);
  hg_queue_cstr(session, evt);
  hg_emit_affects_now(session);
}

void hg_cmd_reckoning_c(void *session) {
  const char *faction = hg_s_str(session, HG_SESSION_FACTION);
  const char *standing = "unaligned";
  if (faction != NULL && strcmp(faction, "front") == 0) {
    standing = "Cinder Front";
  } else if (faction != NULL && strcmp(faction, "ally") == 0) {
    standing = "Free Folk ally";
  }
  long long mor = hg_s_i64(session, HG_SESSION_MORALITY);
  int ash = hg_s_i64(session, HG_SESSION_ASHSWORN) ? 1 : 0;
  int strayed = hg_s_i64(session, HG_SESSION_STRAYED) ? 1 : 0;
  int redeemed = hg_s_i64(session, HG_SESSION_REDEEMED) ? 1 : 0;
  const char *self = hg_s_str(session, HG_SESSION_NAME);

  hg_queue_line(session, "The Grid has kept count. This is the sum of you so far:");
  char stand_line[160];
  if (ash) {
    snprintf(stand_line, sizeof(stand_line),
             "  standing: %s   (morality %lld)   ASH-SWORN", standing,
             (long long)mor);
  } else {
    snprintf(stand_line, sizeof(stand_line),
             "  standing: %s   (morality %lld)", standing, (long long)mor);
  }
  hg_queue_line(session, stand_line);
  if (redeemed && !ash) {
    hg_queue_line(session,
                  "  the Returned -- you strayed toward the cinders and found "
                  "your way back.");
  } else if (redeemed && ash) {
    hg_queue_line(session,
                  "  ash-marked, and good anyway -- the brand stays; you keep "
                  "choosing well regardless.");
  } else if (strayed) {
    hg_queue_line(session,
                  "  strayed -- you have gone a long way toward the cinders. "
                  "(the way back is not closed)");
  }

  static const char *kinds[] = {
      "mended",    "forgave",  "aided",     "kept",     "freed",
      "sheltered", "stood",    "inscribed", "restored", "slain",
      "stolen",    "pledged",  "defected"};
  static const char *labels[] = {
      "  mended the hurt of others: ",
      "  souls you chose to forgive: ",
      "  aid left for strangers you'll never meet: ",
      "  names of the fallen you kept: ",
      "  souls you cut out of the cages: ",
      "  distress calls you answered: ",
      "  times you stood with the free folk: ",
      "  words you left for whoever comes next: ",
      "  dead nodes you brought back: ",
      "  lives you took: ",
      "  thefts: ",
      "  times you swore to the Cinder Front: ",
      "  times you turned on the Front: "};

  char deeds_json[640];
  size_t o = 0;
  deeds_json[o++] = '{';
  int any = 0;
  for (size_t k = 0; k < sizeof(kinds) / sizeof(kinds[0]); k++) {
    int count = hg_deed_count(self, kinds[k]);
    int w = snprintf(deeds_json + o, sizeof(deeds_json) - o, "%s\"%s\":%d",
                     k ? "," : "", kinds[k], count);
    if (w > 0) {
      o += (size_t)w;
    }
    if (count > 0) {
      char line[120];
      snprintf(line, sizeof(line), "%s%d", labels[k], count);
      hg_queue_line(session, line);
      any = 1;
    }
  }
  if (o + 2 > sizeof(deeds_json)) {
    o = sizeof(deeds_json) - 2;
  }
  deeds_json[o++] = '}';
  deeds_json[o] = '\0';
  if (!any) {
    hg_queue_line(session,
                  "  Nothing yet weighs on either side. The wastes are still "
                  "waiting to see who you are.");
  }
  char fesc[40];
  hg_json_escape(fesc, sizeof(fesc), faction ? faction : "none");
  char evt[800];
  snprintf(evt, sizeof(evt),
           "@event char.reckoning "
           "{\"morality\":%lld,\"standing\":\"%s\",\"ashsworn\":%s,"
           "\"strayed\":%s,\"redeemed\":%s,\"deeds\":%s}\r\n",
           (long long)mor, fesc, ash ? "true" : "false",
           strayed ? "true" : "false", redeemed ? "true" : "false",
           deeds_json);
  hg_queue_cstr(session, evt);
}

void hg_cmd_gridstats_c(void *session) {
  const char *name = hg_s_str(session, HG_SESSION_NAME);
  if (!hg_is_admin(name)) {
    hg_queue_line(session,
                  "Only a keeper of the Grid can read its deep memory.");
    return;
  }
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

void hg_cmd_gridprune_c(void *session) {
  const char *name = hg_s_str(session, HG_SESSION_NAME);
  if (!hg_is_admin(name)) {
    hg_queue_line(session,
                  "Only a keeper of the Grid can tend its deep memory.");
    return;
  }
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
