default rel
%include "state.inc"

%define ROOM_RECORD_SIZE 48

section .rodata

empty_mobs: db "[]", 0
empty_actions: db "[]", 0
rat_mobs: db '[{"id":"rat","name":"a glow-rat"}]', 0
leech_mobs: db '[{"id":"leech","name":"a data-leech"}]', 0
raider_mobs: db '[{"id":"raider","name":"a wastes raider"}]', 0
trooper_mobs: db '[{"id":"trooper","name":"a Cinder Front trooper"}]', 0
ashmonger_mobs: db '[{"id":"ashmonger","name":"the Ashmonger"}]', 0
custodian_mobs: db '[{"id":"custodian","name":"the Custodian"}]', 0

actions_nexus: db '[{"verb":"down","label":"descend into the service tunnels","kind":"move"},{"verb":"east","label":"enter the workshop","kind":"move"},{"verb":"north","label":"walk to the market","kind":"move"},{"verb":"west","label":"enter the tavern","kind":"move"}]', 0
actions_tunnels: db '[{"verb":"attack rat","label":"attack the glow-rat","kind":"fight"},{"verb":"down","label":"descend toward the sump","kind":"move"},{"verb":"up","label":"return to the nexus","kind":"move"}]', 0
actions_market: db '[{"verb":"defend","label":"stand with the people the Front would erase","kind":"moral","valence":"virtuous"},{"verb":"join","label":"take the Front coin and help sort the living","kind":"moral","valence":"grave"},{"verb":"sell","label":"sell salvage for gold","kind":"economy"},{"verb":"steal","label":"steal from the stalls","kind":"economy","valence":"corrupt"}]', 0
actions_tavern: db '[{"verb":"talk","label":"talk to whoever shares your room","kind":"social"},{"verb":"buy dust","label":"buy dust: 10 gold a packet (using it heals, but addicts and corrupts)","kind":"moral","valence":"corrupt"}]', 0
actions_lock: db '[{"verb":"defend","label":"open the custody line and move people to safety","kind":"moral","valence":"virtuous"},{"verb":"join","label":"take the Front manifest and work the line","kind":"moral","valence":"corrupt"}]', 0
actions_repeater: db '[{"verb":"witness","label":"preserve the handoff record without alteration","kind":"moral","valence":"virtuous"}]', 0

%macro ROOM_STRINGS 5
%1_id: db %2, 0
%1_name: db %3, 0
%1_desc: db %4, 0
%1_exits: db %5, 0
%endmacro

