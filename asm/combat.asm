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
rat_live_mobs: db '[{"id":"rat","name":"luminous rat"}]', 0
mob_rat: db "rat", 0
mob_luminous: db "luminous rat", 0
item_shiv: db "shiv", 0
faction_front: db "front", 0
faction_ally: db "ally", 0
position_standing: db "standing", 0
position_resting: db "resting", 0
rat_desc:
    db "A bloated rodent, fur matted and faintly luminous with absorbed rads.", 13, 10, 0
consider_easy:
    db "You could put luminous rat down without breaking a sweat.", 13, 10, 0
consider_easy_end:
consider_easy_len: equ consider_easy_end - consider_easy
attack_prose:
    db "You throw yourself at luminous rat.", 13, 10
attack_prose_end:
attack_prose_len: equ attack_prose_end - attack_prose
kill_prose_fmt: db "You have slain luminous rat!  (+8 xp)", 13, 10, 0
already_fighting:
    db "You're already locked in this fight.", 13, 10, 0
already_fighting_end:
already_fighting_len: equ already_fighting_end - already_fighting
no_target:
    db "There's nothing like that here to attack.", 13, 10, 0
no_target_end:
no_target_len: equ no_target_end - no_target
no_mob:
    db "You don't see that here.", 13, 10, 0
no_mob_end:
no_mob_end_len: equ no_mob_end - no_mob
wield_prose:
    db "You ready shiv.", 13, 10, 0
wield_prose_end:
wield_prose_len: equ wield_prose_end - wield_prose
remove_prose:
    db "You stow shiv.", 13, 10, 0
remove_prose_end:
remove_prose_len: equ remove_prose_end - remove_prose
no_item:
    db "You have nothing like that to wear.", 13, 10, 0
no_item_end:
no_item_len: equ no_item_end - no_item
not_wearing:
    db "You are not wearing that.", 13, 10, 0
not_wearing_end:
not_wearing_len: equ not_wearing_end - not_wearing
rest_prose:
    db "You settle against the cold metal and let your breath slow.", 13, 10, 0
rest_prose_end:
rest_prose_len: equ rest_prose_end - rest_prose
stand_prose:
    db "You get to your feet.", 13, 10, 0
stand_prose_end:
stand_prose_len: equ stand_prose_end - stand_prose
sleep_prose:
    db "You close your eyes, and the dead network leans close and shows you something.", 13, 10, 0
sleep_prose_end:
sleep_prose_len: equ sleep_prose_end - sleep_prose
join_prose:
    db "You take the Front's coin. It is warm, which is worse. You are Cinder Front now, and the wastes will remember which side you chose when choosing was easy.", 13, 10, 0
join_prose_end:
join_prose_len: equ join_prose_end - join_prose
no_oath:
    db "There is no one here to swear to.", 13, 10, 0
no_oath_end:
no_oath_len: equ no_oath_end - no_oath
defend_prose:
    db "You step between the recruiter and the refugees. The recruiter spits and storms off.", 13, 10, 0
defend_prose_end:
defend_prose_len: equ defend_prose_end - defend_prose
no_stand:
    db "There is no stand to take here.", 13, 10, 0
no_stand_end:
no_stand_len: equ no_stand_end - no_stand
fight_block:
    db "Not while you're fighting for your life.", 13, 10, 0
fight_block_end:
fight_block_len: equ fight_block_end - fight_block
exits_fmt: db "Exits: %s", 13, 10, 0
world_prose_fmt: db "The sky: %s, clear.", 13, 10, 0
arg_all: db "all", 0
died_prose:
    db "The wastes take you. Your last sight is the tunnel ceiling, and then the dead network's cold half-light instead.", 13, 10, 0
