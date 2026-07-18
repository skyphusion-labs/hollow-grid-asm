default rel
%include "state.inc"

section .rodata

prose_fmt: db "%s", 13, 10, "%s", 13, 10, 0
json_true: db "true", 0
json_false: db "false", 0
empty_players: db "[]", 0

inventory_empty:
    db "You carry nothing.", 13, 10
inventory_empty_end:
inventory_empty_len: equ inventory_empty_end - inventory_empty

inventory_prefix: db "You carry: ", 0
inventory_suffix: db ".", 13, 10

ability_human:
    db "You flash credentials nobody bothers to check. The registry still provides for its own. (+15 gold)", 13, 10
ability_human_end:
ability_human_len: equ ability_human_end - ability_human

ability_name_req: db "Requisition", 0

extern snprintf
extern strlen
extern strcpy
extern strcat
extern strcasecmp
extern hg_session_queue
extern hg_room_id
extern hg_room_name
extern hg_room_desc
extern hg_room_exits
extern hg_room_actions
extern hg_room_live_mobs
extern hg_fmt_vitals
extern hg_fmt_affects
extern hg_fmt_equipment
extern hg_fmt_room_info
extern hg_players_json
extern hg_actions_json_for
extern hg_fmt_room_actions
extern hg_fmt_world_state
extern hg_fmt_ability_recharging
extern hg_emit_dream_now
extern hg_now_ms
extern hg_world_tick_value
extern hg_emit_scene_now

section .bss
inv_scratch: resb 512

section .text

global hg_emit_scene
global hg_emit_equipment
global hg_emit_inventory
global hg_emit_ability
global hg_emit_vitals_dyn
global hg_emit_affects_dyn

; r12=session, r13=wsi, r15=buffer
queue_buffer:
    push rbx
    mov rdi, r15
    call strlen wrt ..plt
    mov rcx, rax
    mov rdi, r12
    mov rsi, r13
    mov rdx, r15
    call hg_session_queue
    pop rbx
    ret

hg_emit_vitals_dyn:
    push r12
    push r13
    push r15
    sub rsp, 512
    mov r12, rdi
    mov r13, rsi
    mov [r12 + SESSION_WSI], r13
    lea r15, [rsp]
    mov rdi, [r12 + SESSION_ROOM]
    call hg_room_id
    mov rdi, r15
    mov esi, 500
    mov rdx, r12
    mov rcx, rax
    call hg_fmt_vitals wrt ..plt
    call queue_buffer
    add rsp, 512
    pop r15
    pop r13
    pop r12
    ret

hg_emit_affects_dyn:
    push r12
    push r13
    push r15
    sub rsp, 512
    mov r12, rdi
    mov r13, rsi
    mov [r12 + SESSION_WSI], r13
    lea r15, [rsp]
    mov rdi, r15
    mov esi, 500
    mov rdx, r12
    call hg_fmt_affects wrt ..plt
    call queue_buffer
    add rsp, 512
    pop r15
    pop r13
    pop r12
    ret

hg_emit_scene:
    ; rdi=session, rsi=wsi -- stash wsi then emit from C
    mov [rdi + SESSION_WSI], rsi
    jmp hg_emit_scene_now wrt ..plt

phase_day_fallback: db "day", 0

hg_emit_equipment:
    push r12
    push r13
    push r15
    sub rsp, 512
    mov r12, rdi
    mov r13, rsi
    mov [r12 + SESSION_WSI], r13
    lea r15, [rsp]
    mov rdi, r15
    mov esi, 500
    mov rdx, r12
    call hg_fmt_equipment wrt ..plt
    call queue_buffer
    add rsp, 512
    pop r15
    pop r13
    pop r12
    ret

hg_emit_inventory:
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    mov r12, rdi
    mov r13, rsi
    mov [r12 + SESSION_WSI], r13
    mov rax, [r12 + SESSION_INV_COUNT]
    test rax, rax
    jz .empty
    lea rdi, [rel inv_scratch]
    lea rsi, [rel inventory_prefix]
    call strcpy wrt ..plt
    xor r14, r14
.loop:
    cmp r14, [r12 + SESSION_INV_COUNT]
    jae .close
    test r14, r14
    jz .item
    lea rdi, [rel inv_scratch]
    ; append ", "
    mov rsi, rdi
    call strlen wrt ..plt
    lea rdi, [rel inv_scratch]
    add rdi, rax
    mov word [rdi], 0x202c
    mov byte [rdi + 2], 0
.item:
    mov rax, r14
    imul rax, SESSION_INV_SLOT_SIZE
    lea rsi, [r12 + SESSION_INVENTORY]
    add rsi, rax
    lea rdi, [rel inv_scratch]
    call strcat wrt ..plt
    inc r14
    jmp .loop
.close:
    lea rdi, [rel inv_scratch]
    lea rsi, [rel inventory_suffix]
    call strcat wrt ..plt
    lea rdi, [rel inv_scratch]
    call strlen wrt ..plt
    mov rcx, rax
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel inv_scratch]
    call hg_session_queue
    jmp .done
.empty:
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel inventory_empty]
    mov ecx, inventory_empty_len
    call hg_session_queue
.done:
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    ret

hg_emit_ability:
    push r12
    push r13
    push r14
    push r15
    sub rsp, 520              ; keep 16-byte align before C calls (4 pushes leave rsp 8-mod-16)
    mov r12, rdi
    mov r13, rsi
    mov [r12 + SESSION_WSI], r13
    lea r15, [rsp + 8]

    call hg_now_ms wrt ..plt
    mov r14, rax
    mov rax, [r12 + SESSION_TRAIT_READY]
    test rax, rax
    jz .fire
    cmp r14, rax
    jae .fire
    ; still recharging
    mov rcx, rax
    sub rcx, r14
    add rcx, 999
    mov rax, rcx
    xor edx, edx
    mov ecx, 1000
    div rcx
    ; eax = seconds remaining (at least 1)
    test eax, eax
    jnz .secs
    mov eax, 1
.secs:
    mov rdi, r15
    mov esi, 500
    lea rdx, [rel ability_name_req]
    mov ecx, eax
    call hg_fmt_ability_recharging wrt ..plt
    call queue_buffer
    jmp .done

.fire:
    ; human Requisition: +15 gold, 180s cooldown
    add qword [r12 + SESSION_GOLD], 15
    mov rax, r14
    add rax, 180000
    mov [r12 + SESSION_TRAIT_READY], rax
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel ability_human]
    mov ecx, ability_human_len
    call hg_session_queue
    mov rdi, [r12 + SESSION_ROOM]
    call hg_room_id
    mov rdi, r15
    mov esi, 500
    mov rdx, r12
    mov rcx, rax
    call hg_fmt_vitals wrt ..plt
    call queue_buffer
.done:
    add rsp, 520
    pop r15
    pop r14
    pop r13
    pop r12
    ret
