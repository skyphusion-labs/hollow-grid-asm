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
cmd_remove_sp: db "remove ", 0
cmd_unwield:   db "unwield", 0
cmd_unwield_sp: db "unwield ", 0
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
cmd_title:     db "title", 0
cmd_title_sp:  db "title ", 0
cmd_who:       db "who", 0
cmd_free:      db "free", 0
cmd_rescue:    db "rescue", 0
cmd_release:   db "release", 0
cmd_unlock:    db "unlock", 0
cmd_liberate:  db "liberate", 0
cmd_unchain:   db "unchain", 0
cmd_unshackle: db "unshackle", 0
cmd_untie:     db "untie", 0
cmd_recall:    db "recall", 0
cmd_home:      db "home", 0
cmd_affects:   db "affects", 0
cmd_inscribe:  db "inscribe", 0
cmd_inscribe_sp: db "inscribe ", 0
cmd_sell:       db "sell", 0
cmd_sell_sp:    db "sell ", 0
cmd_steal:      db "steal", 0
cmd_sense:      db "sense", 0
cmd_actions:    db "actions", 0
cmd_forgive:    db "forgive", 0
cmd_forgive_sp: db "forgive ", 0
cmd_absolve:    db "absolve", 0
cmd_absolve_sp: db "absolve ", 0
cmd_pardon:     db "pardon", 0
cmd_pardon_sp:  db "pardon ", 0
cmd_talk:       db "talk", 0
cmd_ask:        db "ask", 0
cmd_buy:        db "buy", 0
cmd_buy_sp:     db "buy ", 0
cmd_wall:       db "wall", 0
cmd_wall_sp:    db "wall ", 0
cmd_tell:       db "tell", 0
cmd_tell_sp:    db "tell ", 0
cmd_reply:      db "reply", 0
cmd_reply_sp:   db "reply ", 0
cmd_yell:       db "yell", 0
cmd_yell_sp:    db "yell ", 0
cmd_emote:      db "emote", 0
cmd_emote_sp:   db "emote ", 0
cmd_mend:       db "mend", 0
cmd_mend_sp:    db "mend ", 0
cmd_give:       db "give", 0
cmd_give_sp:    db "give ", 0
cmd_cache:      db "cache", 0
cmd_cache_sp:   db "cache ", 0
cmd_gather:     db "gather", 0
cmd_treat:      db "treat", 0
cmd_gridcast:   db "gridcast", 0
cmd_gridcast_sp: db "gridcast ", 0
cmd_gc:         db "gc", 0
cmd_gc_sp:      db "gc ", 0
cmd_list:       db "list", 0
cmd_war:        db "war", 0
cmd_shelter:    db "shelter", 0
cmd_saved:      db "saved", 0
cmd_defy:       db "defy", 0
cmd_defect:     db "defect", 0
cmd_witness:    db "witness", 0
cmd_witness_sp: db "witness ", 0
cmd_remember:   db "remember", 0
cmd_remember_sp: db "remember ", 0
cmd_mourn:      db "mourn", 0
cmd_mourn_sp:   db "mourn ", 0
cmd_reckoning:  db "reckoning", 0
cmd_conscience: db "conscience", 0
cmd_record:     db "record", 0
cmd_gridstats:  db "gridstats", 0
cmd_gridprune:  db "gridprune", 0

cant_move:
    db "The declared ways do not lead there.", 13, 10