ROOM_STRINGS nexus, "nexus", "Basalt Nexus", "Black columns hold transfer marks whose senders are gone. Routes lead to a market, workshop, tavern, and the service tunnels.", '["down","east","north","west"]'
ROOM_STRINGS tavern, "tavern", "The Unsealed Cup", "A low bar built from relay housings. People come here to forget what they were trusted to carry.", '["east"]'
ROOM_STRINGS market, "market", "The Transfer Market", "Salvage and sealed cases hang from wire loops. A Cinder Front recruiter offers coin for help sorting the living.", '["north","south"]'
ROOM_STRINGS holding_pit, "holding_pit", "The Holding Pit", "A sunken cell beneath a dead loading rail. Names remain where guards failed to paint fast enough.", '["south"]'
ROOM_STRINGS workshop, "workshop", "The Relay Workshop", "Hand tools and opened cabinets cover every bench. A ladder climbs to the roof.", '["up","west"]'
ROOM_STRINGS roof, "roof", "The Basalt Roof", "Cut stone plates face a grey sky. The wastes open north and Relay Cut begins east.", '["down","east","north"]'
ROOM_STRINGS tunnels, "tunnels", "Service Tunnels", "Cable hooks line damp concrete. A luminous rodent watches beneath a broken custody seal.", '["down","up"]'
ROOM_STRINGS sump, "sump", "The Black Sump", "Runoff gathers around old conduit. A shaft continues into submerged machinery.", '["down","up"]'
ROOM_STRINGS floodgate, "floodgate", "The Floodgate", "A sealed bulkhead groans under pressure. Cold storage waits beyond.", '["north","up"]'
ROOM_STRINGS coldrow, "coldrow", "Cold Storage Row", "Dead drives sweat condensation while something pale moves between cabinets.", '["east","north","south"]'
ROOM_STRINGS cooling, "cooling", "Cooling Gallery", "Fans turn without power, pushing stale air through split ducts.", '["west"]'
ROOM_STRINGS fiber, "fiber", "Fiber Trench", "Cut bundles cross a trench where every route once had a named owner.", '["down","south"]'
ROOM_STRINGS corelab, "corelab", "The Core Laboratory", "A custodian keeps watch over a shard that still answers the Grid.", '["up","west"]'
ROOM_STRINGS archive, "archive", "The Dead Archive", "Shelves of unreadable media preserve custody records without their keepers.", '["east"]'
ROOM_STRINGS dunes, "dunes", "The Black Powder Flats", "Dark dust combs itself into ridges. Scorch Road runs east and the Front checkpoint stands north.", '["east","north","south"]'
ROOM_STRINGS scorch_road, "scorch_road", "Scorch Road", "Heat lifts from broken tar. A waystation lies east and a transit hub opens south.", '["east","south","west"]'
ROOM_STRINGS waystation, "waystation", "Refugee Waystation", "Tarps and water drums shelter people weighing which side each newcomer serves.", '["west"]'
ROOM_STRINGS transit_hub, "transit_hub", "The Old Transit Hub", "Collapsed platforms hold distress banners that nobody came to collect.", '["north"]'
ROOM_STRINGS checkpoint, "checkpoint", "The Ash Checkpoint", "The Cinder Front first wall divides the road and the people on it.", '["north","south"]'
ROOM_STRINGS gate, "gate", "The Stronghold Gate", "Welded scrap forms a narrow throat into the Front yard.", '["north","south"]'
ROOM_STRINGS muster, "muster", "The Muster Yard", "Troopers drill beneath ash banners. Cages stand west and the war room waits north.", '["north","south","west"]'
ROOM_STRINGS cells, "cells", "The Holding Cells", "Iron cages are bolted into concrete. Some are empty. Some are waiting.", '["east"]'
ROOM_STRINGS warroom, "warroom", "The War Room", "Maps cover a steel table. The Ashmonger dais opens above.", '["south","up"]'
ROOM_STRINGS dais, "dais", "The Ashmonger Dais", "A platform of welded scrap and ash overlooks the stronghold.", '["down"]'
ROOM_STRINGS relay_cut, "relay-cut", "Relay Cut", "A narrow service cut where sealed cases changed hands after supervision ended.", '["east","north","west"]'
ROOM_STRINGS handoff_bay, "handoff-bay", "Handoff Bay", "A dead transfer platform offers no witness except the next person who needs it.", '["south"]'
ROOM_STRINGS custody_lock, "custody-lock", "Custody Lock", "The Front records people and cargo on the same manifest.", '["west"]'
ROOM_STRINGS east_repeater, "east-repeater", "East Repeater", "A damaged relay preserves what was forwarded, not what a keeper later claimed.", '["west"]'

