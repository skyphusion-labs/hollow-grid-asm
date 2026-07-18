default rel
%include "state.inc"

section .rodata

cmd_look:      db "look", 0
cmd_l:         db "l", 0
cmd_look_sp:   db "look ", 0
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
cmd_wield:     db "wield", 0
cmd_wield_sp:  db "wield ", 0
cmd_remove:    db "remove", 0
cmd_unwield:   db "unwield", 0
cmd_attack:    db "attack", 0
cmd_attack_sp: db "attack ", 0
cmd_kill:      db "kill", 0
cmd_kill_sp:   db "kill ", 0
cmd_k:         db "k", 0
cmd_k_sp:      db "k ", 0
cmd_consider:  db "consider", 0
cmd_consider_sp: db "consider ", 0
cmd_con:       db "con", 0
cmd_con_sp:    db "con ", 0
cmd_exits:     db "exits", 0
cmd_exit:      db "exit", 0
cmd_sleep:     db "sleep", 0
cmd_stand:     db "stand", 0
cmd_wake:      db "wake", 0
cmd_rest:      db "rest", 0
cmd_join:      db "join", 0
cmd_defend:    db "defend", 0
cmd_oppose:    db "oppose", 0
cmd_ping:      db "ping", 0
cmd_ping_sp:   db "ping ", 0
cmd_world:     db "world", 0
cmd_weather:   db "weather", 0
cmd_time:      db "time", 0
cmd_listen:    db "listen", 0
cmd_tune:      db "tune", 0
cmd_whoami:    db "whoami", 0
cmd_identity:  db "identity", 0
cmd_worlds:    db "worlds", 0
cmd_travel:    db "travel", 0
cmd_travel_sp: db "travel ", 0
cmd_gate:      db "gate", 0

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
extern hg_cmd_wield
extern hg_cmd_remove
extern hg_cmd_attack
extern hg_cmd_consider
extern hg_cmd_look_mob
extern hg_cmd_exits
extern hg_cmd_sleep
extern hg_cmd_stand
extern hg_cmd_rest
extern hg_cmd_join
extern hg_cmd_defend
extern hg_cmd_ping
extern hg_cmd_world
extern hg_cmd_listen
extern hg_cmd_whoami
extern hg_cmd_worlds
extern hg_cmd_travel

section .text

global hg_world_command

eq:
    sub rsp, 8
    call strcasecmp wrt ..plt
    add rsp, 8
    test eax, eax
    sete al
    movzx eax, al
    ret

; rdi=command, rsi=prefix, rdx=prefix_len -> eax=1 if prefix matches
prefix:
    call strncasecmp wrt ..plt
    test eax, eax
    sete al
    movzx eax, al
    ret

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

    mov rdi, r14
    lea rsi, [rel cmd_look_sp]
    mov edx, 5
    call prefix
    test eax, eax
    jnz .look_mob

    mov rdi, r14
    lea rsi, [rel cmd_go_prefix]
    mov edx, 3
    call prefix
    test eax, eax
    jnz .direct_move
    mov rdx, r14
    jmp .try_move
