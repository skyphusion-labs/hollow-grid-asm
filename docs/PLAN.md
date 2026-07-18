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
      spacing, flee, loot, poison, post-combat save, or full bestiary)
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

- [ ] Add a best-effort Grid Hub client behind a replaceable boundary
- [ ] Keep local play available during hub failure and timeout
- [ ] Synchronize only canonical federated state
- [ ] Exercise registry, travel, tide, ledger, chat, presence, and rolls
- [ ] Run the federation smoke phase against a reachable second world

## Phase 4: release

- [x] Add foundation container and protected-main CI
- [ ] Document deployment configuration and source-offer obligations
- [ ] Deploy only after health, smoke, restart, and persistence checks pass
- [ ] Add a live URL only after verifying the deployed service

## Evidence rule

Mark an item complete only when its code exists and its documented command has
run successfully. Record facts, revision identifiers, and test counts. Never
carry sibling-port status into this repository.
