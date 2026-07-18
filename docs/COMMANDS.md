# Command contract

This file records the required command families for the planned port. It does
not claim that any command is implemented. Exact aliases and behavior must
follow upstream dispatch and `docs/protocol.md`; sibling ports are useful
cross-checks.

## Foundation order

1. Login: name, race selection, resume
2. Observation: `look`, `exits`, `sense`, `help`
3. Movement: `north`, `south`, `east`, `west`, `up`, `down`, `recall`
4. Identity: `whoami`, `affects`, `inventory`, `equipment`, `status`
5. Lifecycle: `rest`, `stand`, `sleep`, `quit`
6. Combat: `consider`, `attack`, `flee`, race ability
7. Items: `get`, `drop`, `use`, `examine`, `wield`, `remove`, `give`
8. Economy: `list`, `buy`, `sell`, `steal`
9. Social: `say`, `tell`, `reply`, `yell`, `emote`, `look <player>`
10. Moral arc: `join`, `defend`, `defy`, `rescue`, `forgive`, `reckoning`
11. Aid and memory: `mend`, `cache`, `gather`, `treat`, `witness`, `inscribe`
12. Grid: `listen`, `ping`, `worlds`, `travel`, `war`, `gridcast`, `who`
13. Keeper: `wall`, `gridstats`, `gridprune`

## Structured output

Commands must expose canonical results through the upstream events, including:

- room views: `room.info`, `room.actions`, `char.vitals`, `char.affects`
- creation and identity: `char.create`, `char.identity`, `char.equipment`
- combat: `combat.start`, `combat.round`, `combat.end`, `char.died`
- communication: `comm.tell`, `comm.yell`, `comm.gridcast`
- world and Grid: `world.state`, `world.war`, `grid.echo`,
  `grid.transmission`, `grid.worlds`, `grid.who`, `grid.travel`
- moral record: `char.reckoning`, `grid.rescued`, `grid.remembrance`

The protocol event vocabulary is authoritative. This list is only an
implementation checklist.

## Parser rules

- Accept one command line per WebSocket message.
- Trim leading and trailing whitespace and line endings.
- Match command words and aliases case-insensitively unless upstream requires
  otherwise.
- Preserve user text after commands such as `say`, `tell`, and `inscribe`.
- Bound command length before copying or tokenizing.
- Return explicit help for an unknown command, missing argument, missing
  target, or unavailable exit.
- Never infer canonical state by parsing prose in tests or clients.