.direct_move:
    lea rdx, [r14 + 3]
    jmp .try_move
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
    lea rsi, [rel cmd_wield]
    call eq
    test eax, eax
    jnz .wield_empty
    mov rdi, r14
    lea rsi, [rel cmd_wield_sp]
    mov edx, 6
    call prefix
    test eax, eax
    jnz .wield_arg

    mov rdi, r14
    lea rsi, [rel cmd_remove]
    call eq
    test eax, eax
    jnz .remove
    mov rdi, r14
    lea rsi, [rel cmd_unwield]
    call eq
    test eax, eax
    jnz .remove

    mov rdi, r14
    lea rsi, [rel cmd_attack]
    call eq
    test eax, eax
    jnz .attack_empty
    mov rdi, r14
    lea rsi, [rel cmd_attack_sp]
    mov edx, 7
    call prefix
    test eax, eax
    jnz .attack_arg
    mov rdi, r14
    lea rsi, [rel cmd_kill]
    call eq
    test eax, eax
    jnz .attack_empty
    mov rdi, r14
    lea rsi, [rel cmd_kill_sp]
    mov edx, 5
    call prefix
    test eax, eax
    jnz .kill_arg
    mov rdi, r14
    lea rsi, [rel cmd_k]
    call eq
    test eax, eax
    jnz .attack_empty
    mov rdi, r14
    lea rsi, [rel cmd_k_sp]
    mov edx, 2
    call prefix
    test eax, eax
    jnz .k_arg

    mov rdi, r14
    lea rsi, [rel cmd_consider]
    call eq
    test eax, eax
    jnz .consider_empty
    mov rdi, r14
    lea rsi, [rel cmd_consider_sp]
    mov edx, 9
    call prefix
    test eax, eax
    jnz .consider_arg
    mov rdi, r14
    lea rsi, [rel cmd_con]
    call eq
    test eax, eax
    jnz .consider_empty
    mov rdi, r14
    lea rsi, [rel cmd_con_sp]
    mov edx, 4
    call prefix
    test eax, eax
    jnz .con_arg

    mov rdi, r14
    lea rsi, [rel cmd_exits]
    call eq
    test eax, eax
    jnz .exits
    mov rdi, r14
    lea rsi, [rel cmd_exit]
    call eq
    test eax, eax
    jnz .exits

    mov rdi, r14
    lea rsi, [rel cmd_sleep]
    call eq
    test eax, eax
    jnz .sleep
    mov rdi, r14
    lea rsi, [rel cmd_stand]
    call eq
    test eax, eax
    jnz .stand
    mov rdi, r14
    lea rsi, [rel cmd_wake]
    call eq
    test eax, eax
    jnz .stand
    mov rdi, r14
    lea rsi, [rel cmd_rest]
    call eq
    test eax, eax
    jnz .rest
    mov rdi, r14
    lea rsi, [rel cmd_join]
    call eq
    test eax, eax
    jnz .join
    mov rdi, r14
    lea rsi, [rel cmd_defend]
    call eq
    test eax, eax
    jnz .defend
    mov rdi, r14
    lea rsi, [rel cmd_oppose]
    call eq
    test eax, eax
    jnz .defend

    mov rdi, r14
    lea rsi, [rel cmd_ping]
    call eq
    test eax, eax
    jnz .ping_empty
    mov rdi, r14
    lea rsi, [rel cmd_ping_sp]
    mov edx, 5
    call prefix
    test eax, eax
    jnz .ping_arg

    mov rdi, r14
    lea rsi, [rel cmd_world]
    call eq
    test eax, eax
    jnz .world
    mov rdi, r14
    lea rsi, [rel cmd_weather]
    call eq
    test eax, eax
    jnz .world
    mov rdi, r14
    lea rsi, [rel cmd_time]
    call eq
    test eax, eax
    jnz .world

    mov rdi, r14
    lea rsi, [rel cmd_listen]
    call eq
    test eax, eax
    jnz .listen
    mov rdi, r14
    lea rsi, [rel cmd_tune]
    call eq
    test eax, eax
    jnz .listen

    mov rdi, r14
    lea rsi, [rel cmd_whoami]
    call eq
    test eax, eax
    jnz .whoami
    mov rdi, r14
    lea rsi, [rel cmd_identity]
    call eq
    test eax, eax
    jnz .whoami

    mov rdi, r14
    lea rsi, [rel cmd_worlds]
    call eq
    test eax, eax
    jnz .worlds

    mov rdi, r14
    lea rsi, [rel cmd_travel]
    call eq
    test eax, eax
    jnz .travel_empty
    mov rdi, r14
    lea rsi, [rel cmd_travel_sp]
    mov edx, 7
    call prefix
    test eax, eax
    jnz .travel_arg
    mov rdi, r14
    lea rsi, [rel cmd_gate]
    call eq
    test eax, eax
    jnz .travel_empty

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

.wield_empty:
    mov rdi, r12
    mov rsi, r13
    xor edx, edx
    call hg_cmd_wield
    jmp .done
.wield_arg:
    lea rdx, [r14 + 6]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_wield
    jmp .done
.remove:
    mov rdi, r12
    mov rsi, r13
    xor edx, edx
    call hg_cmd_remove
    jmp .done
.attack_empty:
    mov rdi, r12
    mov rsi, r13
    xor edx, edx
    call hg_cmd_attack
    jmp .done
.attack_arg:
    lea rdx, [r14 + 7]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_attack
    jmp .done
.kill_arg:
    lea rdx, [r14 + 5]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_attack
    jmp .done
.k_arg:
    lea rdx, [r14 + 2]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_attack
    jmp .done
.consider_empty:
    mov rdi, r12
    mov rsi, r13
    xor edx, edx
    call hg_cmd_consider
    jmp .done
.consider_arg:
    lea rdx, [r14 + 9]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_consider
    jmp .done
.con_arg:
    lea rdx, [r14 + 4]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_consider
    jmp .done
.look_mob:
    lea rdx, [r14 + 5]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_look_mob
    jmp .done
.exits:
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_exits
    jmp .done
.sleep:
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_sleep
    jmp .done
.stand:
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_stand
    jmp .done
.rest:
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_rest
    jmp .done
.join:
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_join
    jmp .done
.defend:
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_defend
    jmp .done
.ping_empty:
    mov rdi, r12
    mov rsi, r13
    xor edx, edx
    call hg_cmd_ping
    jmp .done
.ping_arg:
    lea rdx, [r14 + 5]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_ping
    jmp .done
.world:
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_world
    jmp .done
.listen:
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_listen
    jmp .done
.whoami:
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_whoami
    jmp .done
.worlds:
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_worlds
    jmp .done
.travel_empty:
    mov rdi, r12
    mov rsi, r13
    xor edx, edx
    call hg_cmd_travel
    jmp .done
.travel_arg:
    lea rdx, [r14 + 7]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_travel
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
