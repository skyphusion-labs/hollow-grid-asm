default rel

section .rodata

global hg_default_world
global hg_banner
global hg_banner_len
global hg_race_menu
global hg_race_menu_len
global hg_invalid_name
global hg_invalid_name_len
global hg_invalid_race
global hg_invalid_race_len
global hg_unknown_command
global hg_unknown_command_len
global hg_help
global hg_help_len
global hg_goodbye
global hg_goodbye_len

hg_default_world: db "Basalt Relay", 0

hg_banner:
    db 27, "[38;5;240m"
    db "B A S A L T   R E L A Y"
    db 27, "[0m", 13, 10
    db "A custody node on the dead network.", 13, 10
    db "By what name are you known, wanderer?", 13, 10
hg_banner_end:
hg_banner_len: dq hg_banner_end - hg_banner

hg_race_menu:
    db "Choose what the Relay carried here:", 13, 10
    db "  1) Human", 13, 10
    db "  2) Elf", 13, 10
    db "  3) Revenant", 13, 10
    db "  4) Ghoul", 13, 10
    db "  5) Chromed", 13, 10
    db "  6) Dustkin", 13, 10
    db "  7) Vatborn", 13, 10
    db '@event char.create {"races":["Human","Elf","Revenant","Ghoul","Chromed","Dustkin","Vatborn"],"prompt":"race"}', 13, 10
hg_race_menu_end:
hg_race_menu_len: dq hg_race_menu_end - hg_race_menu

hg_invalid_name:
    db "Names are 2 to 32 letters, numbers, hyphens, or underscores.", 13, 10
hg_invalid_name_end:
hg_invalid_name_len: dq hg_invalid_name_end - hg_invalid_name

hg_invalid_race:
    db "Choose a race by number from 1 to 7.", 13, 10
hg_invalid_race_end:
hg_invalid_race_len: dq hg_invalid_race_end - hg_invalid_race

hg_unknown_command:
    db "The Relay has no instruction by that name. Type help.", 13, 10
hg_unknown_command_end:
hg_unknown_command_len: dq hg_unknown_command_end - hg_unknown_command

hg_help:
    db "Commands: look, exits, north/south/east/west/up/down, go <dir>, inventory, equipment, wield, remove, attack, consider, rest, stand, sleep, join, defend, ping, world, ability, help, quit", 13, 10
hg_help_end:
hg_help_len: dq hg_help_end - hg_help

hg_goodbye:
    db "The Relay records the handoff. Connection closed.", 13, 10
hg_goodbye_end:
hg_goodbye_len: dq hg_goodbye_end - hg_goodbye

