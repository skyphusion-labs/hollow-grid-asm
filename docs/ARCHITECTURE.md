# Architecture

Basalt Relay is planned as a Hollow Grid world server for x86-64 Linux. The
upstream `the-hollow-grid/docs/protocol.md` is the contract.

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
assembly-facing ABI. It must not decide commands, mutate game rules, construct
event semantics, or own world content.

## Planned engine boundaries

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

These are design targets, not claims that modules exist.

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
