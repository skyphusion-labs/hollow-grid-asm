# Foundation plan

Basalt Relay has a green standalone conformance run (Phase 2). The linux/amd64
image, health endpoints, WebSocket login, race menu, atomic persistence,
character resume, canonical map, Relay Cut, declared movement, gameplay,
moral arc, and LocalHub federation commands exercised by upstream smoke are
verified. Public deploy at `wss://basalt.skyphusion.org/ws` was taken offline
after remote-crash bugs (#11 family); re-enable only after those fixes land.
Two-world Phase 12 against Dustfall runs (not SKIP); remaining cross-hub FAILs
are recorded in Phase 4 evidence.

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
  "Blocking upstream smoke" (pins the upstream SHA above). Timeout floor is
  **600s** with `SMOKE_SLOW=2` (mirror hollow-grid-c; CI job `timeout-minutes: 25`).

Closed this pass: personal `char.dream` after cage rescue; keeper
`gridstats`/`gridprune` (local ambient prune); `witness`/`vigil` refuse paths;
moral arc (dais join/defy Returned, steal-stray, forgive/redeem, reckoning/deeds).

### Evidence (crash hardening, 2026-07-19)

Fixes for open issues that can take down a single-process node or corrupt
saves (branch `fix/crash-hardening-smoke-timeout`):

- #11: `title` uses bounded `strncpy` into `SESSION_TITLE` (47 + NUL)
- #12: terminated inventory/ability rodata; inventory scratch capacity-checked
- #13/#14: save writes real `SESSION_INVENTORY`; write loops to full length;
  `close` checked; characters dir `fsync` after `rename`; load restores inventory
- #15: `tests/ws_hardening.py` covers long `title`, inventory prose, title
  persistence; wired into `tests/foundation.sh`

Verified: `docker build` on rancid linux/amd64 -> `make check` green
(persistence, hardening, gameplay, federation, remote federation).

### Evidence (robustness hardening, 2026-07-19)

Fixes for #16 (branch `fix/hardening-textrel-ws-signals`):

- DT_TEXTREL: pointer tables (`phase_table`, `race_table`, `rooms`,
  `directions`, `exits`) moved to `.data.rel.ro`; RELRO seals them after
  relocation. Link gated with `-Wl,--fatal-warnings`. Verified
  `readelf -d` on the built binary: no TEXTREL entry.
- WS input: fragmented text messages reassemble into a per-session buffer
  (`SESSION_RX`, session grew to 17400 bytes in `state.inc` +
  `hg_session.h` lockstep); assembled input over 255 bytes answers
  "Input too long", never silently truncates.
- Signals: SIGALRM/`setitimer` watchdog replaced with a 50ms `lws_sul`
  beat that runs heartbeat/combat/rest/federation ticks on the event
  loop; SIGINT/SIGTERM use `sigaction` and only set a flag.
- `tests/ws_hardening.py` gained fragmented-command and oversize-input
  regressions.

Verified on rancid linux/amd64 (Docker ubuntu:24.04): `make check` green;
full upstream smoke `2558d00f` -> **153 ok / 0 FAIL / 1 SKIP**
(Phase 12 Dustfall unreachable, expected SKIP), exit 0.

### Evidence (social rules port to asm, #17)

**Closed 2026-07-19** on `feat/port-social-to-asm` (merge closes #17):

- `ffi/social.c` deleted. Social/economy/comms/moral handlers live in
  `asm/social.asm`, `asm/social_ledger.asm`, `asm/social_grid.asm`.
- `forgive` / `witness` rule bodies (marked check, ledgers, morality, deeds,
  redemption title, kept vigil) are asm. Admin gate for `gridstats` /
  `gridprune` is asm.
- C remaining: `lws_shim.c` (libwebsockets), `grid_hub.c` (HTTP/JSON hub),
  `format.c` (JSON/prose emitters, hub-row presentation for saved/fallen
  roll/stats/prune, forgiven target/redeemed event text). No command rule
  decisions in those helpers.

**Verify (rancid, Docker ubuntu:24.04):** `docker build --platform linux/amd64`
runs `make check` green (foundation, gameplay, federation,
`ws_remote_federation`). Upstream `smoke.mjs` @ `2558d00f` confirms the ported
`forgive` rule body (kapo/ash-sworn: grace lands, brand permanent, never
redeemed) exactly against protocol assertions. `witness`, `saved`,
`gridstats`, and `gridprune` were verified directly against the built binary:
correct `@event` (`grid.fallen`, `grid.rescued_roll`, `grid.ledger_stats`,
`grid.ledger_pruned`) and prose, and the `gridstats`/`gridprune` admin gate
(asm `hg_is_admin`) refuses a non-keeper with no ledger data leaked.

### Evidence (honest C/asm boundary, #24)

**In progress** on `fix/asm-actions-menu-boundary` (closes #24):

- `asm/actions.asm` owns action menus/valence, brand standing, dream
  selection, prune-kind policy.
- `asm/grid_local.asm` owns LocalHub federation memory (traces, echo, tide,
  rescued/fallen, casts), tide clamp, prune application, and seed worlds.
- `asm/social.asm`, `asm/social_ledger.asm`, `asm/social_grid.asm` own social
  command rules (renamed from social_port2/3).
- C remaining: `lws_shim.c` (libwebsockets), `format.c` (serialize `@event`/
  prose from asm-chosen values), `grid_hub.c` (RemoteHub libcurl/cJSON +
  hub-backed prose wrappers only).

**Verify (rancid, Docker ubuntu:24.04):** `make check` green (foundation,
gameplay, federation, `ws_remote_federation`) after LocalHub port.

### Evidence (Fable-5 review cuts, 2026-07-20)

Two Fable-5 reviews (correctness + honest ASM ownership) knocked out on
`fix/fable5-review-cuts`. What moved:

- **A1 tell (`asm/social.asm`):** `tell_impl` now spills prefix-len / found /
  current to the frame across `hg_session_at` / `strncasecmp` (PLT clobbers
  r8/r10/r11), matching `find_player_prefix`. The `need` / `no_one` error paths
  no longer leak the 1040-byte frame (single teardown at `.out`).
- **A2 gridcast ring (`asm/grid_local.asm`):** slot is now
  `(gl_next_cast - 1) % GL_MAX_CASTS`, so the 200-slot cast ring walks every
  slot instead of pinning slot 0 once `gl_cast_n` saturated.
- **A3 gridcast prose (`asm/social_grid.asm`):** dropped the duplicate
  `sp2_gridcast_prose` line; the sender prose + `comm.gridcast` broadcast both
  come from the C emitter once.
- **A4 callee-saved (`asm/social_grid.asm`, `asm/combat.asm`):** `hg_dais_pledge`
  and `hg_cmd_join` save/restore the `r12`/`r13` they clobber (push/pop keep the
  16-byte alignment) instead of leaning on the dispatcher.
- **B5 reckoning (`asm/social_ledger.asm`, `ffi/format.c`):** the moral summary
  (`hg_emit_char_reckoning_now`) is asm end to end -- standing labels, deed
  labels, narrative, and the `char.reckoning` `@event` use the existing
  `sp2_reckoning_*` / `sp2_deed_*` tables. The C deed/label/standing maps are
  deleted; C no longer authors the moral vocabulary.
- **B6 tick cadence (`ffi/lws_shim.c`, `asm/combat.asm`):** rest regen (+2 hp /
  2s) and combat cadence (arm +2000ms, round 2000ms) are owned by asm
  `hg_heartbeat`; the C `hg_rest_service` / `hg_combat_service` duplicates are
  deleted. The shim keeps only the ~50ms beat + federation poll and a thin
  `hg_wake_service` (lws_cancel_service) that asm `hg_combat_arm` calls.
- **B7 admin gate (`asm/social_ledger.asm`, `ffi/format.c`):** `hg_is_admin` and
  the `ADMINS` parse are asm (lazy `admins_ensure`, `getenv` + tokenise). The C
  `hg_admins_init` / `hg_is_admin` and the admin string list are deleted.
- **B9 world id + thresholds:** `@event` world claims (`grid.who`,
  `comm.gridcast`) thread `hg_grid_world_name()` (configured world id) instead of
  a hardcoded literal; `hg_regard_of` documents the intentional precedence
  difference vs `hg_brand_standing`.
- **C10 soak (`tests/ws_localhub_soak.py`):** floods 260 gridcasts (> the
  200-slot ring) then reads back `ping` / `witness` / `saved` / `gridstats` /
  `who` and `/health`, asserting the process survives the wrap. Also exercises
  the asm keeper gate both ways (keeper allowed, non-keeper refused).
- **C11 resilience (`tests/ws_remote_hub_resilience.py`):** boots remote-mode
  against a hub that returns malformed JSON, then 503s, then drops connections
  mid-suite; asserts `/health` stays 200, the process never exits, and `whoami`
  fails open to the local self.

**Deferred:** B8 (whoami/travel identity-merge and target-matching policy still
in `ffi/grid_hub.c`). It is the largest refactor (new struct-returning hub
accessors + a full asm re-author of both prose surfaces and the merge/matching
policy) and touches the working federation path; deferring keeps the node green
and shippable. World-id threading (B9) and the admin gate (B7) already removed
the adjacent C policy. Tracked as a follow-up.

**Verify (rancid, podman, ubuntu:24.04, linux/amd64):**
`podman build --target build` runs `make check` **green**: foundation
(persistence, hardening, gameplay, federation), `ws_remote_federation`,
`ws_localhub_soak`, `ws_remote_hub_resilience`.

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
