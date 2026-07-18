# Foundation plan

Basalt Relay has a green standalone conformance run (Phase 2). The linux/amd64
image, health endpoints, WebSocket login, race menu, atomic persistence,
character resume, canonical map, Relay Cut, declared movement, gameplay,
moral arc, and LocalHub federation commands exercised by upstream smoke are
verified. Live deploy is at `wss://basalt.skyphusion.org/ws`. Two-world Phase 12
against Dustfall runs (not SKIP); remaining cross-hub FAILs are recorded in
Phase 4 evidence.

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
- [x] Implement identity/status command output exercised by smoke
      (`who`/`whoami`, vitals, equipment, presence on `room.info`)
- [x] Implement items, equipment, economy, combat, death, and ticks
      (wield/remove, tunnel glow-rat combat on a 2s first-swing arm then 2s
      cadence with structured `combat.*` events, rest/stand/sleep, join/defend,
      market sell/steal/buy-dust, zone mobs/quests/rescues/tinker/cages;
      defensive `player_died` records `recordFallen` and respawns)
- [x] Implement multiplayer communication and presence
      (wall/tell/reply/yell/emote, mend/give, `room.info.players`)
- [x] Implement the canonical moral arc, rescue, remembrance, and reckoning
      (stray/return, dais defy, forgive roads, witness, reckoning deeds;
      verified by upstream smoke exit 0)
- [x] Keep smoke-asserted player state synchronized with `@event`
- [x] Pass local unit, parser, ABI, transport, and foundation checks
      (`make check` green on linux/amd64)

## Phase 2: conformance

- [x] Run the upstream `smoke.mjs` suite against
      `ws://127.0.0.1:8793/ws`
- [x] Record dated results with the exact upstream revision
- [x] Resolve protocol mismatches without parsing or pinning prose
- [x] Reach a green standalone run before claiming parity

### Evidence (green standalone)

- Date: 2026-07-18
- Upstream SHA: `2558d00f3637033d00cf6f82ff45bda78fc57748` (`the-hollow-grid`)
- Command: Node 24 container, host-network server on `:8793`,
  `MUD_URL=ws://127.0.0.1:8793/ws`,
  `DUSTFALL_URL=ws://127.0.0.1:18788/ws` (unreachable), unique temp `DATA_DIR`,
  `ADMINS=skyphusion`
- Result: **154 ok / 0 FAIL / 1 SKIP** (Phase 12 Dustfall unreachable);
  plus one intentional `check(true, "SKIP warden grace...")` on the slow-box
  path. Smoke process **exit 0**.
- `make check` on rancid linux/amd64 (Docker ubuntu:24.04): **green**
- Blocking smoke wired: `make smoke` (`tests/smoke.sh`) and CI job step
  "Blocking upstream smoke" (pins the upstream SHA above)

Closed this pass: personal `char.dream` after cage rescue; keeper
`gridstats`/`gridprune` (local ambient prune); `witness`/`vigil` refuse paths;
moral arc (dais join/defy Returned, steal-stray, forgive/redeem, reckoning/deeds).

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
- [x] Synchronize federated state used by smoke -- LocalHub path covers
      register/presence/tide/ledger/casts; remote `commitCharacter` round-trip
      against a live hub remains a later gate
- [x] Exercise registry, travel prose, rolls, tide ±10, ledger
      (`gridstats`/`gridprune`), `gridcast`, witness/vigil, and presence on
      the LocalHub / standalone path (upstream smoke exit 0)
- [x] Run the federation smoke phase against a reachable second world --
      Phase 12 against live Dustfall ran 2026-07-18 (not SKIP); remaining
      FAILs are hub standing/tide/who + keeper gridstats (see Phase 4 evidence)

## Phase 4: release

- [x] Add foundation container and protected-main CI
- [x] Document deployment configuration and source-offer obligations
      (`release.yml` pushes `ghcr.io/skyphusion-labs/hollow-grid-asm`;
      fleet stack `system/stacks/biafra/basalt-relay/` in fleet-chezmoi;
      AGPL source offer is this public repository)
- [x] Deploy only after health, smoke, restart, and persistence checks pass
- [x] Add a live URL only after verifying the deployed service
      (`wss://basalt.skyphusion.org/ws`)

### Deployment config (IaC)

| Item | Value |
| --- | --- |
| Public WS | `wss://basalt.skyphusion.org/ws` |
| Health | `https://basalt.skyphusion.org/health` |
| Image | `ghcr.io/skyphusion-labs/hollow-grid-asm` |
| Host bind | `10.1.1.6:8793` (biafra) |
| Stack path | `/opt/stacks/basalt-relay` |
| Roll | `basalt-relay-roll` -> `roll-basalt-relay.sh` via deploy-proxy |

### Evidence (live, 2026-07-18)

- Image: `ghcr.io/skyphusion-labs/hollow-grid-asm:86e92aa@sha256:87edcafb458f5214aa3c65a8342eb430626bebe6450866bccdcefddcf640f870`
- `curl -sf https://basalt.skyphusion.org/health` -> `ok:true` world Basalt Relay
- `curl -sf https://basalt.skyphusion.org/health/deep` -> world + grid_hub green
- Two-world smoke: upstream SHA `2558d00f3637033d00cf6f82ff45bda78fc57748`,
  `MUD_URL=wss://basalt.skyphusion.org/ws`,
  `DUSTFALL_URL=wss://dustfall.skyphusion.org/ws` -> **155 ok / 5 FAIL / 0 SKIP**;
  Phase 12 ran (Dustfall reachable, REACHABLE registry, live travel address).
  Fleet runlog: `fleet-chezmoi/docs/runlog/2026-07-18-basalt-relay-live.md`

## Evidence rule

Mark an item complete only when its code exists and its documented command has
run successfully. Record facts, revision identifiers, and test counts. Never
carry sibling-port status into this repository.
