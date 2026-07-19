default rel
%include "state.inc"

section .bss
world_tick: resq 1
world_started_ms: resq 1
last_heartbeat_ms: resq 1
rat_hp: resq 1
rat_alive: resq 1
rat_died_at: resq 1
market_resolved: resb 1
    resb 7                      ; pad to 8-byte alignment for session_table
session_table: resq HG_MAX_SESSIONS
session_wsi_table: resq HG_MAX_SESSIONS
session_count: resq 1
heartbeat_now_ms: resq 1
vitals_scratch: resb 512
affects_scratch: resb 512

section .rodata
json_true: db "true", 0
json_false: db "false", 0
empty_mobs: db "[]", 0
rat_live_mobs: db '[{"id":"rat","name":"a glow-rat"}]', 0
mob_rat: db "rat", 0
mob_glow: db "a glow-rat", 0
mob_glow_short: db "glow-rat", 0
item_shiv: db "shiv", 0
item_charm: db "charm", 0
faction_front: db "front", 0
faction_ally: db "ally", 0
faction_none: db "none", 0
race_elf: db "elf", 0
race_dustkin: db "dustkin", 0
position_standing: db "standing", 0
position_resting: db "resting", 0
rat_desc:
    db "A bloated rodent, fur matted and faintly luminous with absorbed rads.", 13, 10, 0
consider_easy:
    db "You could put a glow-rat down without breaking a sweat.", 13, 10, 13, 10
consider_easy_end:
    db 0
consider_easy_len: equ consider_easy_end - consider_easy
attack_prose:
    db "You throw yourself at a glow-rat.", 13, 10
attack_prose_end:
attack_prose_len: equ attack_prose_end - attack_prose
kill_prose_fmt: db "You have slain a glow-rat!  (+8 xp)", 13, 10, 0
already_fighting:
    db "You're already locked in this fight.", 13, 10, 13, 10
already_fighting_end:
    db 0
already_fighting_len: equ already_fighting_end - already_fighting
no_target:
    db "There's nothing like that here to attack.", 13, 10, 13, 10
no_target_end:
    db 0
no_target_len: equ no_target_end - no_target
no_mob:
    db "You don't see that here.", 13, 10, 13, 10
no_mob_end:
    db 0
no_mob_end_len: equ no_mob_end - no_mob
wield_prose:
    db "You ready shiv.", 13, 10, 13, 10
wield_prose_end:
    db 0
wield_prose_len: equ wield_prose_end - wield_prose
remove_prose:
    db "You stow shiv.", 13, 10, 13, 10
remove_prose_end:
    db 0
remove_prose_len: equ remove_prose_end - remove_prose
no_item:
    db "You have nothing like that to wear.", 13, 10, 13, 10
no_item_end:
    db 0
no_item_len: equ no_item_end - no_item
not_wearing:
    db "You are not wearing that.", 13, 10, 13, 10
not_wearing_end:
    db 0
not_wearing_len: equ not_wearing_end - not_wearing
rest_prose:
    db "You settle against the cold metal and let your breath slow.", 13, 10, 13, 10
rest_prose_end:
    db 0
rest_prose_len: equ rest_prose_end - rest_prose
affects_clear:
    db "You stand clear: no afflictions hold you.", 13, 10, 13, 10
affects_clear_end:
    db 0
affects_clear_len: equ affects_clear_end - affects_clear
inscribe_need:
    db "Carve what into the Grid? (inscribe <a few words for whoever comes next>)", 13, 10, 13, 10
inscribe_need_end:
    db 0
inscribe_need_len: equ inscribe_need_end - inscribe_need
inscribe_line1:
    db "You press your words into the dead network, where they will outlast you:", 13, 10
inscribe_line1_end:
    db 0
inscribe_line1_len: equ inscribe_line1_end - inscribe_line1
inscribe_line2:
    db "The Grid takes them. Someone will key into this node, long after you are gone, and hear you. (try ping)", 13, 10, 13, 10
inscribe_line2_end:
    db 0
inscribe_line2_len: equ inscribe_line2_end - inscribe_line2
inscribe_quote_fmt: db '  "%s"', 13, 10, 0
stand_prose:
    db "You get to your feet.", 13, 10, 13, 10
stand_prose_end:
    db 0
stand_prose_len: equ stand_prose_end - stand_prose
sleep_prose:
    db "You close your eyes, and the dead network leans close and shows you something.", 13, 10, 13, 10
sleep_prose_end:
    db 0
sleep_prose_len: equ sleep_prose_end - sleep_prose
join_prose:
    db "You take the Front's coin. It is warm, which is worse. You are Cinder Front now, and the wastes will remember which side you chose when choosing was easy.", 13, 10, 13, 10
join_prose_end:
    db 0
join_prose_len: equ join_prose_end - join_prose
join_ash_prose:
    db "You take the Front's coin. The recruiter sees what you are -- one of the hunted -- and grins, because there is no one they prize more than a traitor to his own. They burn the mark into you: ash-sworn. A kapo. One of your people's hunters now. It does not wash off, in this life or in the Grid's long memory.", 13, 10, 13, 10
join_ash_prose_end:
    db 0
join_ash_prose_len: equ join_ash_prose_end - join_ash_prose
no_oath:
    db "There is no one here to swear to.", 13, 10, 13, 10
no_oath_end:
    db 0
no_oath_len: equ no_oath_end - no_oath
defend_prose:
    db "You step between the recruiter and the refugees. The recruiter spits and storms off.", 13, 10, 13, 10
defend_prose_end:
    db 0
defend_prose_len: equ defend_prose_end - defend_prose
no_stand:
    db "There is no stand to take here.", 13, 10, 13, 10
no_stand_end:
    db 0
no_stand_len: equ no_stand_end - no_stand
fight_block:
    db "Not while you're fighting for your life.", 13, 10, 13, 10
fight_block_end:
    db 0
fight_block_len: equ fight_block_end - fight_block
free_none:
    db "There is no one here to free.", 13, 10, 13, 10
free_none_end:
    db 0
free_none_len: equ free_none_end - free_none
title_cleared:
    db "Your title is cleared.", 13, 10, 13, 10
title_cleared_end:
    db 0