cant_move_end:
cant_move_len: equ cant_move_end - cant_move
position_standing: db "standing", 0

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
extern hg_cmd_affects
extern hg_cmd_inscribe
extern hg_cmd_sell
extern hg_cmd_steal
extern hg_cmd_sense
extern hg_cmd_forgive
extern hg_cmd_look_player
extern hg_cmd_talk
extern hg_cmd_buy
extern hg_cmd_wall
extern hg_cmd_tell
extern hg_cmd_reply
extern hg_cmd_yell
extern hg_cmd_emote
extern hg_cmd_mend
extern hg_cmd_give
extern hg_cmd_cache
extern hg_cmd_gather
extern hg_cmd_treat
extern hg_cmd_gridcast
extern hg_cmd_list
extern hg_cmd_war
extern hg_cmd_shelter
extern hg_cmd_saved
extern hg_cmd_join
extern hg_cmd_defend
extern hg_cmd_defy
extern hg_cmd_witness
extern hg_cmd_reckoning
extern hg_cmd_gridstats
extern hg_cmd_gridprune
extern hg_cmd_ping
extern hg_cmd_world
extern hg_cmd_listen
extern hg_cmd_whoami
extern hg_cmd_worlds
extern hg_cmd_travel
extern hg_cmd_title
extern hg_cmd_who
extern hg_cmd_free
extern strcpy

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
    jnz .look_arg

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
    lea rsi, [rel cmd_remove_sp]
    mov edx, 7
    call prefix
    test eax, eax
    jnz .remove_arg
    mov rdi, r14
    lea rsi, [rel cmd_unwield]
    call eq
    test eax, eax
    jnz .remove
    mov rdi, r14
    lea rsi, [rel cmd_unwield_sp]
    mov edx, 8
    call prefix
    test eax, eax
    jnz .remove_arg

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
    lea rsi, [rel cmd_talk]
    call eq
    test eax, eax
    jnz .talk
    mov rdi, r14
    lea rsi, [rel cmd_ask]
    call eq
    test eax, eax
    jnz .talk
    mov rdi, r14
    lea rsi, [rel cmd_buy]
    call eq
    test eax, eax
    jnz .buy_empty
    mov rdi, r14
    lea rsi, [rel cmd_buy_sp]
    mov edx, 4
    call prefix
    test eax, eax
    jnz .buy_arg
    mov rdi, r14
    lea rsi, [rel cmd_wall]
    call eq
    test eax, eax
    jnz .wall_empty
    mov rdi, r14
    lea rsi, [rel cmd_wall_sp]
    mov edx, 5
    call prefix
    test eax, eax
    jnz .wall_arg
    mov rdi, r14
    lea rsi, [rel cmd_tell]
    call eq
    test eax, eax
    jnz .tell_empty
    mov rdi, r14
    lea rsi, [rel cmd_tell_sp]
    mov edx, 5
    call prefix
    test eax, eax
    jnz .tell_arg
    mov rdi, r14
    lea rsi, [rel cmd_reply]
    call eq
    test eax, eax
    jnz .reply_empty
    mov rdi, r14
    lea rsi, [rel cmd_reply_sp]
    mov edx, 6
    call prefix
    test eax, eax
    jnz .reply_arg
    mov rdi, r14
    lea rsi, [rel cmd_yell]
    call eq
    test eax, eax
    jnz .yell_empty
    mov rdi, r14
    lea rsi, [rel cmd_yell_sp]
    mov edx, 5
    call prefix
    test eax, eax
    jnz .yell_arg
    mov rdi, r14
    lea rsi, [rel cmd_emote]
    call eq
    test eax, eax
    jnz .emote_empty
    mov rdi, r14
    lea rsi, [rel cmd_emote_sp]
    mov edx, 6
    call prefix
    test eax, eax
    jnz .emote_arg
    mov rdi, r14
    lea rsi, [rel cmd_mend]
    call eq
    test eax, eax
    jnz .mend_empty
    mov rdi, r14
    lea rsi, [rel cmd_mend_sp]
    mov edx, 5
    call prefix
    test eax, eax
    jnz .mend_arg
    mov rdi, r14
    lea rsi, [rel cmd_give]
    call eq
    test eax, eax
    jnz .give_empty
    mov rdi, r14
    lea rsi, [rel cmd_give_sp]
    mov edx, 5
    call prefix
    test eax, eax
    jnz .give_arg

    mov rdi, r14
    lea rsi, [rel cmd_gridcast]
    call eq
    test eax, eax
    jnz .gridcast_empty
    mov rdi, r14
    lea rsi, [rel cmd_gridcast_sp]
    mov edx, 9
    call prefix
    test eax, eax
    jnz .gridcast_arg
    mov rdi, r14
    lea rsi, [rel cmd_gc]
    call eq
    test eax, eax
    jnz .gridcast_empty
    mov rdi, r14
    lea rsi, [rel cmd_gc_sp]
    mov edx, 3
    call prefix
    test eax, eax
    jnz .gc_arg
    mov rdi, r14
    lea rsi, [rel cmd_list]
    call eq
    test eax, eax
    jnz .list
    mov rdi, r14
    lea rsi, [rel cmd_war]
    call eq
    test eax, eax
    jnz .war
    mov rdi, r14
    lea rsi, [rel cmd_shelter]
    call eq
    test eax, eax
    jnz .shelter
    mov rdi, r14
    lea rsi, [rel cmd_saved]
    call eq
    test eax, eax
    jnz .saved

    mov rdi, r14
    lea rsi, [rel cmd_cache]
    call eq
    test eax, eax
    jnz .cache_empty
    mov rdi, r14
    lea rsi, [rel cmd_cache_sp]
    mov edx, 6
    call prefix
    test eax, eax
    jnz .cache_arg
    mov rdi, r14
    lea rsi, [rel cmd_gather]
    call eq
    test eax, eax
    jnz .gather
    mov rdi, r14
    lea rsi, [rel cmd_treat]
    call eq
    test eax, eax
    jnz .treat

    mov rdi, r14
    lea rsi, [rel cmd_sell]
    call eq
    test eax, eax
    jnz .sell_empty
    mov rdi, r14
    lea rsi, [rel cmd_sell_sp]
    mov edx, 5
    call prefix
    test eax, eax
    jnz .sell_arg
    mov rdi, r14
    lea rsi, [rel cmd_steal]
    call eq
    test eax, eax
    jnz .steal
    mov rdi, r14
    lea rsi, [rel cmd_sense]
    call eq
    test eax, eax
    jnz .sense
    mov rdi, r14
    lea rsi, [rel cmd_actions]
    call eq
    test eax, eax
    jnz .sense
    mov rdi, r14
    lea rsi, [rel cmd_forgive]
    call eq
    test eax, eax
    jnz .forgive_empty
    mov rdi, r14
    lea rsi, [rel cmd_forgive_sp]
    mov edx, 8
    call prefix
    test eax, eax
    jnz .forgive_arg
    mov rdi, r14
    lea rsi, [rel cmd_absolve]
    call eq
    test eax, eax
    jnz .forgive_empty
    mov rdi, r14
    lea rsi, [rel cmd_absolve_sp]
    mov edx, 8
    call prefix
    test eax, eax
    jnz .forgive_arg_abs
    mov rdi, r14
    lea rsi, [rel cmd_pardon]
    call eq
    test eax, eax
    jnz .forgive_empty
    mov rdi, r14
    lea rsi, [rel cmd_pardon_sp]
    mov edx, 7
    call prefix
    test eax, eax
    jnz .forgive_arg_par

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
    lea rsi, [rel cmd_defy]
    call eq
    test eax, eax
    jnz .defy
    mov rdi, r14
    lea rsi, [rel cmd_defect]
    call eq
    test eax, eax
    jnz .defy

    mov rdi, r14
    lea rsi, [rel cmd_witness]
    call eq
    test eax, eax
    jnz .witness_empty
    mov rdi, r14
    lea rsi, [rel cmd_witness_sp]
    mov edx, 8
    call prefix
    test eax, eax
    jnz .witness_arg
    mov rdi, r14
    lea rsi, [rel cmd_remember]
    call eq
    test eax, eax
    jnz .witness_empty
    mov rdi, r14
    lea rsi, [rel cmd_remember_sp]
    mov edx, 9
    call prefix
    test eax, eax
    jnz .witness_arg_remember
    mov rdi, r14
    lea rsi, [rel cmd_mourn]
    call eq
    test eax, eax
    jnz .witness_empty
    mov rdi, r14
    lea rsi, [rel cmd_mourn_sp]
    mov edx, 6
    call prefix
    test eax, eax
    jnz .witness_arg_mourn

    mov rdi, r14
    lea rsi, [rel cmd_reckoning]
    call eq
    test eax, eax
    jnz .reckoning
    mov rdi, r14
    lea rsi, [rel cmd_conscience]
    call eq
    test eax, eax
    jnz .reckoning
    mov rdi, r14
    lea rsi, [rel cmd_record]
    call eq
    test eax, eax
    jnz .reckoning

    mov rdi, r14
    lea rsi, [rel cmd_gridstats]
    call eq
    test eax, eax
    jnz .gridstats
    mov rdi, r14
    lea rsi, [rel cmd_gridprune]
    call eq
    test eax, eax
    jnz .gridprune

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
    lea rsi, [rel cmd_title]
    call eq
    test eax, eax
    jnz .title_empty
    mov rdi, r14
    lea rsi, [rel cmd_title_sp]
    mov edx, 6
    call prefix
    test eax, eax
    jnz .title_arg

    mov rdi, r14
    lea rsi, [rel cmd_who]
    call eq
    test eax, eax
    jnz .who

    mov rdi, r14
    lea rsi, [rel cmd_free]
    call eq
    test eax, eax
    jnz .free
    mov rdi, r14
    lea rsi, [rel cmd_rescue]
    call eq
    test eax, eax
    jnz .free
    mov rdi, r14
    lea rsi, [rel cmd_release]
    call eq
    test eax, eax
    jnz .free
    mov rdi, r14
    lea rsi, [rel cmd_unlock]
    call eq
    test eax, eax
    jnz .free
    mov rdi, r14
    lea rsi, [rel cmd_liberate]
    call eq
    test eax, eax
    jnz .free
    mov rdi, r14
    lea rsi, [rel cmd_unchain]
    call eq
    test eax, eax
    jnz .free
    mov rdi, r14
    lea rsi, [rel cmd_unshackle]
    call eq
    test eax, eax
    jnz .free
    mov rdi, r14
    lea rsi, [rel cmd_untie]
    call eq
    test eax, eax
    jnz .free

    mov rdi, r14
    lea rsi, [rel cmd_recall]
    call eq
    test eax, eax
    jnz .recall
    mov rdi, r14
    lea rsi, [rel cmd_home]
    call eq
    test eax, eax
    jnz .recall

    mov rdi, r14
    lea rsi, [rel cmd_affects]
    call eq
    test eax, eax
    jnz .affects

    mov rdi, r14
    lea rsi, [rel cmd_inscribe]
    call eq
    test eax, eax
    jnz .inscribe_empty
    mov rdi, r14
    lea rsi, [rel cmd_inscribe_sp]
    mov edx, 9
    call prefix
    test eax, eax
    jnz .inscribe_arg

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
.remove_arg:
    lea rdx, [r14 + 7]
    mov rdi, r12
    mov rsi, r13
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