died_prose_end:
died_prose_len: equ died_prose_end - died_prose
char_died_fmt: db '@event char.died {"respawnRoom":"nexus","hp":%ld,"maxHp":%ld}', 13, 10, 0
vitals_fmt:
    db '@event char.vitals {"hp":%ld,"maxHp":%ld,"level":%ld,"xp":%ld,"gold":%ld,"room":"%s","inCombat":false,"poisoned":false,"position":"%s"}', 13, 10, 0
vitals_combat_fmt:
    db '@event char.vitals {"hp":%ld,"maxHp":%ld,"level":%ld,"xp":%ld,"gold":%ld,"room":"%s","inCombat":true,"poisoned":false,"position":"%s"}', 13, 10, 0
affects_fmt:
    db '@event char.affects {"morality":%ld,"addiction":%ld,"faction":"%s","resisted":false,"race":"%s","ashsworn":%s}', 13, 10, 0
world_state_fmt:
    db '@event world.state {"tick":%ld,"phase":"%s","weather":"clear"}', 13, 10, 0
combat_start_fmt:
    db '@event combat.start {"mob":"rat","name":"luminous rat"}', 13, 10
combat_start_end:
combat_start_len: equ combat_start_end - combat_start_fmt
attack_vitals:
    db '@event char.vitals {"hp":30,"maxHp":30,"level":1,"xp":0,"gold":20,"room":"tunnels","inCombat":true,"poisoned":false,"position":"standing"}', 13, 10
attack_vitals_end:
attack_vitals_len: equ attack_vitals_end - attack_vitals
peace_vitals:
    db '@event char.vitals {"hp":22,"maxHp":30,"level":1,"xp":8,"gold":20,"room":"tunnels","inCombat":false,"poisoned":false,"position":"standing"}', 13, 10
peace_vitals_end:
peace_vitals_len: equ peace_vitals_end - peace_vitals
join_affects:
    db '@event char.affects {"morality":-15,"addiction":0,"faction":"front","resisted":false,"race":"human","ashsworn":false}', 13, 10
join_affects_end:
join_affects_len: equ join_affects_end - join_affects
combat_round_one:
    db '@event combat.round {"mob":"rat","mobHp":4,"mobMaxHp":12,"playerDmg":8,"mobDmg":4,"hp":26}', 13, 10
combat_round_one_end:
combat_round_one_len: equ combat_round_one_end - combat_round_one
combat_round_two:
    db '@event combat.round {"mob":"rat","mobHp":0,"mobMaxHp":12,"playerDmg":8,"mobDmg":0,"hp":26}', 13, 10
combat_round_two_end:
combat_round_two_len: equ combat_round_two_end - combat_round_two
combat_round_fmt:
    db '@event combat.round {"mob":"rat","mobHp":%ld,"mobMaxHp":12,"playerDmg":%ld,"mobDmg":%ld,"hp":%ld}', 13, 10, 0
combat_end_killed:
    db '@event combat.end {"mob":"rat","result":"killed"}', 13, 10
combat_end_killed_end:
combat_end_killed_len: equ combat_end_killed_end - combat_end_killed
combat_end_died:
    db '@event combat.end {"mob":"rat","result":"died"}', 13, 10
combat_end_died_end:
combat_end_died_len: equ combat_end_died_end - combat_end_died
combat_end_gone:
    db '@event combat.end {"mob":"rat","result":"gone"}', 13, 10
combat_end_gone_end:
combat_end_gone_len: equ combat_end_gone_end - combat_end_gone
dream_event:
    db '@event char.dream {"text":"You dream of the wastes seen from above, the dead network laid out like veins.","personal":false}', 13, 10
dream_event_end:
dream_event_len: equ dream_event_end - dream_event
phase_day: db "day", 0
phase_dusk: db "dusk", 0
phase_night: db "night", 0
phase_dawn: db "dawn", 0
phase_table: dq phase_day, phase_dusk, phase_night, phase_dawn