rooms:
    dq nexus_id, nexus_name, nexus_desc, nexus_exits, empty_mobs, actions_nexus
    dq tavern_id, tavern_name, tavern_desc, tavern_exits, empty_mobs, actions_tavern
    dq market_id, market_name, market_desc, market_exits, empty_mobs, actions_market
    dq holding_pit_id, holding_pit_name, holding_pit_desc, holding_pit_exits, empty_mobs, empty_actions
    dq workshop_id, workshop_name, workshop_desc, workshop_exits, empty_mobs, empty_actions
    dq roof_id, roof_name, roof_desc, roof_exits, empty_mobs, empty_actions
    dq tunnels_id, tunnels_name, tunnels_desc, tunnels_exits, rat_mobs, actions_tunnels
    dq sump_id, sump_name, sump_desc, sump_exits, empty_mobs, empty_actions
    dq floodgate_id, floodgate_name, floodgate_desc, floodgate_exits, empty_mobs, empty_actions
    dq coldrow_id, coldrow_name, coldrow_desc, coldrow_exits, leech_mobs, empty_actions
    dq cooling_id, cooling_name, cooling_desc, cooling_exits, empty_mobs, empty_actions
    dq fiber_id, fiber_name, fiber_desc, fiber_exits, empty_mobs, empty_actions
    dq corelab_id, corelab_name, corelab_desc, corelab_exits, custodian_mobs, empty_actions
    dq archive_id, archive_name, archive_desc, archive_exits, empty_mobs, empty_actions
    dq dunes_id, dunes_name, dunes_desc, dunes_exits, empty_mobs, empty_actions
    dq scorch_road_id, scorch_road_name, scorch_road_desc, scorch_road_exits, raider_mobs, empty_actions
    dq waystation_id, waystation_name, waystation_desc, waystation_exits, empty_mobs, empty_actions
    dq transit_hub_id, transit_hub_name, transit_hub_desc, transit_hub_exits, empty_mobs, empty_actions
    dq checkpoint_id, checkpoint_name, checkpoint_desc, checkpoint_exits, empty_mobs, empty_actions
    dq gate_id, gate_name, gate_desc, gate_exits, empty_mobs, empty_actions
    dq muster_id, muster_name, muster_desc, muster_exits, trooper_mobs, empty_actions
    dq cells_id, cells_name, cells_desc, cells_exits, empty_mobs, empty_actions
    dq warroom_id, warroom_name, warroom_desc, warroom_exits, empty_mobs, empty_actions
    dq dais_id, dais_name, dais_desc, dais_exits, ashmonger_mobs, empty_actions
    dq relay_cut_id, relay_cut_name, relay_cut_desc, relay_cut_exits, empty_mobs, empty_actions
    dq handoff_bay_id, handoff_bay_name, handoff_bay_desc, handoff_bay_exits, empty_mobs, empty_actions
    dq custody_lock_id, custody_lock_name, custody_lock_desc, custody_lock_exits, empty_mobs, actions_lock
    dq east_repeater_id, east_repeater_name, east_repeater_desc, east_repeater_exits, empty_mobs, actions_repeater

dir_north: db "north", 0
dir_south: db "south", 0
dir_east: db "east", 0
dir_west: db "west", 0
dir_up: db "up", 0
dir_down: db "down", 0
directions: dq dir_north, dir_south, dir_east, dir_west, dir_up, dir_down

%macro EXIT 3
    dq %1, %2, %3
%endmacro
exits:
    EXIT ROOM_NEXUS, dir_north, ROOM_MARKET
    EXIT ROOM_NEXUS, dir_east, ROOM_WORKSHOP
    EXIT ROOM_NEXUS, dir_down, ROOM_TUNNELS
    EXIT ROOM_NEXUS, dir_west, ROOM_TAVERN
    EXIT ROOM_TAVERN, dir_east, ROOM_NEXUS
    EXIT ROOM_MARKET, dir_south, ROOM_NEXUS
    EXIT ROOM_MARKET, dir_north, ROOM_HOLDING_PIT
    EXIT ROOM_HOLDING_PIT, dir_south, ROOM_MARKET
    EXIT ROOM_WORKSHOP, dir_west, ROOM_NEXUS
    EXIT ROOM_WORKSHOP, dir_up, ROOM_ROOF
    EXIT ROOM_ROOF, dir_down, ROOM_WORKSHOP
    EXIT ROOM_ROOF, dir_north, ROOM_DUNES
    EXIT ROOM_ROOF, dir_east, ROOM_RELAY_CUT
    EXIT ROOM_TUNNELS, dir_up, ROOM_NEXUS
    EXIT ROOM_TUNNELS, dir_down, ROOM_SUMP
    EXIT ROOM_SUMP, dir_up, ROOM_TUNNELS
    EXIT ROOM_SUMP, dir_down, ROOM_FLOODGATE
    EXIT ROOM_FLOODGATE, dir_up, ROOM_SUMP
    EXIT ROOM_FLOODGATE, dir_north, ROOM_COLDROW
    EXIT ROOM_COLDROW, dir_south, ROOM_FLOODGATE
    EXIT ROOM_COLDROW, dir_east, ROOM_COOLING
    EXIT ROOM_COLDROW, dir_north, ROOM_FIBER
    EXIT ROOM_COOLING, dir_west, ROOM_COLDROW
    EXIT ROOM_FIBER, dir_south, ROOM_COLDROW
    EXIT ROOM_FIBER, dir_down, ROOM_CORELAB
    EXIT ROOM_CORELAB, dir_up, ROOM_FIBER
    EXIT ROOM_CORELAB, dir_west, ROOM_ARCHIVE
    EXIT ROOM_ARCHIVE, dir_east, ROOM_CORELAB
    EXIT ROOM_DUNES, dir_south, ROOM_ROOF
    EXIT ROOM_DUNES, dir_east, ROOM_SCORCH_ROAD
    EXIT ROOM_DUNES, dir_north, ROOM_CHECKPOINT
    EXIT ROOM_SCORCH_ROAD, dir_west, ROOM_DUNES
    EXIT ROOM_SCORCH_ROAD, dir_east, ROOM_WAYSTATION
    EXIT ROOM_SCORCH_ROAD, dir_south, ROOM_TRANSIT_HUB
    EXIT ROOM_WAYSTATION, dir_west, ROOM_SCORCH_ROAD
    EXIT ROOM_TRANSIT_HUB, dir_north, ROOM_SCORCH_ROAD
    EXIT ROOM_CHECKPOINT, dir_south, ROOM_DUNES
    EXIT ROOM_CHECKPOINT, dir_north, ROOM_GATE
    EXIT ROOM_GATE, dir_south, ROOM_CHECKPOINT
    EXIT ROOM_GATE, dir_north, ROOM_MUSTER
    EXIT ROOM_MUSTER, dir_south, ROOM_GATE
    EXIT ROOM_MUSTER, dir_west, ROOM_CELLS
    EXIT ROOM_MUSTER, dir_north, ROOM_WARROOM
    EXIT ROOM_CELLS, dir_east, ROOM_MUSTER
    EXIT ROOM_WARROOM, dir_south, ROOM_MUSTER
    EXIT ROOM_WARROOM, dir_up, ROOM_DAIS
    EXIT ROOM_DAIS, dir_down, ROOM_WARROOM
    EXIT ROOM_RELAY_CUT, dir_west, ROOM_ROOF
    EXIT ROOM_RELAY_CUT, dir_north, ROOM_HANDOFF_BAY
    EXIT ROOM_RELAY_CUT, dir_east, ROOM_CUSTODY_LOCK
    EXIT ROOM_HANDOFF_BAY, dir_south, ROOM_RELAY_CUT
    EXIT ROOM_CUSTODY_LOCK, dir_west, ROOM_RELAY_CUT
    EXIT ROOM_CUSTODY_LOCK, dir_east, ROOM_EAST_REPEATER
    EXIT ROOM_EAST_REPEATER, dir_west, ROOM_CUSTODY_LOCK
    dq -1, 0, 0