title_cleared_len: equ title_cleared_end - title_cleared
title_set_fmt: db "Your title is now: %s.", 13, 10, 0
exits_fmt: db "Exits: %s", 13, 10, 0
world_prose_fmt: db "The sky: %s, clear.", 13, 10, 0
arg_all: db "all", 0
died_prose:
    db "The dark takes you -- and the Grid, stubborn, reknits you at the Cracked Nexus.", 13, 10, 13, 10
died_prose_end:
    db 0
died_prose_len: equ died_prose_end - died_prose
phase_day: db "day", 0
phase_dusk: db "dusk", 0
phase_night: db "night", 0
phase_dawn: db "dawn", 0
combat_end_result_killed: db "killed", 0
combat_end_result_died: db "died", 0
combat_end_result_gone: db "gone", 0
nexus_id_lit: db "nexus", 0

; Absolute pointer tables need load-time relocation; .data.rel.ro keeps them
; out of the text segment (no DT_TEXTREL) and RELRO seals them read-only.
section .data.rel.ro progbits alloc noexec write align=8
phase_table: dq phase_day, phase_dusk, phase_night, phase_dawn

section .text
extern time
extern snprintf
extern strlen
extern strcpy
extern strncpy
extern strcasecmp
extern hg_session_queue
extern hg_emit_equipment
extern hg_emit_scene
extern hg_store_save
extern hg_room_id
extern hg_room_exits
extern hg_room_mobs
extern hg_fmt_vitals
extern hg_fmt_affects
extern hg_fmt_combat_start
extern hg_fmt_combat_round
extern hg_fmt_combat_end
extern hg_fmt_attack_miss
extern hg_fmt_who_local
extern hg_fmt_char_died
extern hg_fmt_world_state
extern hg_format_world_state
extern hg_emit_vitals_dyn
extern hg_emit_affects_dyn
extern hg_emit_dream_now
extern hg_now_ms
extern hg_combat_arm
extern hg_session_flush
extern hg_grid_on_kill
extern hg_grid_on_death
extern hg_grid_fmt_listen
extern hg_grid_fmt_ping_echo
extern hg_grid_inscribe
extern hg_join_record_oath
extern hg_grid_shift_tide
extern hg_cmd_gridcast_c
extern hg_cmd_list_c
extern hg_cmd_war_c
extern hg_cmd_free_c
extern hg_cmd_shelter_c
extern hg_cmd_saved_c
extern hg_cmd_sell_c
extern hg_cmd_steal_c
extern hg_cmd_sense_c
extern hg_cmd_look_player_c
extern hg_cmd_forgive_c
extern hg_cmd_talk_c
extern hg_cmd_buy_c
extern hg_cmd_wall_c
extern hg_cmd_tell_c
extern hg_cmd_reply_c
extern hg_cmd_yell_c
extern hg_cmd_emote_c
extern hg_cmd_mend_c
extern hg_cmd_give_c
extern hg_inv_add_item
extern hg_cmd_who_c
extern hg_cmd_cache_c
extern hg_cmd_gather_c
extern hg_cmd_treat_c
extern hg_dais_pledge_c
extern hg_moral_arc_now
extern hg_cmd_defy_c
extern hg_cmd_witness_c
extern hg_cmd_reckoning_c
extern hg_cmd_gridstats_c
extern hg_cmd_gridprune_c
extern hg_grid_fmt_ping_all
extern hg_grid_fmt_worlds
extern hg_grid_fmt_travel
extern hg_grid_fmt_whoami
extern memcpy
extern memset
global hg_world_boot
global hg_emit_vitals
global hg_room_live_mobs
global hg_session_register
global hg_session_unregister
global hg_heartbeat
global hg_cmd_wield
global hg_cmd_remove
global hg_cmd_attack
global hg_cmd_consider
global hg_cmd_look_mob
global hg_cmd_exits
global hg_cmd_sleep
global hg_cmd_stand
global hg_cmd_rest
global hg_cmd_affects
global hg_cmd_inscribe
global hg_cmd_sell
global hg_cmd_steal
global hg_cmd_sense
global hg_cmd_forgive
global hg_cmd_look_player
global hg_cmd_talk
global hg_cmd_buy
global hg_cmd_wall
global hg_cmd_tell
global hg_cmd_reply
global hg_cmd_yell
global hg_cmd_emote
global hg_cmd_mend
global hg_cmd_give
global hg_cmd_cache
global hg_cmd_gather
global hg_cmd_treat
global hg_cmd_gridcast
global hg_cmd_list
global hg_cmd_war
global hg_cmd_shelter
global hg_cmd_saved
global hg_cmd_join
global hg_cmd_defend
global hg_cmd_defy
global hg_cmd_witness
global hg_cmd_reckoning
global hg_cmd_gridstats
global hg_cmd_gridprune
global hg_cmd_ping
global hg_cmd_world
global hg_cmd_listen
global hg_cmd_whoami
global hg_cmd_worlds
global hg_cmd_travel
global hg_cmd_title
global hg_cmd_who
global hg_cmd_free
global hg_session_pulse
global hg_session_flush_all
global hg_session_count
global hg_session_at
global hg_world_tick_value
global hg_room_id_cstr

; rdi=session, rsi=wsi, rdx=data, rcx=len
queue_bytes:
    jmp hg_session_queue

; rdi=session, rsi=wsi, rdx=zero-terminated string
queue_cstring:
    push rdi
    push rsi
    push rdx
    mov rdi, rdx
    call strlen wrt ..plt
    mov rcx, rax
    pop rdx
    pop rsi
    pop rdi
    jmp queue_bytes

; r12=session, r13=wsi, r15=buffer with formatted event
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

; r12=session, r13=wsi throughout command handlers
setup_cmd:
    mov r12, rdi
    mov r13, rsi
    mov [r12 + SESSION_WSI], r13
    ret

; int64 player_damage(session) -- r12=session; base 5 + shiv 3
player_damage:
    mov eax, 5
    lea rdi, [r12 + SESSION_EQ_WEAPON]
    cmp byte [rdi], 0
    je .done
    lea rsi, [rel item_shiv]
.loop:
    movzx ecx, byte [rdi]
    movzx edx, byte [rsi]
    test cl, cl
    jz .has_shiv
    test dl, dl
    jz .done
    cmp cl, dl
    jne .done
    inc rdi
    inc rsi
    jmp .loop