.gridcast_empty:
    mov rdi, r12
    mov rsi, r13
    xor edx, edx
    call hg_cmd_gridcast
    jmp .done
.gridcast_arg:
    lea rdx, [r14 + 9]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_gridcast
    jmp .done
.gc_arg:
    lea rdx, [r14 + 3]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_gridcast
    jmp .done
.list:
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_list
    jmp .done
.war:
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_war
    jmp .done
.shelter:
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_shelter
    jmp .done
.saved:
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_saved
    jmp .done
.cache_empty:
    mov rdi, r12
    mov rsi, r13
    xor edx, edx
    call hg_cmd_cache
    jmp .done
.cache_arg:
    lea rdx, [r14 + 6]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_cache
    jmp .done
.gather:
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_gather
    jmp .done
.treat:
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_treat
    jmp .done
.talk:
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_talk
    jmp .done
.buy_empty:
    mov rdi, r12
    mov rsi, r13
    xor edx, edx
    call hg_cmd_buy
    jmp .done
.buy_arg:
    lea rdx, [r14 + 4]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_buy
    jmp .done
.wall_empty:
    mov rdi, r12
    mov rsi, r13
    xor edx, edx
    call hg_cmd_wall
    jmp .done
.wall_arg:
    lea rdx, [r14 + 5]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_wall
    jmp .done
