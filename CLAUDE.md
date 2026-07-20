# CLAUDE.md

Guidance for agents working in this repository.

## Scope

This is Basalt Relay, a Hollow Grid world-node port targeting x86-64 Linux with
NASM. The current phase is foundation. Do not claim playability, protocol
parity, smoke results, federation, deployment, or live status without verified
artifacts.

## Authority

1. `the-hollow-grid/docs/protocol.md` defines transport, events, health, and
   federation.
2. This repository defines Basalt Relay's implementation and world content.
3. `hollow-grid-c`, `hollow-grid-go`, and `hollow-grid-py` are sibling
   references. They do not override the protocol.

## Hard boundaries

- Assembly owns game logic, state, command dispatch, world content, the moral
  arc/economy/rescue systems, action menus and valence, dream selection,
  prune-kind policy, LocalHub federation memory, and tide clamp. Anything that
  can live in NASM does.
- C is three narrow files only: `lws_shim.c` (libwebsockets ABI), `format.c`
  (bounded `@event`/prose serialization from values asm already chose), and
  `grid_hub.c` (RemoteHub libcurl/cJSON plus hub-backed prose wrappers). C never
  decides a command, moral menu, threshold, or LocalHub store mutation.
- Runtime target is x86-64 Linux. Assembly syntax is NASM.
- Default listen port is `8793`.
- `/ws` uses WebSocket UTF-8 text and CRLF output lines.
- Canonical player state must be emitted as `@event <name> <json>`.
- Federation is optional and best-effort. Hub failure must not block play.
- An unknown command or unavailable exit must answer clearly, never silently.
- Never commit plaintext secrets. Keep `.env.example` value-safe.
- No em dash or en dash characters in any file.

## World contract

Basalt Relay is a custody node. Its question is: "what do you carry forward
when no one is watching the handoff?"

Relay Cut is the signature zone, grafted east from canonical `roof`. Preserve
canonical room, command, event, and moral-arc identifiers needed by upstream
conformance. Differentiate through place and voice, not protocol drift.

## Verification

Do not invent working commands. Add build and test instructions only when the
corresponding targets exist and have been run. The eventual definition of done
is the upstream `smoke.mjs` suite against the exact `@event` contract.

Keep documentation concise and reproducible. Update `docs/PLAN.md` with
evidence, not forecasts presented as completed work.