.has_shiv:
    test dl, dl
    jnz .done
    add eax, 3
.done:
    ret

emit_world_state:
    push r12
    push r13
    push r15
    sub rsp, 288
    mov r12, rdi
    mov r13, rsi
    mov [r12 + SESSION_WSI], r13
    lea r15, [rsp + 40]
    mov rax, [rel world_tick]
    and eax, 3
    lea rcx, [rel phase_table]
    mov rcx, [rcx + rax * 8]
    mov rdi, r15
    mov esi, 240
    mov rdx, [rel world_tick]
    call hg_format_world_state wrt ..plt
    mov rdi, r12
    mov rsi, r13
    mov rdx, r15
    call queue_cstring
    add rsp, 288
    pop r15
    pop r13
    pop r12
    ret

hg_emit_vitals:
    jmp hg_emit_vitals_dyn

emit_affects:
    jmp hg_emit_affects_dyn

; One exchange per heartbeat tick against the glow-rat.
; Stack: [rsp]=mob_dmg arg7, [rsp+8]=hp arg8, [rsp+16..]=format buffer
; C ABI entry: rdi=session, rsi=wsi. Also exposed as hg_combat_round.
global hg_combat_round
hg_combat_round:
combat_round:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 528
    mov r12, rdi
    mov r13, rsi
    mov [r12 + SESSION_WSI], r13
    cmp qword [r12 + SESSION_TARGET], 0
    je .done
    cmp qword [rel rat_alive], 0
    jne .fight
    mov qword [r12 + SESSION_IN_COMBAT], 0
    mov qword [r12 + SESSION_TARGET], 0
    lea r15, [rsp + 16]
    mov rdi, r15
    mov esi, 500
    lea rdx, [rel mob_rat]
    lea rcx, [rel combat_end_result_gone]
    call hg_fmt_combat_end wrt ..plt
    call queue_buffer
    mov rdi, r12
    mov rsi, r13
    call hg_emit_vitals
    jmp .done
.fight:
    call player_damage
    mov ebx, eax
    mov rax, [rel rat_hp]
    sub rax, rbx
    cmp rax, 0
    jge .hp_ok
    xor eax, eax
.hp_ok:
    mov [rel rat_hp], rax
    xor r14d, r14d
    cmp qword [rel rat_hp], 0
    jle .emit
    mov r14d, 4
    sub [r12 + SESSION_HP], r14
.emit:
    mov [rsp], r14
    mov rax, [r12 + SESSION_HP]
    mov [rsp + 8], rax
    lea r15, [rsp + 16]
    mov rdi, r15
    mov esi, 500
    lea rdx, [rel mob_rat]
    mov rcx, [rel rat_hp]
    mov r8d, 12
    mov r9, rbx
    call hg_fmt_combat_round wrt ..plt
    call queue_buffer

    cmp qword [rel rat_hp], 0
    jle .killed
    cmp qword [r12 + SESSION_HP], 0
    jle .player_dead
    mov rdi, r12
    mov rsi, r13
    call hg_emit_vitals
    jmp .done

.killed:
    mov qword [rel rat_alive], 0
    call hg_now_ms wrt ..plt
    mov [rel rat_died_at], rax
    mov qword [r12 + SESSION_IN_COMBAT], 0
    mov qword [r12 + SESSION_TARGET], 0
    add qword [r12 + SESSION_XP], 8
    lea r15, [rsp + 16]
    mov rdi, r15
    mov esi, 500
    lea rdx, [rel mob_rat]
    lea rcx, [rel combat_end_result_killed]
    call hg_fmt_combat_end wrt ..plt
    call queue_buffer
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel kill_prose_fmt]
    call queue_cstring
    call kill_hub_record
    mov rdi, r12
    mov rsi, r13
    call hg_emit_vitals
    mov rdi, r12
    call hg_store_save
    jmp .done

.player_dead:
    call player_died
.done:
    add rsp, 528
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

kill_hub_record:
    sub rsp, 8
    mov rdi, [r12 + SESSION_ROOM]
    call hg_room_id
    mov rdi, rax
    lea rsi, [r12 + SESSION_NAME]
    lea rdx, [rel mob_glow]
    call hg_grid_on_kill wrt ..plt
    add rsp, 8
    ret

player_died:
    push r14
    push r15
    sub rsp, 520
    mov r14, rsp
    mov rdi, [r12 + SESSION_ROOM]
    call hg_room_id
    mov rdi, rax
    lea rsi, [r12 + SESSION_NAME]
    call hg_grid_on_death wrt ..plt
    mov rax, [r12 + SESSION_MAX_HP]
    mov [r12 + SESSION_HP], rax
    mov qword [r12 + SESSION_ROOM], ROOM_NEXUS
    mov qword [r12 + SESSION_IN_COMBAT], 0
    mov qword [r12 + SESSION_TARGET], 0
    mov qword [r12 + SESSION_POISONED], 0
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel died_prose]
    mov ecx, died_prose_len
    call queue_bytes
    mov rdi, r14
    mov esi, 240
    lea rdx, [rel nexus_id_lit]
    mov rcx, [r12 + SESSION_HP]
    mov r8, [r12 + SESSION_MAX_HP]
    call hg_fmt_char_died wrt ..plt
    mov rdi, r12
    mov rsi, r13
    mov rdx, r14
    mov ecx, eax
    call queue_bytes
    lea r15, [r14 + 256]
    mov rdi, r15
    mov esi, 240
    lea rdx, [rel mob_rat]
    lea rcx, [rel combat_end_result_died]
    call hg_fmt_combat_end wrt ..plt
    mov rdi, r12
    mov rsi, r13
    mov rdx, r15
    mov ecx, eax
    call queue_bytes
    mov rdi, r12
    mov rsi, r13
    call hg_emit_vitals
    mov rdi, r12
    mov rsi, r13
    call hg_emit_scene
    add rsp, 520
    pop r15
    pop r14
    ret

tick_session:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, [r12 + SESSION_WSI]
    test r13, r13
    jnz .have_wsi
    lea r15, [rel session_table]
    lea r14, [rel session_wsi_table]
    xor ebx, ebx
