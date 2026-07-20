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
int hg_dream_compose(const void *session, char *text, size_t tcap,
                     char *subject, size_t scap);
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
/* Action menu + valence authored in asm; C only emits @event around it. */
int hg_actions_json_for(void *session, char *buf, size_t cap);
void hg_emit_room_actions_now(void *session);
void hg_emit_grid_who_now(void *session);
void hg_emit_char_reckoning_now(void *session);
void hg_emit_comm_gridcast_now(void *session, const char *text);
void hg_emit_saved_roll_now(void *session);
void hg_emit_fallen_roll_now(void *session);
void hg_emit_gridstats_cmd_now(void *session);
void hg_emit_gridprune_cmd_now(void *session);
void hg_emit_forgiven_target_now(void *target, void *forgiver, int ashsworn,
                                 int redeemed_path);
void hg_emit_forgiven_redeemed_now(void *target, void *forgiver);

extern const char *hg_regard_of(const void *session);
extern void hg_deed_add_str(const char *player, const char *kind);
extern int hg_deed_count_str(const char *player, const char *kind);
extern int hg_forgiven_has(const char *forgiver, const char *subject);
extern void hg_forgiven_mark(const char *forgiver, const char *subject);
extern int hg_kept_has(const char *keeper, const char *fallen);
extern void hg_kept_mark(const char *keeper, const char *fallen);

extern void hg_moral_arc_now(void *session);
extern void hg_announce_cache_now(void *session);
extern long long hg_cache_gold_peek(int64_t room);
extern void hg_cache_gold_add(int64_t room, long long amount);
extern long long hg_cache_gold_take(int64_t room);
extern long long hg_cells_ready_at_get(void);
extern void hg_cells_ready_at_set(long long when);
extern long long hg_transit_ready_at_get(void);
extern void hg_transit_ready_at_set(long long when);

/* hg_is_admin is implemented in asm (social_ledger.asm). */
int hg_is_admin(const char *name);

/* Broadcast helpers (iterate asm session registry). */
void hg_deliver_room(int64_t room, const char *text, const char *except_name);
void hg_deliver_all(const char *text, const char *except_name);

/* Asm-exported registry walk used by deliver helpers. */
extern int hg_session_count(void);
extern void *hg_session_at(int index);
extern const char *hg_room_id_cstr(int64_t room);

#endif /* HG_FORMAT_H */
