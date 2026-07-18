default rel
%include "state.inc"

section .rodata

nexus_scene:
    db "Basalt Nexus", 13, 10
    db "Black columns hold transfer marks whose senders are gone. A market lies north, a workshop east, a bar west, and service tunnels descend.", 13, 10
    db '@event room.info {"id":"nexus","name":"Basalt Nexus","exits":["down","east","north","west"],"mobs":[],"items":[],"players":[]}', 13, 10
    db '@event char.vitals {"hp":30,"maxHp":30,"level":1,"xp":0,"gold":20,"room":"nexus","inCombat":false,"poisoned":false,"position":"standing"}', 13, 10
    db '@event char.affects {"morality":0,"addiction":0,"faction":"none","resisted":false,"race":"human","ashsworn":false}', 13, 10
    db '@event room.actions {"actions":[{"verb":"down","label":"descend into the service tunnels","kind":"move"},{"verb":"east","label":"enter the workshop","kind":"move"},{"verb":"north","label":"walk to the market","kind":"move"},{"verb":"west","label":"enter the tavern","kind":"move"}]}', 13, 10
    db '@event world.state {"tick":0,"phase":"day","weather":"clear"}', 13, 10
nexus_scene_end:
nexus_scene_len: equ nexus_scene_end - nexus_scene

tunnels_scene:
    db "Service Tunnels", 13, 10
    db "Cable hooks line the damp concrete. A luminous rodent watches from beneath a broken custody seal.", 13, 10
    db '@event room.info {"id":"tunnels","name":"Service Tunnels","exits":["down","up"],"mobs":[{"id":"rat","name":"luminous rat"}],"items":[],"players":[]}', 13, 10
    db '@event char.vitals {"hp":30,"maxHp":30,"level":1,"xp":0,"gold":20,"room":"tunnels","inCombat":false,"poisoned":false,"position":"standing"}', 13, 10
    db '@event char.affects {"morality":0,"addiction":0,"faction":"none","resisted":false,"race":"human","ashsworn":false}', 13, 10
    db '@event room.actions {"actions":[{"verb":"attack rat","label":"attack the luminous rat","kind":"fight"},{"verb":"down","label":"descend toward the sump","kind":"move"},{"verb":"up","label":"return to the nexus","kind":"move"}]}', 13, 10
    db '@event world.state {"tick":0,"phase":"day","weather":"clear"}', 13, 10
tunnels_scene_end:
tunnels_scene_len: equ tunnels_scene_end - tunnels_scene

equipment_event:
    db '@event char.equipment {"weapon":null,"head":null,"body":null,"hands":null,"feet":null}', 13, 10
equipment_event_end:
equipment_event_len: equ equipment_event_end - equipment_event

inventory_text:
    db "You carry: shiv.", 13, 10
inventory_text_end:
inventory_text_len: equ inventory_text_end - inventory_text

ability_text:
    db "Requisition answers with 15 gold from an abandoned transfer.", 13, 10
    db '@event char.vitals {"hp":30,"maxHp":30,"level":1,"xp":0,"gold":35,"room":"nexus","inCombat":false,"poisoned":false,"position":"standing"}', 13, 10
ability_text_end:
ability_text_len: equ ability_text_end - ability_text

section .text

extern hg_session_queue

global hg_emit_scene
global hg_emit_equipment
global hg_emit_inventory
global hg_emit_ability

; rdi=session, rsi=wsi
hg_emit_scene:
    cmp qword [rdi + SESSION_ROOM], ROOM_TUNNELS
    je .tunnels
    lea rdx, [rel nexus_scene]
    mov ecx, nexus_scene_len
    jmp hg_session_queue
.tunnels:
    lea rdx, [rel tunnels_scene]
    mov ecx, tunnels_scene_len
    jmp hg_session_queue

hg_emit_equipment:
    lea rdx, [rel equipment_event]
    mov ecx, equipment_event_len
    jmp hg_session_queue

hg_emit_inventory:
    lea rdx, [rel inventory_text]
    mov ecx, inventory_text_len
    jmp hg_session_queue

hg_emit_ability:
    lea rdx, [rel ability_text]
    mov ecx, ability_text_len
    jmp hg_session_queue