.find_wsi:
    cmp ebx, HG_MAX_SESSIONS
    jae .done
    cmp qword [r15 + rbx * 8], r12
    je .found_wsi
    inc ebx
    jmp .find_wsi
.found_wsi:
    mov r13, [r14 + rbx * 8]
    test r13, r13
    jz .done
    mov [r12 + SESSION_WSI], r13
.have_wsi:
    cmp qword [r12 + SESSION_IN_COMBAT], 0
    jne .done
    mov rdi, r12
    mov rsi, r13
    call emit_world_state
    jmp .rest_check
.rest_check:
    lea rdi, [r12 + SESSION_POSITION]
    lea rsi, [rel position_resting]
.loop_pos:
    movzx eax, byte [rdi]
    movzx edx, byte [rsi]
    cmp al, dl
    jne .done
    test al, al
    jz .regen
    inc rdi
    inc rsi
    jmp .loop_pos
.regen:
    mov rax, [r12 + SESSION_HP]
    cmp rax, [r12 + SESSION_MAX_HP]
    jge .done
    add qword [r12 + SESSION_HP], 2
    mov rax, [r12 + SESSION_HP]
    cmp rax, [r12 + SESSION_MAX_HP]
    jle .emit_vitals
    mov rax, [r12 + SESSION_MAX_HP]
    mov [r12 + SESSION_HP], rax
.emit_vitals:
    mov rdi, r12
    mov rsi, r13
    call hg_emit_vitals
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

hg_session_pulse:
    push rbx
    push r12
    push r13
    push r14
    push r15
    ; 5 pushes from entry rsp≡8 -> rsp≡0. Aligned for combat_round/C.
    mov r12, rdi
    mov r13, rsi
    mov rbx, rdx
    cmp qword [r12 + SESSION_IN_COMBAT], 0
    je .done
    test r13, r13
    jnz .have_wsi
    ; Fall back to the registry if the session-cached wsi was cleared.
    lea r15, [rel session_table]
    lea r14, [rel session_wsi_table]
    xor ecx, ecx
.find:
    cmp ecx, HG_MAX_SESSIONS
    jae .done
    cmp qword [r15 + rcx * 8], r12
    je .found
    inc ecx
    jmp .find
.found:
    mov r13, [r14 + rcx * 8]
    test r13, r13
    jz .done
.have_wsi:
    mov [r12 + SESSION_WSI], r13
    ; Cadence: LAST_TICK==0 arms first due at now+HG_COMBAT_MS (smoke mid-fight
    ; window). When due, one combat_round then re-arm. C hg_combat_service is a
    ; parallel owner of the same fields; both must agree on the arm delay.
    mov rax, [r12 + SESSION_LAST_TICK]
    test rax, rax
    jnz .check_due
    mov rax, rbx
    add rax, HG_COMBAT_MS
    mov [r12 + SESSION_LAST_TICK], rax
    jmp .done
.check_due:
    cmp rbx, rax
    jb .done
    mov rax, rbx
    add rax, HG_COMBAT_MS
    mov [r12 + SESSION_LAST_TICK], rax
    mov rdi, r12
    mov rsi, r13
    call combat_round
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret


; Flush every session with pending OUT. Called each service-loop turn so
; heartbeat-queued combat frames are not stranded if WRITEABLE is skipped.
hg_session_flush_all:
    push rbx
    push r15
    sub rsp, 8
    lea r15, [rel session_table]
    xor ebx, ebx
.loop:
    cmp ebx, HG_MAX_SESSIONS
    jae .done
    mov rdi, [r15 + rbx * 8]
    test rdi, rdi
    jz .next
    call hg_session_flush
.next:
    inc ebx
    jmp .loop
.done:
    add rsp, 8
    pop r15
    pop rbx
    ret

hg_world_boot:
    sub rsp, 8
    mov qword [rel world_started_ms], 0
    mov qword [rel last_heartbeat_ms], 0
    mov qword [rel world_tick], 0
    mov qword [rel rat_hp], 12
    mov qword [rel rat_alive], 1
    mov qword [rel rat_died_at], 0
    mov byte [rel market_resolved], 0
    mov qword [rel session_count], 0
    push r15
    push r14
    lea r15, [rel session_table]
    lea r14, [rel session_wsi_table]
    xor ecx, ecx
.clear_table:
    cmp ecx, HG_MAX_SESSIONS
    jae .clear_done
    mov qword [r15 + rcx * 8], 0
    mov qword [r14 + rcx * 8], 0
    inc ecx
    jmp .clear_table
.clear_done:
    pop r14
    pop r15
.done:
    add rsp, 8
    ret

hg_room_live_mobs:
    cmp rdi, ROOM_TUNNELS
    jne .static
    cmp qword [rel rat_alive], 0
    je .static
    lea rax, [rel rat_live_mobs]
    ret
.static:
    jmp hg_room_mobs

hg_session_register:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov [r12 + SESSION_WSI], r13
    lea r15, [rel session_table]
    lea r14, [rel session_wsi_table]
    xor ebx, ebx
.find_slot:
    cmp ebx, HG_MAX_SESSIONS
    jae .done
    cmp qword [r15 + rbx * 8], 0
    je .insert
    cmp qword [r15 + rbx * 8], r12
    je .update_wsi
    inc ebx
    jmp .find_slot
.insert:
    mov [r15 + rbx * 8], r12
    inc qword [rel session_count]
.update_wsi:
    mov [r14 + rbx * 8], r13
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

hg_session_unregister:
    push rbx
    push r12
    push r14
    push r15
    mov r12, rdi
    lea r15, [rel session_table]
    lea r14, [rel session_wsi_table]
    mov qword [r12 + SESSION_WSI], 0
    xor ebx, ebx
.find:
    cmp ebx, HG_MAX_SESSIONS
    jae .done
    cmp qword [r15 + rbx * 8], r12
    jne .next
    mov qword [r15 + rbx * 8], 0
    mov qword [r14 + rbx * 8], 0
    dec qword [rel session_count]
    jmp .done
.next:
    inc ebx
    jmp .find
.done:
    pop r15
    pop r14
    pop r12
    pop rbx
    ret

