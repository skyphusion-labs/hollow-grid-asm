# hollow-grid-asm

**Basalt Relay** is a Hollow Grid custody-node world server for x86-64 Linux,
written primarily in NASM assembly. A tiny C shim adapts the libwebsockets ABI.
Assembly owns game rules, state transitions, protocol framing, and world content.

Public world is offline pending finished-product review (fleet stack parked on
biafra). GHCR image: `ghcr.io/skyphusion-labs/hollow-grid-asm` (push gated by
`BASALT_AUTODEPLOY` / version tag until re-enable).

## Contract

The authority is
[`the-hollow-grid/docs/protocol.md`](https://github.com/skyphusion-labs/the-hollow-grid/blob/main/docs/protocol.md).
Sibling ports in C, Go, and Python are implementation references, not protocol
authorities.

The service provides:

- WebSocket text transport at `/ws`
- UTF-8 output with CRLF line endings
- `@event <name> <json>` as machine-readable player state
- `GET /health` and `GET /health/deep`
- standalone play when no Grid Hub is configured
- best-effort federation that never blocks local play

Default listen port: `8793`.

## Runtime boundary

```text
client -> libwebsockets -> tiny C ABI shim -> NASM engine
                                             |
                                             +-> game rules, state transitions,
                                             |   and command dispatch
                                             +-> world content and the moral
                                             |   arc/economy/rescue systems
                                             +-> event payloads and
                                                 persistence/federation seams
```

NASM decides every rule: when a command applies, what it mutates, and what
prose or event it produces. C is three narrow files: `lws_shim.c` (the
libwebsockets ABI shim), `format.c` (bounded JSON/prose formatting and
hub-row presentation), and `grid_hub.c` (federation HTTP/JSON transport). C
may format `@event` JSON from state or hub rows that asm already decided; it
never decides a command or mutates game rules.

## Repository guide

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md): ownership and data flow
- [`docs/COMMANDS.md`](docs/COMMANDS.md): required command surface
- [`docs/WORLD.md`](docs/WORLD.md): Basalt Relay identity and Relay Cut
- [`docs/PLAN.md`](docs/PLAN.md): phased implementation plan
- [`.env.example`](.env.example): runtime configuration

## Build and run

The runtime target is linux/amd64. On an amd64 Ubuntu 24.04 host:

```sh
sudo apt-get install nasm pkg-config libcjson-dev libwebsockets-dev \
  libcurl4-openssl-dev libssl-dev
make check
./build/hollow-grid-asm --addr 127.0.0.1:8793
```

On another architecture, build the container:

```sh
docker build --platform linux/amd64 -t hollow-grid-asm .
docker run --rm -p 8793:8793 hollow-grid-asm
```

CI (`ci.yml`) runs `make check` plus blocking upstream smoke. `release.yml`
builds the image on every push/PR; GHCR push and the fleet roll dispatch fire
only on a pushed version tag (`v*`), never on a merge to `main` (#22), and
only when repo variable `BASALT_AUTODEPLOY` is `true` (#20). Basalt Relay
stays offline until both a tagged release and Mackaye's code review land.
Fleet IaC and roll runbook live in `fleet-chezmoi`
(`system/stacks/biafra/basalt-relay/`, `RUNBOOK-basalt-relay-roll.md`).

## License

AGPL-3.0-only. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
