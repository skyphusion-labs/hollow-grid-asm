# hollow-grid-asm

**Basalt Relay** is a Hollow Grid custody-node world server for x86-64 Linux,
written primarily in NASM assembly. A tiny C shim adapts the libwebsockets ABI.
Assembly owns game rules, state transitions, protocol framing, and world content.

Live deployment: `wss://basalt.skyphusion.org/ws` (fleet stack on biafra via
`cloudflared-fleet`). GHCR image: `ghcr.io/skyphusion-labs/hollow-grid-asm`.

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
                                             +-> game rules and world state
                                             +-> commands and event payloads
                                             +-> persistence and federation seams
```

The C layer must remain an ABI adapter. Moving game logic into C breaks the
port's defining boundary.

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

CI (`ci.yml`) runs `make check` plus blocking upstream smoke. `release.yml` on
`main` pushes GHCR (`:<sha>` + `:latest`) and dispatches a fleet
`basalt-relay-roll`. Fleet IaC and roll runbook live in `fleet-chezmoi`
(`system/stacks/biafra/basalt-relay/`, `RUNBOOK-basalt-relay-roll.md`).

## License

AGPL-3.0-only. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