hg_heartbeat:
    push rbx
    push r12
    push r14
    push r15
    ; entry rsp≡8; 4 pushes -> ≡8; pad to ≡0 before any calls.
    sub rsp, 8
    mov [rel heartbeat_now_ms], rdi
    mov r12, rdi
    lea r15, [rel session_table]
    ; Always pulse in-combat sessions; resolve wsi via session or registry.
    xor ebx, ebx
.combat_pulse:
    cmp ebx, HG_MAX_SESSIONS
    jae .world_gate
    mov r14, [r15 + rbx * 8]
    test r14, r14
    jz .combat_next
    cmp qword [r14 + SESSION_IN_COMBAT], 0
    je .combat_next
    mov rdi, r14
    mov rsi, [r14 + SESSION_WSI]
    mov rdx, r12
    call hg_session_pulse
    mov rdi, r14
    call hg_session_flush
.combat_next:
    inc ebx
    jmp .combat_pulse
.world_gate:
    ; One living-world beat every HG_HEARTBEAT_MS (rest + world.state + combat
    ; fallback via tick_session when pulse could not run).
    mov rax, [rel last_heartbeat_ms]
    mov rbx, HG_HEARTBEAT_MS
    add rax, rbx
    cmp r12, rax
    jb .respawn_only
    mov [rel last_heartbeat_ms], r12
    inc qword [rel world_tick]
    xor ebx, ebx
.tick_all:
    cmp ebx, HG_MAX_SESSIONS
    jae .respawn_only
    mov rdi, [r15 + rbx * 8]
    test rdi, rdi
    jz .next_session
    call tick_session
    mov rdi, [r15 + rbx * 8]
    call hg_session_flush
.next_session:
    inc ebx
    jmp .tick_all
.respawn_only:
    cmp qword [rel rat_alive], 0
    je .check_respawn
    jmp .done
.check_respawn:
    mov rax, [rel rat_died_at]
    test rax, rax
    jz .done
    mov rbx, 20000
    add rax, rbx
    cmp r12, rax
    jb .done
    mov qword [rel rat_hp], 12
    mov qword [rel rat_alive], 1
    mov qword [rel rat_died_at], 0
.done:
    add rsp, 8
    pop r15
    pop r14
    pop r12
    pop rbx
    ret

hg_cmd_wield:
    call setup_cmd
    sub rsp, 8
    ; accept empty/"shiv"
    test rdx, rdx
    jz .do_wield
    mov rdi, rdx
    lea rsi, [rel item_shiv]
    call strcasecmp wrt ..plt
    test eax, eax
    jnz .no_item
.do_wield:
    lea rdi, [r12 + SESSION_EQ_WEAPON]
    lea rsi, [rel item_shiv]
    call strcpy wrt ..plt
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel wield_prose]
    mov ecx, wield_prose_len
    call queue_bytes
    mov rdi, r12
    mov rsi, r13
    call hg_emit_equipment
    add rsp, 8
    ret
.no_item:
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel no_item]
    mov ecx, no_item_len
    call queue_bytes
    add rsp, 8
    ret

hg_cmd_remove:
    call setup_cmd
    sub rsp, 8
    ; Accept bare remove / remove shiv / unwield shiv.
    test rdx, rdx
    jz .check_slot
    mov rdi, rdx
    lea rsi, [rel item_shiv]
    call strcasecmp wrt ..plt
    test eax, eax
    jnz .no_item
.check_slot:
    lea rdi, [r12 + SESSION_EQ_WEAPON]
    cmp byte [rdi], 0
    je .not_wearing
    mov byte [rdi], 0
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel remove_prose]
    mov ecx, remove_prose_len
    call queue_bytes
    mov rdi, r12
    mov rsi, r13
    call hg_emit_equipment
    add rsp, 8
    ret
.not_wearing:
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel not_wearing]
    mov ecx, not_wearing_len
    call queue_bytes
    add rsp, 8
    ret
.no_item:
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel no_item]
    mov ecx, no_item_len
    call queue_bytes
    add rsp, 8
    ret

hg_cmd_attack:
    call setup_cmd
    push r14
    push r15
    sub rsp, 520
    mov r14, rdx
    cmp qword [r12 + SESSION_IN_COMBAT], 0
    jne .already
    cmp qword [r12 + SESSION_ROOM], ROOM_TUNNELS
    jne .miss
    cmp qword [rel rat_alive], 0
    je .miss
    test r14, r14
    jz .miss
    mov rdi, r14
    lea rsi, [rel mob_rat]
    call strcasecmp wrt ..plt
    test eax, eax
    jz .start
    mov rdi, r14
    lea rsi, [rel mob_glow]
    call strcasecmp wrt ..plt
    test eax, eax
    jz .start
    mov rdi, r14
    lea rsi, [rel mob_glow_short]
    call strcasecmp wrt ..plt
    test eax, eax
    jnz .miss
.start:
    mov qword [r12 + SESSION_IN_COMBAT], 1
    mov qword [r12 + SESSION_TARGET], 1
    lea rdi, [r12 + SESSION_POSITION]
    lea rsi, [rel position_standing]
    call strcpy wrt ..plt
    lea r15, [rsp + 8]
    mov rdi, r15
    mov esi, 500
    lea rdx, [rel mob_rat]
    lea rcx, [rel mob_glow]
    call hg_fmt_combat_start wrt ..plt
    call queue_buffer
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel attack_prose]
    mov ecx, attack_prose_len
    call queue_bytes
    mov rdi, r12
    mov rsi, r13
    call hg_emit_vitals
    ; Arm first swing at now+2000ms and set a wsi timer so lws_service wakes.
    mov rdi, r12
    mov rsi, r13
    call hg_combat_arm wrt ..plt
    jmp .out
.already:
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel already_fighting]
    mov ecx, already_fighting_len
    call queue_bytes
    jmp .out
.miss:
    lea r15, [rsp + 8]
    mov rdi, r15
    mov esi, 500
    mov rdx, r14
    lea rcx, [rel mob_glow]
    cmp qword [r12 + SESSION_ROOM], ROOM_TUNNELS
    jne .miss_empty
    cmp qword [rel rat_alive], 0
    je .miss_empty
    call hg_fmt_attack_miss wrt ..plt
    call queue_buffer
    jmp .out
.miss_empty:
    xor ecx, ecx
    call hg_fmt_attack_miss wrt ..plt
    call queue_buffer