section .text
extern time
extern snprintf
extern strlen
extern strcpy
extern strcasecmp
extern hg_session_queue
extern hg_emit_equipment
extern hg_emit_scene
extern hg_store_save
extern hg_room_id
extern hg_room_exits
extern hg_format_vitals
extern hg_format_combat_round
extern hg_format_world_state
extern hg_format_affects
extern hg_grid_on_kill
extern hg_grid_on_death
extern hg_grid_fmt_listen
extern hg_grid_fmt_ping_echo
extern hg_grid_fmt_ping_all
extern hg_grid_fmt_worlds
extern hg_grid_fmt_travel
extern hg_grid_fmt_whoami

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
global hg_cmd_join
global hg_cmd_defend
global hg_cmd_ping
global hg_cmd_world
global hg_cmd_listen
global hg_cmd_whoami
global hg_cmd_worlds
global hg_cmd_travel
global hg_session_pulse

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
    mov rdi, r15
    call strlen wrt ..plt
    mov rcx, rax
    mov rdi, r12
    mov rsi, r13
    mov rdx, r15
    jmp queue_bytes

; r12=session, r13=wsi throughout command handlers
setup_cmd:
    mov r12, rdi
    mov r13, rsi
    mov [r12 + SESSION_WSI], r13
    ret

; int64 player_damage(session) -- r12=session
player_damage:
    mov eax, 5
    lea rdi, [r12 + SESSION_WEAPON]
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
    sub rsp, 288           ; multiple of 16: keeps rsp aligned for the C call below
    mov r12, rdi
    mov r13, rsi
    mov r15, rsp
    add r15, 40
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
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    lea rdx, [rel peace_vitals]
    mov ecx, peace_vitals_len
    cmp qword [r12 + SESSION_IN_COMBAT], 0
    je .queue
    lea rdx, [rel attack_vitals]
    mov ecx, attack_vitals_len
.queue:
    mov rdi, r12
    mov rsi, r13
    call queue_bytes
    pop r13
    pop r12
    ret

emit_affects:
    push r12
    push r13
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel join_affects]
    mov ecx, join_affects_len
    call queue_bytes
    pop r13
    pop r12
    ret

combat_round:
    push r12
    push r13
    push rax
    mov r12, rdi
    mov r13, rsi
    cmp qword [rel rat_hp], 12
    je .round_one
    cmp qword [rel rat_hp], 4
    je .round_two
    jmp .done
.round_one:
    mov qword [rel rat_hp], 0
    mov qword [rel rat_alive], 0
    sub qword [r12 + SESSION_HP], 4
    xor edi, edi
    call time wrt ..plt
    imul rax, rax, 1000
    mov [rel rat_died_at], rax
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel combat_round_one]
    mov ecx, combat_round_one_len
    call queue_bytes
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel combat_round_two]
    mov ecx, combat_round_two_len
    call queue_bytes
    mov qword [r12 + SESSION_IN_COMBAT], 0
    add qword [r12 + SESSION_XP], 8
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel combat_end_killed]
    mov ecx, combat_end_killed_len
    call queue_bytes
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel peace_vitals]
    mov ecx, peace_vitals_len
    call queue_bytes
    call kill_hub_record
    cmp qword [r12 + SESSION_HP], 0
    jg .round_one_ret
    call player_died
.round_one_ret:
    pop rax
    pop r13
    pop r12
    ret
.round_two:
    mov qword [rel rat_hp], 0
    mov qword [rel rat_alive], 0
    xor edi, edi
    call time wrt ..plt
    imul rax, rax, 1000
    mov [rel rat_died_at], rax
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel combat_round_two]
    mov ecx, combat_round_two_len
    call queue_bytes
    mov qword [r12 + SESSION_IN_COMBAT], 0
    add qword [r12 + SESSION_XP], 8
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel combat_end_killed]
    mov ecx, combat_end_killed_len
    call queue_bytes
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel peace_vitals]
    mov ecx, peace_vitals_len
    call queue_bytes
    call kill_hub_record
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel kill_prose_fmt]
    call queue_cstring
    mov rdi, r12
    call hg_store_save