.tell_empty:
    mov rdi, r12
    mov rsi, r13
    xor edx, edx
    call hg_cmd_tell
    jmp .done
.tell_arg:
    lea rdx, [r14 + 5]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_tell
    jmp .done
.reply_empty:
    mov rdi, r12
    mov rsi, r13
    xor edx, edx
    call hg_cmd_reply
    jmp .done
.reply_arg:
    lea rdx, [r14 + 6]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_reply
    jmp .done
.yell_empty:
    mov rdi, r12
    mov rsi, r13
    xor edx, edx
    call hg_cmd_yell
    jmp .done
.yell_arg:
    lea rdx, [r14 + 5]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_yell
    jmp .done
.emote_empty:
    mov rdi, r12
    mov rsi, r13
    xor edx, edx
    call hg_cmd_emote
    jmp .done
.emote_arg:
    lea rdx, [r14 + 6]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_emote
    jmp .done
.mend_empty:
    mov rdi, r12
    mov rsi, r13
    xor edx, edx
    call hg_cmd_mend
    jmp .done
.mend_arg:
    lea rdx, [r14 + 5]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_mend
    jmp .done
.give_empty:
    mov rdi, r12
    mov rsi, r13
    xor edx, edx
    call hg_cmd_give
    jmp .done
.give_arg:
    lea rdx, [r14 + 5]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_give
    jmp .done