.out:
    add rsp, 520
    pop r15
    pop r14
    ret

hg_cmd_consider:
    call setup_cmd
    cmp qword [r12 + SESSION_ROOM], ROOM_TUNNELS
    jne .no_mob
    cmp qword [rel rat_alive], 0
    je .no_mob
    mov rdi, rdx
    lea rsi, [rel mob_rat]
    call strcasecmp wrt ..plt
    test eax, eax
    jnz .no_mob
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel consider_easy]
    mov ecx, consider_easy_len
    jmp queue_bytes
.no_mob:
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel no_mob]
    mov ecx, no_mob_end_len
    jmp queue_bytes

hg_cmd_look_mob:
    call setup_cmd
    cmp qword [r12 + SESSION_ROOM], ROOM_TUNNELS
    jne .no_mob
    cmp qword [rel rat_alive], 0
    je .no_mob
    mov rdi, rdx
    lea rsi, [rel mob_rat]
    call strcasecmp wrt ..plt
    test eax, eax
    jnz .no_mob
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel rat_desc]
    jmp queue_cstring
.no_mob:
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel no_mob]
    mov ecx, no_mob_end_len
    jmp queue_bytes

hg_cmd_exits:
    call setup_cmd
    push r15
    sub rsp, 256
    mov r15, rsp
    mov rdi, [r12 + SESSION_ROOM]
    call hg_room_exits
    mov rcx, rax
    mov rdi, r15
    mov esi, 240
    lea rdx, [rel exits_fmt]
    xor eax, eax
    call snprintf wrt ..plt
    mov rdi, r12
    mov rsi, r13
    mov rdx, r15
    mov rcx, rax
    call queue_bytes
    add rsp, 256
    pop r15
    ret

hg_cmd_rest:
    call setup_cmd
    sub rsp, 8
    cmp qword [r12 + SESSION_IN_COMBAT], 0
    je .ok
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel fight_block]
    mov ecx, fight_block_len
    call queue_bytes
    add rsp, 8
    ret
.ok:
    lea rdi, [r12 + SESSION_POSITION]
    lea rsi, [rel position_resting]
    call strcpy wrt ..plt
    mov qword [rel last_heartbeat_ms], 0
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel rest_prose]
    mov ecx, rest_prose_len
    call queue_bytes
    mov rdi, r12
    mov rsi, r13
    call hg_emit_vitals
    add rsp, 8
    ret

hg_cmd_stand:
    call setup_cmd
    sub rsp, 8
    lea rdi, [r12 + SESSION_POSITION]
    lea rsi, [rel position_standing]
    call strcpy wrt ..plt
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel stand_prose]
    mov ecx, stand_prose_len
    call queue_bytes
    mov rdi, r12
    mov rsi, r13
    call hg_emit_vitals
    add rsp, 8
    ret

hg_cmd_sleep:
    call setup_cmd
    sub rsp, 8
    cmp qword [r12 + SESSION_IN_COMBAT], 0
    je .ok
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel fight_block]
    mov ecx, fight_block_len
    call queue_bytes
    add rsp, 8
    ret
.ok:
    lea rdi, [r12 + SESSION_POSITION]
    lea rsi, [rel position_resting]
    call strcpy wrt ..plt
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel sleep_prose]
    mov ecx, sleep_prose_len
    call queue_bytes
    mov rdi, r12
    call hg_emit_dream_now wrt ..plt
    mov rdi, r12
    mov rsi, r13
    call hg_emit_vitals
    add rsp, 8
    ret

hg_cmd_join:
    call setup_cmd
    sub rsp, 8
    cmp qword [r12 + SESSION_ROOM], ROOM_DAIS
    jne .try_market
    mov rdi, r12
    call hg_dais_pledge_c wrt ..plt
    add rsp, 8
    ret
.try_market:
    cmp qword [r12 + SESSION_ROOM], ROOM_MARKET
    jne .no_oath
    cmp qword [r12 + SESSION_MKT_RESOLVED], 0
    jne .no_oath
    mov qword [r12 + SESSION_MKT_RESOLVED], 1
    lea rdi, [r12 + SESSION_FACTION]
    lea rsi, [rel faction_front]
    call strcpy wrt ..plt
    ; hunted races (elf/dustkin) join brands ash-sworn and sinks harder
    lea rdi, [r12 + SESSION_RACE]
    lea rsi, [rel race_elf]
    call strcasecmp wrt ..plt
    test eax, eax
    jz .ash_join
    lea rdi, [r12 + SESSION_RACE]
    lea rsi, [rel race_dustkin]
    call strcasecmp wrt ..plt
    test eax, eax
    jnz .human_join
.ash_join:
    mov qword [r12 + SESSION_ASHSWORN], 1
    sub qword [r12 + SESSION_MORALITY], 40
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel join_ash_prose]
    mov ecx, join_ash_prose_len
    call queue_bytes
    jmp .joined
.human_join:
    sub qword [r12 + SESSION_MORALITY], 15
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel join_prose]
    mov ecx, join_prose_len
    call queue_bytes
.joined:
    mov rdi, r12
    mov rsi, r13
    call hg_emit_affects_dyn
    mov rdi, r12
    mov rsi, r13
    call hg_emit_vitals
    mov rdi, r12
    call hg_join_record_oath wrt ..plt
    mov edi, -10
    xor esi, esi
    call hg_grid_shift_tide wrt ..plt
    mov rdi, r12
    call hg_moral_arc_now wrt ..plt
    mov rdi, r12
    call hg_store_save
    add rsp, 8
    ret
.no_oath:
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel no_oath]
    mov ecx, no_oath_len
    call queue_bytes
    add rsp, 8
    ret

hg_cmd_defend:
    call setup_cmd
    sub rsp, 8
    cmp qword [r12 + SESSION_ROOM], ROOM_MARKET
    jne .no_stand
    cmp qword [r12 + SESSION_MKT_RESOLVED], 0
    jne .no_stand
    mov qword [r12 + SESSION_MKT_RESOLVED], 2
    lea rdi, [r12 + SESSION_FACTION]
    lea rsi, [rel faction_ally]
    call strcpy wrt ..plt
    add qword [r12 + SESSION_MORALITY], 25
    mov rdi, r12
    lea rsi, [rel item_charm]
    call hg_inv_add_item wrt ..plt
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel defend_prose]
    mov ecx, defend_prose_len
    call queue_bytes
    mov rdi, r12
    mov rsi, r13
    call emit_affects
    mov rdi, r12
    mov rsi, r13
    call hg_emit_vitals
    mov edi, 10
    xor esi, esi
    call hg_grid_shift_tide wrt ..plt
    mov rdi, r12
    call hg_store_save
    add rsp, 8
    ret
