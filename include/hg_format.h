#ifndef HG_FORMAT_H
#define HG_FORMAT_H

#include <stddef.h>
#include <stdint.h>

/* JSON-safe copy of src into dst (quotes/backslashes escaped). Returns bytes
 * written excluding NUL, or -1 if truncated. */
int hg_json_escape(char *dst, size_t cap, const char *src);

/* Format helpers write into buf and return strlen, or -1 on truncate. */
int hg_fmt_vitals(char *buf, size_t cap, const void *session, const char *room_id);
int hg_fmt_affects(char *buf, size_t cap, const void *session);
int hg_fmt_equipment(char *buf, size_t cap, const void *session);
int hg_fmt_dream(char *buf, size_t cap, const void *session);
int hg_fmt_world_state(char *buf, size_t cap, int64_t tick, const char *phase);
int hg_fmt_combat_start(char *buf, size_t cap, const char *mob_id,
                        const char *mob_name);
int hg_fmt_combat_round(char *buf, size_t cap, const char *mob_id, int64_t mob_hp,
                        int64_t mob_max, int64_t player_dmg, int64_t mob_dmg,
                        int64_t hp);
int hg_fmt_combat_end(char *buf, size_t cap, const char *mob_id,
                      const char *result);
int hg_fmt_room_info(char *buf, size_t cap, const char *id, const char *name,
                     const char *exits_json, const char *mobs_json,
                     const char *players_json);
int hg_fmt_room_actions(char *buf, size_t cap, const char *actions_json);
int hg_fmt_attack_miss(char *buf, size_t cap, const char *target,
                       const char *suggestions);
int hg_fmt_who_local(char *buf, size_t cap, const void *session);
int hg_fmt_ability_recharging(char *buf, size_t cap, const char *name,
                              int seconds);
int hg_fmt_char_died(char *buf, size_t cap, const char *room, int64_t hp,
                     int64_t max_hp);

/* Queue a CRLF-terminated line (or raw bytes) onto the session outbox and
 * request a writable callback. */
void hg_queue(void *session, const char *data, size_t len);
void hg_queue_cstr(void *session, const char *cstr);
void hg_queue_line(void *session, const char *line);

/* Emit structured events from current session state. */
void hg_emit_vitals_now(void *session, const char *room_id);
void hg_emit_affects_now(void *session);
void hg_emit_equipment_now(void *session);
void hg_emit_dream_now(void *session);
void hg_emit_world_now(void *session, int64_t tick, const char *phase);
void hg_emit_scene_now(void *session);

long long hg_now_ms(void);
void hg_combat_arm(void *session, void *wsi);
const char *hg_brand_standing(const void *session);
int hg_players_json(int64_t room, const char *except_name, char *buf,
                    size_t cap);
int hg_actions_json_for(void *session, char *buf, size_t cap);
void hg_emit_room_actions_now(void *session);
void hg_join_record_oath(void *session);
void hg_cmd_sell_c(void *session, const char *arg);
void hg_cmd_steal_c(void *session);
void hg_cmd_sense_c(void *session);
int hg_cmd_look_player_c(void *session, const char *arg);
void hg_cmd_forgive_c(void *session, const char *arg);
void hg_inv_add_item(void *session, const char *id);
void hg_cmd_talk_c(void *session);
void hg_cmd_buy_c(void *session, const char *arg);
void hg_cmd_wall_c(void *session, const char *arg);
void hg_cmd_tell_c(void *session, const char *arg);
void hg_cmd_reply_c(void *session, const char *arg);
void hg_cmd_yell_c(void *session, const char *arg);
void hg_cmd_emote_c(void *session, const char *arg);
void hg_cmd_mend_c(void *session, const char *arg);
void hg_cmd_give_c(void *session, const char *arg);
void hg_announce_cache_now(void *session);
void hg_cmd_who_c(void *session);
void hg_cmd_cache_c(void *session, const char *arg);
void hg_cmd_gather_c(void *session);
void hg_cmd_treat_c(void *session);
void hg_cmd_gridcast_c(void *session, const char *arg);
void hg_cmd_list_c(void *session);
void hg_cmd_war_c(void *session);
void hg_cmd_free_c(void *session);
void hg_cmd_shelter_c(void *session);
void hg_cmd_saved_c(void *session);

void hg_moral_arc_now(void *session);
void hg_dais_pledge_c(void *session);
void hg_cmd_defy_c(void *session);
void hg_cmd_witness_c(void *session, const char *arg);
void hg_cmd_reckoning_c(void *session);
void hg_cmd_gridstats_c(void *session);
void hg_cmd_gridprune_c(void *session);

int hg_is_admin(const char *name);
void hg_admins_init(void);

/* Broadcast helpers (iterate asm session registry). */
void hg_deliver_room(int64_t room, const char *text, const char *except_name);
void hg_deliver_all(const char *text, const char *except_name);

/* Asm-exported registry walk used by deliver helpers. */
extern int hg_session_count(void);
extern void *hg_session_at(int index);
extern const char *hg_room_id_cstr(int64_t room);

#endif /* HG_FORMAT_H */