.done:
    pop rax
    pop r13
    pop r12
    ret

; r12=session (preserved by both callees per SysV ABI). Best-effort hub
; record + local echo for a rat kill; never touches session state.
; sub rsp,8 restores 16-byte stack alignment before calling into C (this is
; called mid-expression from combat_round with an already-8-mod-16 rsp).
kill_hub_record:
    sub rsp, 8
    mov rdi, [r12 + SESSION_ROOM]
    call hg_room_id
    mov rdi, rax
    lea rsi, [r12 + SESSION_NAME]
    lea rdx, [rel mob_luminous]
    call hg_grid_on_kill wrt ..plt
    add rsp, 8
    ret

; r12=session, r13=wsi. Defensive death path: current damage numbers never
; drive HP to 0, so this is unreached in practice, but wired for when combat
; balance changes. Records the fall, respawns to the nexus, and queues
; prose + char.died.
player_died:
    push r14
    sub rsp, 512
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
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel died_prose]
    mov ecx, died_prose_len
    call queue_bytes
    mov rdi, r14
    mov esi, 240
    lea rdx, [rel char_died_fmt]
    mov rcx, [r12 + SESSION_HP]
    mov r8, [r12 + SESSION_MAX_HP]
    xor eax, eax
    call snprintf wrt ..plt
    mov rdi, r12
    mov rsi, r13
    mov rdx, r14
    mov ecx, eax
    call queue_bytes
    add rsp, 512
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
    jne .combat
    mov rdi, r12
    mov rsi, r13
    call emit_world_state
    jmp .rest_check
.combat:
    mov rdi, r12
    mov rsi, r13
    call combat_round
    jmp .done
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
    mov r12, rdi
    mov r13, rsi
    mov [r12 + SESSION_WSI], r13
    mov rbx, rdx
    cmp qword [r12 + SESSION_IN_COMBAT], 0
    je .done
    mov rax, [r12 + SESSION_LAST_TICK]
    test rax, rax
    jz .due
    mov rcx, HG_HEARTBEAT_MS
    add rax, rcx
    cmp rbx, rax
    jb .done
.due:
    mov [r12 + SESSION_LAST_TICK], rbx
    mov rdi, r12
    mov rsi, r13
    call combat_round
.done:
    pop r13
    pop r12
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
    jne .empty
    cmp qword [rel rat_alive], 0
    je .empty
    lea rax, [rel rat_live_mobs]
    ret
.empty:
    lea rax, [rel empty_mobs]
    ret

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
    push r15
    mov [rel heartbeat_now_ms], rdi
    mov r12, rdi
    lea r15, [rel session_table]
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
    pop r15
    pop r12
    pop rbx
    ret

hg_cmd_wield:
    call setup_cmd
    lea rdi, [r12 + SESSION_WEAPON]
    lea rsi, [rel item_shiv]
    call strcpy wrt ..plt
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel wield_prose]
    mov ecx, wield_prose_len
    call queue_bytes
    mov rdi, r12
    mov rsi, r13
    jmp hg_emit_equipment

hg_cmd_remove:
    call setup_cmd
    lea rdi, [r12 + SESSION_WEAPON]
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
    jmp hg_emit_equipment
.not_wearing:
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel not_wearing]
    mov ecx, not_wearing_len
    jmp queue_bytes

