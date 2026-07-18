default rel
%include "state.inc"

section .rodata

cmd_look:      db "look", 0
cmd_l:         db "l", 0
cmd_down:      db "down", 0
cmd_d:         db "d", 0
cmd_up:        db "up", 0
cmd_u:         db "u", 0
cmd_help:      db "help", 0
cmd_question:  db "?", 0
cmd_inventory: db "inventory", 0
cmd_inv:       db "inv", 0
cmd_i:         db "i", 0
cmd_equipment: db "equipment", 0
cmd_eq:        db "eq", 0
cmd_ability:   db "ability", 0
cmd_trait:     db "trait", 0
cmd_quit:      db "quit", 0
cmd_go_prefix: db "go ", 0

cant_move:
    db "The declared ways do not lead there.", 13, 10
cant_move_end:
cant_move_len: equ cant_move_end - cant_move

extern hg_help
extern hg_help_len
extern hg_goodbye
extern hg_goodbye_len
extern hg_unknown_command
extern hg_unknown_command_len
extern hg_session_queue
extern hg_emit_scene
extern hg_emit_inventory
extern hg_emit_equipment
extern hg_emit_ability
extern strcasecmp
extern strncasecmp
extern hg_room_move

section .text

global hg_world_command

; int eq(command, literal)
; rdi=command, rsi=literal
eq:
    sub rsp, 8
    call strcasecmp wrt ..plt
    add rsp, 8
    test eax, eax
    sete al
    movzx eax, al
    ret

; rdi=session, rsi=wsi, rdx=zero-terminated command
hg_world_command:
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx

    mov rdi, r14
    lea rsi, [rel cmd_look]
    call eq
    test eax, eax
    jnz .scene
    mov rdi, r14
    lea rsi, [rel cmd_l]
    call eq
    test eax, eax
    jnz .scene

    ; Full declared-exit movement, including "go <direction>".
    mov rdi, r14
    lea rsi, [rel cmd_go_prefix]
    mov edx, 3
    call strncasecmp wrt ..plt
    test eax, eax
    jnz .direct_move
    lea rdx, [r14 + 3]
    jmp .try_move
.direct_move:
    mov rdx, r14
.try_move:
    mov rdi, [r12 + SESSION_ROOM]
    mov rsi, rdx
    call hg_room_move
    cmp rax, -2
    je .cant_move
    cmp rax, -1
    je .not_movement
    mov [r12 + SESSION_ROOM], rax
    jmp .scene
.not_movement:

    mov rdi, r14
    lea rsi, [rel cmd_down]
    call eq
    test eax, eax
    jnz .down
    mov rdi, r14
    lea rsi, [rel cmd_d]
    call eq
    test eax, eax
    jnz .down

    mov rdi, r14
    lea rsi, [rel cmd_up]
    call eq
    test eax, eax
    jnz .up
    mov rdi, r14
    lea rsi, [rel cmd_u]
    call eq
    test eax, eax
    jnz .up

    mov rdi, r14
    lea rsi, [rel cmd_help]
    call eq
    test eax, eax
    jnz .help
    mov rdi, r14
    lea rsi, [rel cmd_question]
    call eq
    test eax, eax
    jnz .help

    mov rdi, r14
    lea rsi, [rel cmd_inventory]
    call eq
    test eax, eax
    jnz .inventory
    mov rdi, r14
    lea rsi, [rel cmd_inv]
    call eq
    test eax, eax
    jnz .inventory
    mov rdi, r14
    lea rsi, [rel cmd_i]
    call eq
    test eax, eax
    jnz .inventory

    mov rdi, r14
    lea rsi, [rel cmd_equipment]
    call eq
    test eax, eax
    jnz .equipment
    mov rdi, r14
    lea rsi, [rel cmd_eq]
    call eq
    test eax, eax
    jnz .equipment

    mov rdi, r14
    lea rsi, [rel cmd_ability]
    call eq
    test eax, eax
    jnz .ability
    mov rdi, r14
    lea rsi, [rel cmd_trait]
    call eq
    test eax, eax
    jnz .ability

    mov rdi, r14
    lea rsi, [rel cmd_quit]
    call eq
    test eax, eax
    jnz .quit

    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel hg_unknown_command]
    mov rcx, [rel hg_unknown_command_len]
    call hg_session_queue
    jmp .done

.down:
    cmp qword [r12 + SESSION_ROOM], ROOM_NEXUS
    jne .cant_move
    mov qword [r12 + SESSION_ROOM], ROOM_TUNNELS
    jmp .scene

.up:
    cmp qword [r12 + SESSION_ROOM], ROOM_TUNNELS
    jne .cant_move
    mov qword [r12 + SESSION_ROOM], ROOM_NEXUS
    jmp .scene

.cant_move:
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel cant_move]
    mov ecx, cant_move_len
    call hg_session_queue
    jmp .done

.scene:
    mov rdi, r12
    mov rsi, r13
    call hg_emit_scene
    jmp .done

.help:
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel hg_help]
    mov rcx, [rel hg_help_len]
    call hg_session_queue
    jmp .done

.inventory:
    mov rdi, r12
    mov rsi, r13
    call hg_emit_inventory
    jmp .done

.equipment:
    mov rdi, r12
    mov rsi, r13
    call hg_emit_equipment
    jmp .done

.ability:
    mov rdi, r12
    mov rsi, r13
    call hg_emit_ability
    jmp .done

.quit:
    mov qword [r12 + SESSION_CLOSE], 1
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel hg_goodbye]
    mov rcx, [rel hg_goodbye_len]
    call hg_session_queue

.done:
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    xor eax, eax
    ret

