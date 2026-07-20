#ifndef HG_GRID_H
#define HG_GRID_H

/* Federation seam for the Basalt Relay assembly world.
 *
 * ASM owns LocalHub memory, tide clamp, prune application, and when to call
 * the hub. C owns RemoteHub libcurl/cJSON transport and hub-backed prose /
 * @event wrappers (see docs/ARCHITECTURE.md). Every call here is fail-open:
 * a hub error or timeout never blocks local play.
 */

#include <stddef.h>

/* Boot the hub client. world_url may be NULL/empty (falls back to
 * ws://127.0.0.1:<port>/ws by convention, computed by the caller).
 * hub_url NULL/empty selects LocalHub (in-memory, always available).
 * Returns 0 on success. Never fails hard: LocalHub construction cannot fail. */
/* Configured world id (as booted), for @event payloads that claim a world. */
const char *hg_grid_world_name(void);

int hg_grid_boot(const char *world_name, const char *world_url,
                 const char *hub_url, const char *token);
void hg_grid_shutdown(void);

/* 1 if a remote Grid Hub URL was configured (RemoteHub mode). */
int hg_grid_remote(void);

/* Liveness probe used by /health/deep. LocalHub: always ok=1, latency=0.
 * RemoteHub: pings tide() and measures latency. Always returns 0 (never
 * treat federation health as fatal); *ok reflects reachability. */
int hg_grid_health(int *ok, long *latency_ms);

/* Record one cross-world trace. Fail-open: errors are swallowed. */
int hg_grid_record(const char *world, const char *node, const char *kind,
                   const char *text, long long at_ms);

/* Node-local memory (grid.echo / room-scoped ping), kept even in remote mode
 * so ping never depends on hub reachability. */
int hg_grid_record_local_echo(const char *node, const char *kind,
                              const char *text);
/* Player-left mark on a node (inscribe). */
int hg_grid_inscribe(const char *node, const char *name, const char *msg);

int hg_grid_record_fallen(const char *world, const char *name,
                          const char *room, long long at_ms);
int hg_grid_record_rescued(const char *world, const char *name,
                           const char *saved_by, long long at_ms);

/* Convenience wrappers combining a hub record with the local echo, used by
 * the world's combat/lifecycle hooks. Both are best-effort, never fail the
 * caller, and record against this world's own name (set at hg_grid_boot). */
int hg_grid_on_kill(const char *room_id, const char *slayer,
                    const char *mob_name);
int hg_grid_on_death(const char *room_id, const char *name);

/* Registers this world's name/url with the hub (self-registration). */
int hg_grid_register_self(void);

/* One player's live presence (best-effort; remote mode only calls the hub). */
int hg_grid_report_presence_player(const char *name, const char *regard,
                                   const char *title, long long at_ms);

/* Rate-limited periodic federation work (register + health probe). Safe to
 * call every service-loop tick; internally no-ops until ~10s have passed. */
void hg_grid_federation_tick(long long now_ms);

/* Local session fields needed to format whoami/identity output. Strings may
 * be empty but must not be NULL. */
typedef struct {
  const char *name;
  long level;
  long xp;
  long gold;
  const char *faction;
  long morality;
  const char *title;
  const char *race;
  long ashsworn;
} hg_grid_identity_ctx;

/* Format helpers: each writes CRLF-terminated prose plus one or more
 * "@event <name> {json}\r\n" lines into buf and returns the byte length, or
 * -1 if cap was too small. Callers queue the bytes directly (no extra
 * strlen needed on success). */
int hg_grid_fmt_listen(char *buf, size_t cap);
int hg_grid_fmt_ping_echo(char *buf, size_t cap, const char *room_id);
int hg_grid_fmt_ping_all(char *buf, size_t cap);
int hg_grid_fmt_worlds(char *buf, size_t cap);
int hg_grid_fmt_travel(char *buf, size_t cap, const char *target,
                       int *out_handoff);
int hg_grid_fmt_whoami(char *buf, size_t cap, const hg_grid_identity_ctx *ctx);

/* Remaining RPC surface (docs/PLAN.md Phase 3): supported by this client so a
 * later phase can wire more player/keeper commands. Not all of these have an
 * ASM command yet -- see docs/PLAN.md for the honest list of what's wired. */
int hg_grid_tide(int *out_tide);
int hg_grid_shift_tide(int delta, int *out_tide);
int hg_grid_gridcast(const char *sender, const char *text);
int hg_grid_commit_character(const char *name,
                             const hg_grid_identity_ctx *ctx);
/* Load or commit the canonical identity fields carried by an ASM session.
 * load returns 1 when a canonical race exists, 0 for a new/standalone
 * character, and -1 when the remote hub is unavailable. */
int hg_grid_load_session(void *session);
int hg_grid_commit_session(void *session);

typedef struct {
  char world[48];
  char name[33];
  char saved_by[33];
  long long at;
} hg_grid_rescued_row;

typedef struct {
  char world[48];
  char name[33];
  char room[32];
  long long at;
} hg_grid_fallen_row;

typedef struct {
  char kind[32];
  int count;
} hg_grid_ledger_row;

typedef struct {
  int id;
  char world[48];
  char sender[33];
  char text[240];
} hg_grid_cast_row;

typedef struct {
  char world[48];
  char name[33];
  char regard[48];
  char title[48];
  long long at;
} hg_grid_presence_row;

int hg_grid_recent_rescued(int limit, hg_grid_rescued_row *out, size_t cap,
                          size_t *out_count);
int hg_grid_recent_fallen(int limit, hg_grid_fallen_row *out, size_t cap,
                         size_t *out_count);
int hg_grid_ledger_stats(hg_grid_ledger_row *out, size_t cap,
                        size_t *out_count);
int hg_grid_prune_ledger(int *removed);
/* Asm policy: which trace kinds gridprune removes. */
int hg_prune_kind_ambient(const char *kind);
int hg_prune_ambient_count(void);
const char *hg_prune_ambient_at(int index);
int hg_grid_casts_since(int since_id, int limit, hg_grid_cast_row *out,
                       size_t cap, size_t *out_count);
int hg_grid_presence(long long max_age_ms, hg_grid_presence_row *out,
                    size_t cap, size_t *out_count);

#endif