hg_cmd_attack:
    call setup_cmd
    cmp qword [r12 + SESSION_IN_COMBAT], 0
    jne .already
    cmp qword [r12 + SESSION_ROOM], ROOM_TUNNELS
    jne .no_target
    cmp qword [rel rat_alive], 0
    je .no_target
    mov rdi, rdx
    lea rsi, [rel mob_rat]
    call strcasecmp wrt ..plt
    test eax, eax
    jnz .no_target
    mov qword [r12 + SESSION_IN_COMBAT], 1
    lea rdi, [r12 + SESSION_TARGET]
    lea rsi, [rel mob_rat]
    call strcpy wrt ..plt
    lea rdi, [r12 + SESSION_POSITION]
    lea rsi, [rel position_standing]
    call strcpy wrt ..plt
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel combat_start_fmt]
    mov ecx, combat_start_len
    call queue_bytes
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel attack_prose]
    mov ecx, attack_prose_len
    call queue_bytes
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel attack_vitals]
    mov ecx, attack_vitals_len
    call queue_bytes
    mov qword [r12 + SESSION_LAST_TICK], 0
    mov qword [rel last_heartbeat_ms], 0
    ret
.already:
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel already_fighting]
    mov ecx, already_fighting_len
    jmp queue_bytes
.no_target:
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel no_target]
    mov ecx, no_target_len
    jmp queue_bytes

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
    cmp qword [r12 + SESSION_IN_COMBAT], 0
    je .ok
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel fight_block]
    mov ecx, fight_block_len
    jmp queue_bytes
.ok:
    lea rdi, [r12 + SESSION_POSITION]
    lea rsi, [rel position_resting]
    call strcpy wrt ..plt
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel rest_prose]
    mov ecx, rest_prose_len
    call queue_bytes
    mov rdi, r12
    mov rsi, r13
    jmp hg_emit_vitals

hg_cmd_stand:
    call setup_cmd
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
    jmp hg_emit_vitals

hg_cmd_sleep:
    call setup_cmd
    cmp qword [r12 + SESSION_IN_COMBAT], 0
    je .ok
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel fight_block]
    mov ecx, fight_block_len
    jmp queue_bytes
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
    mov rsi, r13
    lea rdx, [rel dream_event]
    mov ecx, dream_event_len
    call queue_bytes
    mov rdi, r12
    mov rsi, r13
    jmp hg_emit_vitals

hg_cmd_join:
    call setup_cmd
    cmp qword [r12 + SESSION_ROOM], ROOM_MARKET
    jne .no_oath
    cmp byte [rel market_resolved], 0
    jne .no_oath
    mov byte [rel market_resolved], 1
    lea rdi, [r12 + SESSION_FACTION]
    lea rsi, [rel faction_front]
    call strcpy wrt ..plt
    sub qword [r12 + SESSION_MORALITY], 15
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel join_prose]
    mov ecx, join_prose_len
    call queue_bytes
    call emit_affects
    mov rdi, r12
    mov rsi, r13
    jmp hg_emit_vitals
.no_oath:
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel no_oath]
    mov ecx, no_oath_len
    jmp queue_bytes

hg_cmd_defend:
    call setup_cmd
    cmp qword [r12 + SESSION_ROOM], ROOM_MARKET
    jne .no_stand
    cmp byte [rel market_resolved], 0
    jne .no_stand
    mov byte [rel market_resolved], 2
    lea rdi, [r12 + SESSION_FACTION]
    lea rsi, [rel faction_ally]
    call strcpy wrt ..plt
    add qword [r12 + SESSION_MORALITY], 25
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel defend_prose]
    mov ecx, defend_prose_len
    call queue_bytes
    call emit_affects
    mov rdi, r12
    mov rsi, r13
    jmp hg_emit_vitals
.no_stand:
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel no_stand]
    mov ecx, no_stand_len
    jmp queue_bytes

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

; travel / gate (rdx=target, or NULL to just list worlds): shows the
; destination and its reconnect URL. No mid-session handoff yet (Phase 3
; only lists destinations; see docs/PLAN.md).
hg_cmd_travel:
    call setup_cmd
    push r14
    mov r14, rdx
    sub rsp, 3072
    mov rdi, rsp
    mov esi, 3072
    mov rdx, r14
    call hg_grid_fmt_travel wrt ..plt
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