section .text

extern strcasecmp

global hg_room_id
global hg_room_name
global hg_room_desc
global hg_room_exits
global hg_room_mobs
global hg_room_actions
global hg_room_move

%macro FIELD_FUNCTION 2
%1:
    cmp rdi, ROOM_COUNT
    jae %%bad
    imul rax, rdi, ROOM_RECORD_SIZE
    lea rdx, [rel rooms]
    mov rax, [rdx + rax + %2]
    ret
%%bad:
    xor eax, eax
    ret
%endmacro

FIELD_FUNCTION hg_room_id, 0
FIELD_FUNCTION hg_room_name, 8
FIELD_FUNCTION hg_room_desc, 16
FIELD_FUNCTION hg_room_exits, 24
FIELD_FUNCTION hg_room_mobs, 32
FIELD_FUNCTION hg_room_actions, 40

; int64 hg_room_move(room_index, direction)
; destination >= 0, -2 for a direction without an exit, -1 for unknown input.
hg_room_move:
    push r12
    push r13
    push r14
    push rbx
    sub rsp, 8
    mov r12, rdi
    mov r13, rsi
    lea r14, [rel exits]
.exit_loop:
    cmp qword [r14], -1
    je .known_check
    cmp [r14], r12
    jne .next_exit
    mov rdi, r13
    mov rsi, [r14 + 8]
    call strcasecmp wrt ..plt
    test eax, eax
    jz .found
.next_exit:
    add r14, 24
    jmp .exit_loop
.found:
    mov rax, [r14 + 16]
    jmp .done

.known_check:
    lea r14, [rel directions]
    xor ebx, ebx
.direction_loop:
    cmp ebx, 6
    jae .unknown
    mov rdi, r13
    mov rsi, [r14 + rbx * 8]
    call strcasecmp wrt ..plt
    test eax, eax
    jz .known
    inc ebx
    jmp .direction_loop
.known:
    mov rax, -2
    jmp .done
.unknown:
    mov rax, -1
.done:
    add rsp, 8
    pop rbx
    pop r14
    pop r13
    pop r12
    ret