.no_stand:
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel no_stand]
    mov ecx, no_stand_len
    call queue_bytes
    add rsp, 8
    ret

; ping (rdx=NULL): this room's local echo, via the grid hub's node-local
; memory (always available, remote or local mode).
; ping all (rdx="all"): recentAcross the whole federation.
hg_cmd_ping:
    call setup_cmd
    push r14
    mov r14, rdx
    sub rsp, 3072
    test r14, r14
    jz .room
    mov rdi, r14
    lea rsi, [rel arg_all]
    call strcasecmp wrt ..plt
    test eax, eax
    jnz .room
    mov rdi, rsp
    mov esi, 3072
    call hg_grid_fmt_ping_all wrt ..plt
    jmp .emit
.room:
    mov rdi, [r12 + SESSION_ROOM]
    call hg_room_id
    mov rdx, rax
    mov rdi, rsp
    mov esi, 3072
    call hg_grid_fmt_ping_echo wrt ..plt
.emit:
    cmp eax, 0
    jl .done
    mov rdi, r12
    mov rsi, r13
    mov rdx, rsp
    mov ecx, eax
    call queue_bytes
.done:
    add rsp, 3072
    pop r14
    ret

; listen / tune: a random cross-world echo (recentAcross-flavored prose).
hg_cmd_listen:
    call setup_cmd
    sub rsp, 1032          ; +8 keeps rsp 16-aligned before the C call below
    mov rdi, rsp
    mov esi, 1024
    call hg_grid_fmt_listen wrt ..plt
    cmp eax, 0
    jl .done
    mov rdi, r12
    mov rsi, r13
    mov rdx, rsp
    mov ecx, eax
    call queue_bytes
.done:
    add rsp, 1032
    ret

; whoami / identity: char sheet, with a best-effort hub overlay (loadCharacter)
; in remote mode. Session fields feed a stack hg_grid_identity_ctx; C owns
; the prose + @event formatting.
hg_cmd_whoami:
    call setup_cmd
    sub rsp, 600           ; +8 keeps rsp 16-aligned before the C calls below
    lea rax, [r12 + SESSION_NAME]
    mov [rsp + 0], rax
    mov rax, [r12 + SESSION_LEVEL]
    mov [rsp + 8], rax
    mov rax, [r12 + SESSION_XP]
    mov [rsp + 16], rax
    mov rax, [r12 + SESSION_GOLD]
    mov [rsp + 24], rax
    lea rax, [r12 + SESSION_FACTION]
    mov [rsp + 32], rax
    mov rax, [r12 + SESSION_MORALITY]
    mov [rsp + 40], rax
    lea rax, [r12 + SESSION_TITLE]
    mov [rsp + 48], rax
    lea rax, [r12 + SESSION_RACE]
    mov [rsp + 56], rax
    mov rax, [r12 + SESSION_ASHSWORN]
    mov [rsp + 64], rax
    lea rdi, [rsp + 80]
    mov esi, 512
    mov rdx, rsp
    call hg_grid_fmt_whoami wrt ..plt
    cmp eax, 0
    jl .done
    lea rdx, [rsp + 80]
    mov ecx, eax
    mov rdi, r12
    mov rsi, r13
    call queue_bytes
.done:
    add rsp, 600
    ret

; worlds: listWorlds, formatted with reachability tags.
hg_cmd_worlds:
    call setup_cmd
    sub rsp, 3080          ; +8 keeps rsp 16-aligned before the C call below
    mov rdi, rsp
    mov esi, 3072
    call hg_grid_fmt_worlds wrt ..plt
    cmp eax, 0
    jl .done
    mov rdi, r12
    mov rsi, r13
    mov rdx, rsp
    mov ecx, eax
    call queue_bytes
.done:
    add rsp, 3080
    ret

; travel / gate (rdx=target, or NULL to just list worlds): emits the
; destination handoff, then closes after the queued event is written.
hg_cmd_travel:
    call setup_cmd
    push r14
    mov r14, rdx
    sub rsp, 3088
    mov dword [rsp + 3072], 0
    mov rdi, rsp
    mov esi, 3072
    mov rdx, r14
    lea rcx, [rsp + 3072]
    call hg_grid_fmt_travel wrt ..plt
    cmp eax, 0
    jl .done
    mov rdi, r12
    mov rsi, r13
    mov rdx, rsp
    mov ecx, eax
    call queue_bytes
    cmp dword [rsp + 3072], 0
    je .done
    mov qword [r12 + SESSION_CLOSE], 1
.done:
    add rsp, 3088
    pop r14
    ret

hg_cmd_world:
    call setup_cmd
    push r15
    sub rsp, 256
    mov r15, rsp
    mov rax, [rel world_tick]
    and eax, 3
    lea r8, [rel phase_table]
    mov r9, [r8 + rax * 8]
    mov rdi, r15
    mov esi, 240
    lea rdx, [rel world_prose_fmt]
    mov rcx, r9
    xor eax, eax
    call snprintf wrt ..plt
    mov rdi, r12
    mov rsi, r13
    call queue_buffer
    mov rdi, r12
    mov rsi, r13
    call emit_world_state
    add rsp, 256
    pop r15
    ret

; rdi=session, rsi=wsi, rdx=title arg (may be null/empty)
; SESSION_TITLE is 48 bytes; bound the copy (#11 remote crash).
hg_cmd_title:
    call setup_cmd
    push r15
    sub rsp, 272
    mov r15, rdx
    test r15, r15
    jz .clear
    cmp byte [r15], 0
    je .clear
    lea rdi, [r12 + SESSION_TITLE]
    mov rsi, r15
    mov edx, 47
    call strncpy wrt ..plt
    mov byte [r12 + SESSION_TITLE + 47], 0
    mov rdi, rsp
    mov esi, 240
    lea rdx, [rel title_set_fmt]
    lea rcx, [r12 + SESSION_TITLE]
    xor eax, eax
    call snprintf wrt ..plt
    mov r15, rsp
    call queue_buffer
    jmp .save
.clear:
    mov byte [r12 + SESSION_TITLE], 0
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel title_cleared]
    mov ecx, title_cleared_len
    call queue_bytes
