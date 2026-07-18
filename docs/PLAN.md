# Foundation plan

Basalt Relay is in the standalone world phase. The linux/amd64 image, health
endpoints, WebSocket login, race menu, atomic persistence, character resume,
canonical map, Relay Cut, and declared movement are verified. Complete
gameplay, conformance, federation, release, and deployment are not yet claimed.

## Phase 0: build and ABI foundation

- [x] Establish reproducible NASM and x86-64 Linux linking targets
- [x] Define and test the System V AMD64 boundary between NASM and the minimal C
      libwebsockets shim
- [x] Add bounded session/input/output buffers and callback lifetime smoke tests
- [x] Serve `/health`, `/health/deep`, and `/ws`
- [x] Implement UTF-8 text input and CRLF output
- [x] Complete login, named race selection, persistence-backed resume, and
      dynamic initial `@event` framing

## Phase 1: standalone world

- [x] Implement canonical room anchors and Basalt Relay's east-from-`roof`
      Relay Cut graft
- [x] Implement room views, actions, declared movement, and persistence
- [ ] Implement complete identity/status command output
- [x] Implement items, equipment, economy, combat, death, and ticks (partial:
      wield/remove, tunnel rat combat via heartbeat (single-tick resolve today),
      rest/stand/sleep, join/defend at market, ping/world; no multi-tick round
      spacing, flee, loot, poison, post-combat save, or full bestiary; a
      defensive `player_died` path records `recordFallen` and respawns to the
      nexus, but is unreachable at today's fixed damage numbers -- HP never
      actually reaches 0)
- [ ] Implement multiplayer communication and presence
- [ ] Implement the canonical moral arc, rescue, remembrance, and reckoning
- [ ] Keep all canonical player state synchronized with `@event`
- [ ] Pass local unit, parser, ABI, transport, and memory-safety checks

## Phase 2: conformance

- [ ] Run the upstream `smoke.mjs` suite against
      `ws://127.0.0.1:8793/ws`
- [ ] Record dated results with the exact upstream revision
- [ ] Resolve protocol mismatches without parsing or pinning prose
- [ ] Reach a green standalone run before claiming parity

## Phase 3: federation

- [x] Add a best-effort Grid Hub client behind a replaceable boundary
      (`include/hg_grid.h` + `ffi/grid_hub.c`): LocalHub (in-memory, always
      available, seeded with Saltreach/the Ninth Server/Dustfall traces) when
      `GRID_HUB_URL` is unset, RemoteHub (libcurl POST JSON `{method,params}`
      -> `{ok,result,error}`, 2s timeout, optional Bearer token) when it is
      set. C owns HTTP/JSON/libcurl transport and hub-backed prose/`@event`
      formatting; ASM owns command dispatch and when to call.
- [x] Keep local play available during hub failure and timeout: every
      `hg_grid_*` call is fail-open (errors swallowed, local echo/prose
      fallback), verified by a manual smoke run with an unreachable
      `GRID_HUB_URL` exercising `worlds`/`ping`/`whoami`/`listen`/`travel`
      without a crash or blocked session.
- [ ] Synchronize only canonical federated state -- `whoami` overlays a
      `loadCharacter` read in remote mode, but nothing calls `commitCharacter`
      yet, so character state never round-trips back to the hub.
- [x] Exercise registry (`register`/`hg_grid_register_self`, called on boot
      and rate-limited via `hg_grid_federation_tick`), travel (`travel`/`gate`
      list `listWorlds` destinations with reconnect URLs; no mid-session
      handoff), and rolls (`record`/`recordFallen` wired to rat kills and the
      -- currently unreachable at today's damage numbers -- player-death
      path). Tide, ledger, chat (`gridcast`/`castsSince`), and presence
      (`reportPresence`/`presence`) have full C client support
      (`hg_grid_tide`, `hg_grid_shift_tide`, `hg_grid_gridcast`,
      `hg_grid_casts_since`, `hg_grid_report_presence_player`,
      `hg_grid_presence`, `hg_grid_ledger_stats`, `hg_grid_prune_ledger`) but
      no ASM command surface yet -- next phase's work, not this one's.
- [ ] Run the federation smoke phase against a reachable second world --
      `tests/ws_federation.py` only exercises the LocalHub path (no
      `GRID_HUB_URL`); it has not been run against a live second
      hollow-grid-go hub or a live Dustfall.

## Phase 4: release

- [x] Add foundation container and protected-main CI
- [ ] Document deployment configuration and source-offer obligations
- [ ] Deploy only after health, smoke, restart, and persistence checks pass
- [ ] Add a live URL only after verifying the deployed service

## Evidence rule

Mark an item complete only when its code exists and its documented command has
run successfully. Record facts, revision identifiers, and test counts. Never
carry sibling-port status into this repository.
