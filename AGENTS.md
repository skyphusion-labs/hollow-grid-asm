# hollow-grid-asm

This file is the guide for any coding agent and any contributor. Follow it.

## What this project is

Basalt Relay is a Hollow Grid world node for x86-64 Linux. NASM owns the game. A small C layer covers the library ABI. The public world runs in a Cloudflare container. Play at https://basalt.skyphusion.org/ or connect to `wss://basalt.skyphusion.org/ws`.

Do not claim playability, protocol parity, smoke results, federation, deployment, or a live host without a verified artifact. A plan line is not a result.

## Authority

1. `the-hollow-grid/docs/protocol.md` defines transport, events, health, and federation. Protocol authority stays upstream.
2. This repository defines Basalt Relay's implementation and world content.
3. `hollow-grid-c`, `hollow-grid-go`, and `hollow-grid-py` are sibling references. They do not override the protocol.

## Toolchain pin

NASM 3.x on Ubuntu 26.04 warns on `reloc-rel-dword`. It also warns on `reloc-abs-qword`. Those warnings fire on every section-crossing reference. `-Wall -Werror` then fails. See issues #43, #46, and #68.

The source has no clean spelling for that warning. Even `lea rax, [rel sym]` trips it. The Makefile passes `-Wno-reloc-rel-dword`. It also passes `-Wno-reloc-abs-qword`. Every other warning stays fatal. The linker still fails the build on `DT_TEXTREL` through `--fatal-warnings`.

CI may track `ubuntu-latest`. The Dockerfile still builds on Ubuntu 24.04.

## Hard boundaries

Assembly owns game logic, state, command dispatch, and world content. It owns the moral arc, the economy, rescue, action menus, valence, and dream selection. It owns prune-kind policy, LocalHub memory, and the tide clamp. If a rule can live in NASM, it lives in NASM.

C is four files under `ffi/`. `Makefile` `C_SRC` is that list.

- `ffi/lws_shim.c` adapts the libwebsockets ABI.
- `ffi/format.c` serializes `@event` lines and prose from values assembly already chose.
- `ffi/grid_hub.c` is the RemoteHub client (libcurl and cJSON) plus hub-backed prose wrappers.
- `ffi/auth.c` hashes a passphrase with bcrypt and compares `ADMIN_TOKEN`. Assembly calls it. Assembly still owns the login flow.

C never decides a command, a moral menu, a threshold, or a LocalHub store mutation.

The runtime target is x86-64 Linux. Assembly syntax is NASM. The default listen port is `8793`. `/ws` uses WebSocket UTF-8 text and CRLF lines. Emit canonical player state as `@event <name> <json>`.

Federation is optional and best-effort. A hub failure must not block play. An unknown command must answer clearly. An unavailable exit must answer clearly. Never answer with silence.

Never commit a plaintext secret. Keep `.env.example` free of live values.

Do not use an em dash (U+2014) or an en dash (U+2013) in any file. Use a comma, parentheses, or two hyphens (`--`).

## World contract

Basalt Relay is a custody node. Its question is what you carry forward when no one watches the handoff.

Relay Cut is the signature zone. The graft sits east of canonical `roof`. Keep the canonical room ids, command names, event names, and moral-arc ids that upstream conformance needs. Differ by place and voice. Do not drift the protocol.

## Verification

The binary is `./build/hollow-grid-asm` (`Makefile` `BIN`). The default listen port is `8793`.

```bash
make check   # --help, tests/foundation.sh, and the ws_*.py checks
make smoke   # tests/smoke.sh; ci.yml also runs upstream smoke.mjs on port 8793
```

Definition of done is upstream `smoke.mjs` against the `@event` contract. [.github/workflows/ci.yml](.github/workflows/ci.yml) runs `make check` and blocking upstream smoke.

Keep docs short and reproducible. Update [docs/PLAN.md](docs/PLAN.md) with evidence. Do not write a forecast as finished work.

## Docs

Write Simplified Technical English. Use short sentences. Put one idea in each sentence. Use the active present tense. Use plain words. Use the same word every time.

State the limit next to the capability. Do not turn a measured result into a promise. Do not claim a live world from a green image build.

Other docs: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), [docs/COMMANDS.md](docs/COMMANDS.md), [docs/WORLD.md](docs/WORLD.md), [README.md](README.md).

## Release

Cloudflare hosts the public world through `wrangler.jsonc`. The release workflow handles GHCR publishing separately.

A merge to `main` runs CI. [.github/workflows/release.yml](.github/workflows/release.yml) builds the image. It does not push the image on that merge.

A `v*` tag pushes `ghcr.io/skyphusion-labs/hollow-grid-asm` as `:<sha>` and `:latest` only when the repo variable `BASALT_AUTODEPLOY` is `true`. `release.yml` does not check that the tag commit is an ancestor of `origin/main`.

## Version

There is no manifest version. The git tag is the version of record. The CHANGELOG heading is the version of record. The tag form is `v*`.

A version moves only in a release pull request. Write the changelog in that same pull request. A feature pull request does not bump the version. A fix pull request does not bump the version. Put the tag on the merge commit of the release pull request.

Before a release pull request, look for a tag of the current version. A matching tag means the cycle is closed. The release pull request then bumps. No matching tag means a bump already landed outside a release pull request. Stop and read why.

## Safety

Do not put a secret in a tracked file. Do not put a secret in a log. Do not put a secret in an issue.