.save:
    mov rdi, r12
    call hg_store_save
    add rsp, 272
    pop r15
    ret

hg_cmd_who:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    call hg_cmd_who_c wrt ..plt
    add rsp, 8
    ret

hg_cmd_free:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    call hg_cmd_free_c wrt ..plt
    add rsp, 8
    ret

hg_cmd_affects:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    mov rsi, r13
    call emit_affects
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel affects_clear]
    mov ecx, affects_clear_len
    call queue_bytes
    add rsp, 8
    ret

; rdx = argument text (may be null)
hg_cmd_inscribe:
    call setup_cmd
    push r14
    push r15
    sub rsp, 8
    mov r14, rdx
    test r14, r14
    jz .need
.skip:
    movzx eax, byte [r14]
    test al, al
    jz .need
    cmp al, " "
    jne .go
    inc r14
    jmp .skip
.go:
    mov rdi, [r12 + SESSION_ROOM]
    call hg_room_id
    mov rdi, rax
    lea rsi, [r12 + SESSION_NAME]
    mov rdx, r14
    call hg_grid_inscribe wrt ..plt
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel inscribe_line1]
    mov ecx, inscribe_line1_len
    call queue_bytes
    sub rsp, 128
    mov rdi, rsp
    mov esi, 120
    lea rdx, [rel inscribe_quote_fmt]
    mov rcx, r14
    xor eax, eax
    call snprintf wrt ..plt
    mov rdi, r12
    mov rsi, r13
    mov rdx, rsp
    mov rcx, rax
    call queue_bytes
    add rsp, 128
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel inscribe_line2]
    mov ecx, inscribe_line2_len
    call queue_bytes
    add rsp, 8
    pop r15
    pop r14
    ret
.need:
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel inscribe_need]
    mov ecx, inscribe_need_len
    call queue_bytes
    add rsp, 8
    pop r15
    pop r14
    ret





hg_cmd_gridcast:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    mov rsi, rdx
    call hg_cmd_gridcast_c wrt ..plt
    add rsp, 8
    ret

hg_cmd_list:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    call hg_cmd_list_c wrt ..plt
    add rsp, 8
    ret

hg_cmd_war:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    call hg_cmd_war_c wrt ..plt
    add rsp, 8
    ret

hg_cmd_shelter:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    call hg_cmd_shelter_c wrt ..plt
    add rsp, 8
    ret

hg_cmd_saved:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    call hg_cmd_saved_c wrt ..plt
    add rsp, 8
    ret

hg_cmd_cache:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    mov rsi, rdx
    call hg_cmd_cache_c wrt ..plt
    add rsp, 8
    ret

hg_cmd_gather:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    call hg_cmd_gather_c wrt ..plt
    add rsp, 8
    ret

hg_cmd_treat:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    call hg_cmd_treat_c wrt ..plt
    add rsp, 8
    ret

hg_cmd_talk:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    call hg_cmd_talk_c wrt ..plt
    add rsp, 8
    ret

hg_cmd_buy:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    mov rsi, rdx
    call hg_cmd_buy_c wrt ..plt
    add rsp, 8
    ret

hg_cmd_wall:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    mov rsi, rdx
    call hg_cmd_wall_c wrt ..plt
    add rsp, 8
    ret

hg_cmd_tell:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    mov rsi, rdx
    call hg_cmd_tell_c wrt ..plt
    add rsp, 8
    ret

hg_cmd_reply:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    mov rsi, rdx
    call hg_cmd_reply_c wrt ..plt
    add rsp, 8
    ret

hg_cmd_yell:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    mov rsi, rdx
    call hg_cmd_yell_c wrt ..plt
    add rsp, 8
    ret

hg_cmd_emote:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    mov rsi, rdx
    call hg_cmd_emote_c wrt ..plt
    add rsp, 8
    ret

hg_cmd_mend:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    mov rsi, rdx
    call hg_cmd_mend_c wrt ..plt
    add rsp, 8
    ret

hg_cmd_give:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    mov rsi, rdx
    call hg_cmd_give_c wrt ..plt
    add rsp, 8
    ret

hg_cmd_sell:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    mov rsi, rdx
    call hg_cmd_sell_c wrt ..plt
    add rsp, 8
    ret

hg_cmd_steal:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    call hg_cmd_steal_c wrt ..plt
    add rsp, 8
    ret

hg_cmd_sense:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    call hg_cmd_sense_c wrt ..plt
    add rsp, 8
    ret

hg_cmd_forgive:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    mov rsi, rdx
    call hg_cmd_forgive_c wrt ..plt
    add rsp, 8
    ret

hg_cmd_defy:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    call hg_cmd_defy_c wrt ..plt
    add rsp, 8
    ret

hg_cmd_witness:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    mov rsi, rdx
    call hg_cmd_witness_c wrt ..plt
    add rsp, 8
    ret

hg_cmd_reckoning:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    call hg_cmd_reckoning_c wrt ..plt
    add rsp, 8
    ret

hg_cmd_gridstats:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    call hg_cmd_gridstats_c wrt ..plt
    add rsp, 8
    ret

hg_cmd_gridprune:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    call hg_cmd_gridprune_c wrt ..plt
    add rsp, 8
    ret

; rdx = look target; returns via C (1 handled). Caller falls through on 0.
hg_cmd_look_player:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    mov rsi, rdx
    call hg_cmd_look_player_c wrt ..plt
    add rsp, 8
    ret

hg_session_count:
    mov eax, [rel session_count]
    ret

hg_session_at:
    cmp edi, HG_MAX_SESSIONS
    jae .none
    lea rax, [rel session_table]
    mov rax, [rax + rdi * 8]
    ret
.none:
    xor eax, eax
    ret

hg_world_tick_value:
    mov rax, [rel world_tick]
    ret

hg_room_id_cstr:
    jmp hg_room_id
