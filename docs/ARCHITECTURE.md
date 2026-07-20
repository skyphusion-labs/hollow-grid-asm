# Architecture

Basalt Relay is a Hollow Grid world server under active construction for
x86-64 Linux. The upstream `the-hollow-grid/docs/protocol.md` is the contract.

## Ownership

```text
player or bot
    |
    | WebSocket /ws, UTF-8 text
    v
libwebsockets
    |
    v
tiny C ABI shim
    |
    v
NASM engine
    |-- connection and login state
    |-- command parsing and dispatch
    |-- rooms, actors, items, and combat
    |-- prose plus @event framing
    |-- persistence seam
    `-- optional Grid Hub client seam
```

The C shim translates libwebsockets callbacks and buffers into a stable
assembly-facing ABI. It must not decide commands, thresholds, or LocalHub
store mutations, and it does not author the moral vocabulary, run the game
cadence, or gate keepers: the reckoning summary (deed labels, standing names,
`char.reckoning`), rest regen + combat cadence (asm `hg_heartbeat` /
`hg_combat_arm`; the shim keeps only the ~50ms beat and a thin `hg_wake_service`
that pokes the event loop), and the `ADMINS` keeper gate (`hg_is_admin`) all
live in NASM. `format.c` serializes `@event`/prose from values asm chose.
`grid_hub.c` owns RemoteHub libcurl/cJSON only; LocalHub memory and tide clamp
live in NASM (`asm/grid_local.asm`).

## Engine boundaries

- **Transport:** accept `/ws`, normalize one client message to one command, and
  emit CRLF-terminated lines.
- **Session:** serialize login, commands, ticks, and disconnect cleanup for one
  player.
- **World:** own the room graph, Relay Cut, mobs, items, moral affordances, and
  living-world state.
- **Events:** encode every canonical player-facing state change as one
  `@event <name> <json>` line beside prose.
- **Persistence:** separate federated character fields from world-local HP,
  inventory, room, and position.
- **Federation:** use a replaceable client boundary. If the hub fails, continue
  locally and reconcile later.

Transport, session, world data, event framing, persistence, and a Phase 3
federation seam exist. Multiplayer presence and the complete command surface
remain planned behind these boundaries.

## Federation seam

`include/hg_grid.h` exposes one API with two modes, selected at boot by
whether `GRID_HUB_URL` is set:

- **LocalHub** (default, no `GRID_HUB_URL`): in-memory store in
  `asm/grid_local.asm` (traces, echo, tide, rescued/fallen, casts, seed
  worlds). Always available. Asm owns mutations and tide clamp.
- **RemoteHub** (`GRID_HUB_URL` set): HTTP POST JSON-RPC over libcurl in
  `ffi/grid_hub.c`, `{"method":...,"params":[...]}` -> `{"ok":...,"result":...}`,
  2s connect + total timeout, optional `Authorization: Bearer <GRID_HUB_TOKEN>`.

Every `hg_grid_*` call is fail-open: a transport error, timeout, or
malformed response is swallowed and the caller falls back to local-only
prose (LocalHub asm state, or a plain "the Grid is unreachable" line). A hub
outage never blocks local play. `hg_grid_federation_tick`, called every
service-loop iteration from `hg_lws_run`, rate-limits best-effort
re-registration to roughly once every 10s and is a no-op in LocalHub mode.

C owns RemoteHub HTTP/JSON/libcurl plus thin fetch/parse (`hg_grid_list_worlds`,
`hg_grid_fetch_character`, `hg_grid_fetch_recent*`, `hg_grid_local_trace_at`),
and hub-backed prose/`@event` serialization in `format.c`. ASM owns LocalHub memory,
command dispatch, identity merge for whoami/travel/login, worlds reachability
tagging, listen/ping branch selection plus row collection, and federation
presentation rules (`asm/grid_policy.asm`). Asm never builds HTTP itself; C never
decides LocalHub store policy.

`/health/deep` reports `grid_hub` as non-critical: LocalHub always reports
`ok:true, latency_ms:0`; RemoteHub pings `tide()` and reports the measured
latency and whether that ping succeeded, but a failure there never flips the
top-level `ok`.

## Protocol invariants

- First input on a new connection is the character name.
- New characters receive race selection and `char.create`; known characters
  resume without choosing race again.
- `/health` is cheap liveness. `/health/deep` reports local world health as
  critical and Grid Hub health as non-critical.
- Prose may vary. Event names, JSON fields, and canonical identifiers may not.
- `room.info.exits` is complete. Missing exits and unknown commands return an
  explicit response.
- Contextual actions are exposed through `room.actions`; moral actions carry
  their required valence.

## Assembly discipline

- Use explicit ownership for all buffers and state blocks.
- Bound every copy, parse, and serialization operation.
- Keep callback entry points small and preserve the System V AMD64 ABI.
- Keep wire-format constants and event field order documented and testable.
- Avoid hidden global mutation across libwebsockets callbacks. Route mutation
  through a session or world owner.

## Conformance

Local unit and transport tests should cover malformed input, buffer limits,
login, movement, event JSON, and callback lifetime. The final external gate is
the upstream `smoke.mjs` suite pointed at `ws://127.0.0.1:8793/ws`.
