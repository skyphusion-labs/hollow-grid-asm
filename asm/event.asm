default rel
%include "state.inc"

section .rodata

prose_fmt: db "%s", 13, 10, "%s", 13, 10, 0
room_fmt:
    db '@event room.info {"id":"%s","name":"%s","exits":%s,"mobs":%s,"items":[],"players":[]}', 13, 10, 0
affects_fmt:
    db '@event char.affects {"morality":%ld,"addiction":%ld,"faction":"%s","resisted":false,"race":"%s","ashsworn":%s}', 13, 10, 0
vitals_fmt:
    db '@event char.vitals {"hp":%ld,"maxHp":%ld,"level":%ld,"xp":%ld,"gold":%ld,"room":"%s","inCombat":false,"poisoned":false,"position":"%s"}', 13, 10, 0
vitals_combat_fmt:
    db '@event char.vitals {"hp":%ld,"maxHp":%ld,"level":%ld,"xp":%ld,"gold":%ld,"room":"%s","inCombat":true,"poisoned":false,"position":"%s"}', 13, 10, 0
actions_fmt:
    db '@event room.actions {"actions":%s}', 13, 10, 0
world_state:
    db '@event world.state {"tick":0,"phase":"day","weather":"clear"}', 13, 10
world_state_end:
world_state_len: equ world_state_end - world_state
json_true: db "true", 0
json_false: db "false", 0
equip_weapon_fmt:
    db '@event char.equipment {"weapon":"%s","head":null,"body":null,"hands":null,"feet":null}', 13, 10, 0
equip_shiv:
    db '@event char.equipment {"weapon":"shiv","head":null,"body":null,"hands":null,"feet":null}', 13, 10
equip_shiv_end:
equip_shiv_len: equ equip_shiv_end - equip_shiv
equip_empty:
    db '@event char.equipment {"weapon":null,"head":null,"body":null,"hands":null,"feet":null}', 13, 10
equip_empty_end:
equip_empty_len: equ equip_empty_end - equip_empty

inventory_text:
    db "You carry: shiv.", 13, 10
inventory_text_end:
inventory_text_len: equ inventory_text_end - inventory_text

ability_text:
    db "Requisition answers with 15 gold from an abandoned transfer.", 13, 10
ability_text_end:
ability_text_len: equ ability_text_end - ability_text

extern snprintf
extern strlen
extern strcasecmp
extern hg_session_queue
extern hg_room_id
extern hg_room_name
extern hg_room_desc
extern hg_room_exits
extern hg_room_actions
extern hg_room_live_mobs

section .text

global hg_emit_scene
global hg_emit_equipment
global hg_emit_inventory
global hg_emit_ability

queue_buffer:
    sub rsp, 8
    mov rdi, r15
    call strlen wrt ..plt
    mov rcx, rax
    mov rdi, r12
    mov rsi, r13
    mov rdx, r15
    call hg_session_queue
    add rsp, 8
    ret

hg_emit_scene:
    push r12
    push r13
    push r14
    push r15
    sub rsp, 2056
    mov r12, rdi
    mov r13, rsi
    mov r14, [r12 + SESSION_ROOM]
    lea r15, [rsp + 64]

    mov rdi, r14
    call hg_room_name
    mov rcx, rax
    mov rdi, r14
    call hg_room_desc
    mov r8, rax
    mov rdi, r15
    mov esi, 1984
    lea rdx, [rel prose_fmt]
    xor eax, eax
    call snprintf wrt ..plt
    call queue_buffer

    mov rdi, r14
    call hg_room_id
    mov rcx, rax
    mov rdi, r14
    call hg_room_name
    mov r8, rax
    mov rdi, r14
    call hg_room_exits
    mov r9, rax
    mov rdi, r14
    call hg_room_live_mobs
    mov [rsp], rax
    mov rdi, r15
    mov esi, 1984
    lea rdx, [rel room_fmt]
    xor eax, eax
    call snprintf wrt ..plt
    call queue_buffer

    mov rdi, r14
    call hg_room_id
    mov rcx, [r12 + SESSION_HP]
    mov r8, [r12 + SESSION_MAX_HP]
    mov r9, [r12 + SESSION_LEVEL]
    mov rdx, [r12 + SESSION_XP]
    mov [rsp], rdx
    mov rdx, [r12 + SESSION_GOLD]
    mov [rsp + 8], rdx
    mov [rsp + 16], rax
    lea rax, [r12 + SESSION_POSITION]
    mov [rsp + 24], rax
    lea rdx, [rel vitals_fmt]
    cmp qword [r12 + SESSION_IN_COMBAT], 0
    je .vitals_ready
    lea rdx, [rel vitals_combat_fmt]
.vitals_ready:
    mov rdi, r15
    mov esi, 1984
    xor eax, eax
    call snprintf wrt ..plt
    call queue_buffer

    mov rcx, [r12 + SESSION_MORALITY]
    mov r8, [r12 + SESSION_ADDICTION]
    lea r9, [r12 + SESSION_FACTION]
    lea rax, [r12 + SESSION_RACE]
    mov [rsp], rax
    lea rax, [rel json_false]
    cmp qword [r12 + SESSION_ASHSWORN], 0
    je .ashsworn_ready
    lea rax, [rel json_true]
.ashsworn_ready:
    mov [rsp + 8], rax
    mov rdi, r15
    mov esi, 1984
    lea rdx, [rel affects_fmt]
    xor eax, eax
    call snprintf wrt ..plt
    call queue_buffer

    mov rdi, r14
    call hg_room_actions
    mov rcx, rax
    mov rdi, r15
    mov esi, 1984
    lea rdx, [rel actions_fmt]
    xor eax, eax
    call snprintf wrt ..plt
    call queue_buffer

    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel world_state]
    mov ecx, world_state_len
    call hg_session_queue

    add rsp, 2056
    pop r15
    pop r14
    pop r13
    pop r12
    ret

hg_emit_equipment:
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    lea rdi, [r12 + SESSION_WEAPON]
    cmp byte [rdi], 0
    je .empty
    lea rdx, [rel equip_shiv]
    mov ecx, equip_shiv_len
    jmp .queue
.empty:
    lea rdx, [rel equip_empty]
    mov ecx, equip_empty_len
.queue:
    mov rdi, r12
    mov rsi, r13
    call hg_session_queue
    pop r13
    pop r12
    ret

hg_emit_inventory:
    lea rdx, [rel inventory_text]
    mov ecx, inventory_text_len
    jmp hg_session_queue

hg_emit_ability:
    push r12
    push r13
    sub rsp, 8
    mov r12, rdi
    mov r13, rsi
    add qword [r12 + SESSION_GOLD], 15
    lea rdx, [rel ability_text]
    mov ecx, ability_text_len
    call hg_session_queue
    mov rdi, r12
    mov rsi, r13
    call hg_emit_scene
    add rsp, 8
    pop r13
    pop r12
    ret