.look_arg:
    lea rdx, [r14 + 5]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_look_player
    test eax, eax
    jnz .done
    lea rdx, [r14 + 5]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_look_mob
    jmp .done
.sell_empty:
    mov rdi, r12
    mov rsi, r13
    xor edx, edx
    call hg_cmd_sell
    jmp .done
.sell_arg:
    lea rdx, [r14 + 5]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_sell
    jmp .done
.steal:
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_steal
    jmp .done
.sense:
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_sense
    jmp .done
.forgive_empty:
    mov rdi, r12
    mov rsi, r13
    xor edx, edx
    call hg_cmd_forgive
    jmp .done
.forgive_arg:
    lea rdx, [r14 + 8]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_forgive
    jmp .done
.forgive_arg_abs:
    lea rdx, [r14 + 8]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_forgive
    jmp .done
.forgive_arg_par:
    lea rdx, [r14 + 7]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_forgive
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
.affects:
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_affects
    jmp .done
.inscribe_empty:
    mov rdi, r12
    mov rsi, r13
    xor edx, edx
    call hg_cmd_inscribe
    jmp .done
.inscribe_arg:
    lea rdx, [r14 + 9]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_inscribe
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
.defy:
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_defy
    jmp .done
.witness_empty:
    mov rdi, r12
    mov rsi, r13
    xor edx, edx
    call hg_cmd_witness
    jmp .done
.witness_arg:
    lea rdx, [r14 + 8]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_witness
    jmp .done
.witness_arg_remember:
    lea rdx, [r14 + 9]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_witness
    jmp .done
.witness_arg_mourn:
    lea rdx, [r14 + 6]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_witness
    jmp .done
.reckoning:
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_reckoning
    jmp .done
.gridstats:
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_gridstats
    jmp .done
.gridprune:
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_gridprune
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

.title_empty:
    mov rdi, r12
    mov rsi, r13
    xor edx, edx
    call hg_cmd_title
    jmp .done
.title_arg:
    lea rdx, [r14 + 6]
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_title
    jmp .done
.who:
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_who
    jmp .done
.free:
    mov rdi, r12
    mov rsi, r13
    call hg_cmd_free
    jmp .done
.recall:
    mov qword [r12 + SESSION_ROOM], ROOM_NEXUS
    lea rdi, [r12 + SESSION_POSITION]
    lea rsi, [rel position_standing]
    call strcpy wrt ..plt
    jmp .scene

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
