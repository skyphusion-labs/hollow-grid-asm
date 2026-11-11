# CLAUDE.md

> ## HANDS-OFF -- Conrad's solo fun
>
> **No agent work in this repo without explicit task language from Conrad in the same
> turn.** Prior foreign-agent damage took Basalt offline after a stop order was ignored.
> Stop means stop. If you are not under an explicit task for this repo right now, leave.
> Protocol authority remains `the-hollow-grid/docs/protocol.md`; this banner is about
> *who may touch the tree*, not about where the wire contract lives.

Guidance for agents working in this repository (only when explicitly tasked).

## Scope

This is Basalt Relay, a Hollow Grid world-node port targeting x86-64 Linux with
NASM. The current phase is standalone (fleet offline). Do not claim playability, protocol
parity, smoke results, federation, deployment, or live status without verified
artifacts.

## Authority

1. `the-hollow-grid/docs/protocol.md` defines transport, events, health, and
   federation. **Protocol authority is always upstream.**
2. This repository defines Basalt Relay's implementation and world content.
3. `hollow-grid-c`, `hollow-grid-go`, and `hollow-grid-py` are sibling
   references. They do not override the protocol.

## Toolchain pin (NASM / Ubuntu)

NASM 3.x (Ubuntu 26.04) warns `reloc-rel-dword` and `reloc-abs-qword` on every section-crossing
reference, so `-Wall -Werror` failed (closed #43, #46; #68). There is no clean spelling in the
source (even `lea rax, [rel sym]` trips it), so the Makefile passes `-Wno-reloc-rel-dword
-Wno-reloc-abs-qword`; every other warning stays fatal and the linker still gates DT_TEXTREL via
`--fatal-warnings`. CI may track `ubuntu-latest`; the Dockerfile still builds on 24.04.

## Hard boundaries

- Assembly owns game logic, state, command dispatch, world content, the moral
  arc/economy/rescue systems, action menus and valence, dream selection,
  prune-kind policy, LocalHub federation memory, and tide clamp. Anything that
  can live in NASM does.
- C is four narrow files under `ffi/`: `lws_shim.c` (libwebsockets ABI), `format.c`
  (bounded `@event`/prose serialization from values asm already chose),
  `grid_hub.c` (RemoteHub libcurl/cJSON plus hub-backed prose wrappers), and
  `auth.c` (bcrypt passphrase hash and `ADMIN_TOKEN` compare; asm calls it and
  still owns the login flow). `Makefile` `C_SRC` is that list. C never
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

Binary is `./build/hollow-grid-asm` (`Makefile` `BIN`). Default listen port is `8793`.

```bash
make check   # --help, tests/foundation.sh, and the ws_*.py checks
make smoke   # tests/smoke.sh; ci.yml also runs upstream smoke.mjs on port 8793
```

Definition of done is the upstream `smoke.mjs` suite against the exact `@event` contract.

Keep documentation concise and reproducible. Update `docs/PLAN.md` with
evidence, not forecasts presented as completed work.

## Release / deploy

**GHCR publish is parked. There is no host deploy.** Merges to `main` run CI and
`release.yml` builds the image; they do not push it. The Hetzner fleet was
decommissioned 2026-09-24, and `release.yml` has no deploy step.
A `v*` tag pushes `ghcr.io/skyphusion-labs/hollow-grid-asm` (`:<sha>` and `:latest`)
only when repo variable `BASALT_AUTODEPLOY` is `true`. `release.yml` does not
assert that the tag commit is an ancestor of `origin/main`.
