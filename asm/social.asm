default rel
%include "state.inc"

section .rodata
faction_front: db "front", 0
faction_ally: db "ally", 0
item_dust: db "dust", 0
item_helm: db "helm", 0
item_plating: db "plating", 0
item_rebar: db "rebar", 0
pretty_helm: db "a dented scrap helm", 0
pretty_plating: db "makeshift plating", 0
pretty_rebar: db "a length of rebar", 0
word_to: db "to", 0
world_basalt: db "Basalt Relay", 0

sell_cant_here:
    db "You can't do that here.", 0
sell_front_refuse:
    db "The vendor drone's optic flares red. ", 34
    db "Cinder Front. We remember Scrap Market. We don't trade with your kind.", 34
    db " It turns its back on you, and the stalls nearby go quiet.", 0
sell_what: db "Sell what?", 0
sell_not_carrying_fmt:
    db "You aren't carrying ", 34, "%s", 34, ".", 0

list_not_here: db "There is nothing listed for sale here.", 0
list_workshop:
    db "The tinker's wares, laid out on an oily cloth:", 13, 10
    db "  helm (14 gold)", 13, 10
    db "  plating (18 gold)", 13, 10
    db "  rebar (20 gold)", 13, 10, 0

talk_tavern:
    db "The dealer rolls a packet of dust between his fingers: ", 34
    db "First taste eases any pain, friend. Just say buy dust.", 34, 13, 10
    db "(You could buy/use dust, carouse, or resist.)", 13, 10, 0
talk_floodgate:
    db "A stranded operator looks up from a dead console: ", 34
    db "I can't leave until this node is restored, and the Custodian dragged the core shard down "
    db "into the Core Lab. Kill it, bring me the shard, and I'll give you everything I have.", 34, 13, 10, 0
talk_way_front:
    db "The free folk look at your Front brand and go quiet. There "
    db "is no welcome here for your kind.", 0
talk_way_ally:
    db "A medic nods: ", 34
    db "The free folk hold. Rest if you need it (treat).", 34, 0
talk_way_neutral:
    db "A refugee looks you over: ", 34
    db "Pick a side before you ask us for shelter. The free folk or the Front -- the road doesn't care, but "
    db "we do.", 34, 13, 10, 0
talk_dais_front:
    db "The Ashmonger claps a heavy hand on your shoulder. ", 34
    db "You came far for the cause. Kneel and take your place at my right hand -- or find "
    db "your spine and 'defy' me, here and now. Choose what you are.", 34, 13, 10, 0
talk_dais_ally:
    db "The Ashmonger laughs, low and delighted. ", 34
    db "The elf-lover walked right into my house. Bold. I am going to wear you as a banner.", 34, " "
    db "There is no talking your way out of this -- only steel.", 13, 10, 0
talk_dais_neutral:
    db "The Ashmonger spits. ", 34
    db "Pledge to the Front or get off my dais. I have no patience for fence-sitters.", 34, 13, 10, 0
talk_none: db "There's no one here to talk to.", 0

buy_dust_only:
    db "The dealer only deals one thing: dust. (", 34, "buy dust", 34, ")", 0
buy_short_gold:
    db "The dealer sneers. ", 34, "10 gold, no credit.", 34, " You're short.", 0
buy_dust_fmt:
    db "The dealer slips you a packet of dust. (-10 gold, gold: %lld)", 0
buy_nothing: db "There is nothing to buy here.", 0
buy_no_item: db "The tinker doesn't sell that.", 0
buy_cant_afford_fmt:
    db "You can't afford that -- it is %d gold and you have %lld.", 0
buy_hand_fmt: db "The tinker hands you %s and pockets your coin.", 0

wall_not_admin:
    db "Only a keeper of the Grid can broadcast across the wastes.", 0
wall_need: db "Announce what?  (wall <message>)", 0
wall_banner_fmt: db "*** GRID BROADCAST ***  %s", 13, 10, 0
wall_evt_fmt:
    db "@event server.announce {", 34, "from", 34, ":", 34, "%s", 34, ","
    db 34, "text", 34, ":", 34, "%s", 34, "}", 13, 10, 0

tell_need: db "Tell whom what?  (tell <player> <message>)", 0
tell_no_one: db "No one by that name is connected.", 0
tell_you_fmt:
    db "%s tells you, ", 34, "%s", 34, 13, 10, 0
tell_evt_fmt:
    db "@event comm.tell {", 34, "from", 34, ":", 34, "%s", 34, ","
    db 34, "text", 34, ":", 34, "%s", 34, "}", 13, 10, 0
tell_self_fmt:
    db "You tell %s, ", 34, "%s", 34, 0

reply_none: db "No one has told you anything lately.", 0

yell_need: db "Yell what?  (yell <message>)", 0
yell_you_fmt:
    db "You yell, ", 34, "%s", 34, 13, 10, 0
yell_other_fmt:
    db "%s yells, ", 34, "%s", 34, 13, 10, 0
yell_evt_fmt:
    db "@event comm.yell {", 34, "from", 34, ":", 34, "%s", 34, ","
    db 34, "text", 34, ":", 34, "%s", 34, "}", 13, 10, 0

emote_need: db "Emote what?  (emote <action>)", 0
emote_fmt: db "%s %s", 13, 10, 0

mend_none: db "There's no one like that here to mend.", 0
mend_whole_fmt: db "%s is already whole.", 0
mend_no_hp: db "You don't have enough life left to spare.", 0
mend_you_fmt: db "You spend a little of yourself to mend %s.", 0
mend_target_fmt: db "%s tends your wounds.", 13, 10, 0

give_need: db "Give what to whom?  (give <item> <player>)", 0
give_not_carry_fmt:
    db "You aren't carrying ", 34, "%s", 34, ".", 0
give_no_target_fmt:
    db "There's no one called ", 34, "%s", 34, " here to give it to.", 0
give_you_fmt: db "You give %s to %s.", 0
give_target_fmt: db "%s gives you %s.", 13, 10, 0

treat_no_medic:
    db "There's no medic here. The free folk keep their triage cot "
    db "at the waystation, off the Scorch Road.", 0
treat_in_combat: db "Not in the middle of a fight.", 0
treat_branded:
    db "The waystation medic looks at your brand and turns their "
    db "back. There is no care to be had here for your kind.", 0
treat_whole:
    db "The medic looks you over and waves you off. ", 34
    db "You're whole. Save the cot for someone who isn't.", 34, 13, 10, 0
treat_whole_evt:
    db "@event char.treated {", 34, "amount", 34, ":0,", 34, "mood", 34, ":", 34
    db "rising", 34, ",", 34, "tide", 34, ":0}", 13, 10, 0
treat_done:
    db "The medic waves you onto the cot. With the free folk holding, the "
    db "waystation has supplies to spare -- they clean and bind your wounds "
    db "without a word about payment. You stand whole again.", 13, 10, 0
treat_evt_fmt:
    db "@event char.treated {", 34, "amount", 34, ":%lld,", 34, "mood", 34, ":", 34
    db "rising", 34, ",", 34, "tide", 34, ":0}", 13, 10, 0

war_prose_fmt:
    db "Across the whole Grid, the war for the wastes hangs in the balance "
    db "(tide %+d).", 0
war_evt_fmt:
    db "@event world.war {", 34, "tide", 34, ":%d}", 13, 10, 0

section .text
extern snprintf
extern strlen
extern strcpy
extern strncpy
extern strcasecmp
extern strncasecmp
extern strcmp
extern strstr
extern memcpy
extern memset
extern hg_queue_line
extern hg_queue_cstr
extern hg_deliver_room
extern hg_deliver_all
extern hg_json_escape
extern hg_is_admin
extern hg_emit_room_actions_now
extern hg_emit_vitals_now
extern hg_store_save
extern hg_room_id_cstr
extern hg_grid_tide
extern hg_session_at

global hg_inv_add_item
global find_player_prefix
global inv_add_internal
global inv_find_slot
global setup_cmd
global queue_line_h
global queue_cstr_h
global skip_spaces

; r12=session, r13=wsi
setup_cmd:
    mov r12, rdi
    mov r13, rsi
    mov [r12 + SESSION_WSI], r13
    ret

; rdi=session, rsi=msg
queue_line_h:
    jmp hg_queue_line wrt ..plt

; rdi=session, rsi=cstr
queue_cstr_h:
    jmp hg_queue_cstr wrt ..plt

; rdi=cstr -> rax=ptr after leading spaces
skip_spaces:
    mov rax, rdi
.sp:
    movzx ecx, byte [rax]
    test cl, cl
    jz .done
    cmp cl, " "
    jne .done
    inc rax
    jmp .sp
.done:
    ret

; r12=session
emit_vitals_here:
    mov rdi, [r12 + SESSION_ROOM]
    call hg_room_id_cstr wrt ..plt
    mov rsi, rax
    mov rdi, r12
    jmp hg_emit_vitals_now wrt ..plt

; rdi=room, rsi=prefix, rdx=except (may be null)
; returns rax=session or null (null also if ambiguous)
; Keep found/current session on the stack: C calls clobber r10/r11.
find_player_prefix:
    push rbx
    push r12
    push r13
    push r14
    push r15
    ; 5 pushes leave rsp 0-mod-16; keep that for System V calls.
    sub rsp, 16
    mov r12, rdi                      ; room
    mov r13, rsi                      ; prefix
    mov r14, rdx                      ; except
    mov qword [rsp], 0                ; found
    mov qword [rsp + 8], 0            ; current
    test r13, r13
    jz .none
    cmp byte [r13], 0
    je .none
    mov rdi, r13
    call strlen wrt ..plt
    mov r15, rax                      ; prefix len
    xor ebx, ebx
.loop:
    cmp ebx, HG_MAX_SESSIONS
    jge .ret_found
    mov edi, ebx
    call hg_session_at wrt ..plt
    test rax, rax
    jz .next
    mov [rsp + 8], rax
    cmp r12, 0
    jl .name_ok
    cmp qword [rax + SESSION_ROOM], r12
    jne .next
.name_ok:
    mov rax, [rsp + 8]
    lea rdi, [rax + SESSION_NAME]
    cmp byte [rdi], 0
    je .next
    test r14, r14
    jz .no_except
    mov rsi, r14
    call strcasecmp wrt ..plt
    test eax, eax
    jz .next
.no_except:
    mov rax, [rsp + 8]
    lea rdi, [rax + SESSION_NAME]
    mov rsi, r13
    mov rdx, r15
    call strncasecmp wrt ..plt
    test eax, eax
    jnz .next
    cmp qword [rsp], 0
    jne .none
    mov rax, [rsp + 8]
    mov [rsp], rax
.next:
    inc ebx
    jmp .loop
.ret_found:
    mov rax, [rsp]
    jmp .out
.none:
    xor eax, eax
.out:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; rdi=session, rsi=item id -> eax=0 ok, -1 fail
inv_add_internal:
    mov r8, rdi
    mov r9, rsi
    test r9, r9
    jz .fail
    cmp byte [r9], 0
    je .fail
    mov rax, [r8 + SESSION_INV_COUNT]
    cmp rax, 0
    jl .fail
    cmp rax, SESSION_INV_SLOTS
    jge .fail
    imul rcx, rax, SESSION_INV_SLOT_SIZE
    lea rdi, [r8 + SESSION_INVENTORY + rcx]
    mov rsi, r9
    mov edx, SESSION_INV_SLOT_SIZE
    call strncpy wrt ..plt
    mov byte [rdi + SESSION_INV_SLOT_SIZE - 1], 0
    inc qword [r8 + SESSION_INV_COUNT]
    xor eax, eax
    ret
.fail:
    mov eax, -1
    ret

global hg_inv_add_item
hg_inv_add_item:
    jmp inv_add_internal

; rdi=session, rsi=arg -> eax=slot index or -1
inv_find_slot:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov r12, rdi
    mov r13, rsi
    test r13, r13
    jz .if_miss
    cmp byte [r13], 0
    je .if_miss
    xor ebx, ebx
    mov rax, [r12 + SESSION_INV_COUNT]
    mov r14, rax
.if_loop:
    cmp rbx, r14
    jge .if_miss
    imul rcx, rbx, SESSION_INV_SLOT_SIZE
    lea rdi, [r12 + SESSION_INVENTORY + rcx]
    mov rsi, r13
    call strcasecmp wrt ..plt
    test eax, eax
    jz .if_found
    mov rdi, r13
    call strlen wrt ..plt
    mov rdx, rax
    lea rdi, [r12 + SESSION_INVENTORY + rcx]
    mov rsi, r13
    call strncasecmp wrt ..plt
    test eax, eax
    jz .if_found
    inc rbx
    jmp .if_loop
.if_found:
    mov eax, ebx
    jmp .if_out
.if_miss:
    mov eax, -1
.if_out:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; rdi=session, esi=slot index -> eax=0 ok
inv_remove_slot:
    push r12
    push r13
    push r14
    mov r12, rdi
    movsxd r13, esi
    mov rax, [r12 + SESSION_INV_COUNT]
    cmp r13, 0
    jl .fail
    cmp r13, rax
    jge .fail
    lea r14, [r12 + SESSION_INVENTORY]
    mov rcx, rax
    sub rcx, r13
    dec rcx
    jz .last
    imul r8, r13, SESSION_INV_SLOT_SIZE
    lea rdi, [r14 + r8]
    lea rsi, [r14 + r8 + SESSION_INV_SLOT_SIZE]
    mov edx, SESSION_INV_SLOT_SIZE
    imul edx, ecx
    call memcpy wrt ..plt
.last:
    dec qword [r12 + SESSION_INV_COUNT]
    mov rax, [r12 + SESSION_INV_COUNT]
    imul rcx, rax, SESSION_INV_SLOT_SIZE
    lea rdi, [r14 + rcx]
    mov edx, SESSION_INV_SLOT_SIZE
    xor esi, esi
    call memset wrt ..plt
    xor eax, eax
    jmp .out
.fail:
    mov eax, -1
.out:
    pop r14
    pop r13
    pop r12
    ret

global hg_find_session_name
hg_find_session_name:
    push rbx
    push r12
    push r13
    mov r12, rdi
    test r12, r12
    jz .fsn_none
    cmp byte [r12], 0
    je .fsn_none
    xor ebx, ebx
.fsn_loop:
    cmp ebx, HG_MAX_SESSIONS
    jge .fsn_none
    mov edi, ebx
    call hg_session_at wrt ..plt
    test rax, rax
    jz .fsn_next
    mov r13, rax
    lea rdi, [r13 + SESSION_NAME]
    mov rsi, r12
    call strcasecmp wrt ..plt
    test eax, eax
    jz .fsn_found
.fsn_next:
    inc ebx
    jmp .fsn_loop
.fsn_found:
    mov rax, r13
    jmp .fsn_out
.fsn_none:
    xor rax, rax
.fsn_out:
    pop r13
    pop r12
    pop rbx
    ret

; --- command handlers: rdi=session, rsi=wsi, rdx=arg ---

global hg_cmd_sense
hg_cmd_sense:
    call setup_cmd
    mov rdi, r12
    jmp hg_emit_room_actions_now wrt ..plt

global hg_cmd_list
hg_cmd_list:
    call setup_cmd
    cmp qword [r12 + SESSION_ROOM], ROOM_WORKSHOP
    jne .bad
    mov rdi, r12
    lea rsi, [rel list_workshop]
    jmp queue_cstr_h
.bad:
    mov rdi, r12
    lea rsi, [rel list_not_here]
    jmp queue_line_h

global hg_cmd_sell
hg_cmd_sell:
    call setup_cmd
    push r14
    mov r14, rdx
    cmp qword [r12 + SESSION_ROOM], ROOM_MARKET
    jne .cant
    lea rdi, [r12 + SESSION_FACTION]
    lea rsi, [rel faction_front]
    call strcmp wrt ..plt
    test eax, eax
    jnz .arg
    mov rdi, r12
    lea rsi, [rel sell_front_refuse]
    call queue_line_h
    jmp .out
.cant:
    mov rdi, r12
    lea rsi, [rel sell_cant_here]
    call queue_line_h
    jmp .out
.arg:
    test r14, r14
    jz .what
    cmp byte [r14], 0
    je .what
    sub rsp, 168
    mov rdi, rsp
    mov esi, 160
    lea rdx, [rel sell_not_carrying_fmt]
    mov rcx, r14
    xor eax, eax
    call snprintf wrt ..plt
    mov rdi, r12
    mov rsi, rsp
    call queue_line_h
    add rsp, 168
    jmp .out
.what:
    mov rdi, r12
    lea rsi, [rel sell_what]
    call queue_line_h
.out:
    pop r14
    ret

global hg_cmd_talk
hg_cmd_talk:
    call setup_cmd
    mov rax, [r12 + SESSION_ROOM]
    cmp rax, ROOM_TAVERN
    je .tavern
    cmp rax, ROOM_FLOODGATE
    je .flood
    cmp rax, ROOM_WAYSTATION
    je .way
    cmp rax, ROOM_DAIS
    je .dais
    mov rdi, r12
    lea rsi, [rel talk_none]
    jmp queue_line_h
.tavern:
    mov rdi, r12
    lea rsi, [rel talk_tavern]
    jmp queue_cstr_h
.flood:
    mov rdi, r12
    lea rsi, [rel talk_floodgate]
    jmp queue_cstr_h
.way:
    lea rdi, [r12 + SESSION_FACTION]
    lea rsi, [rel faction_front]
    call strcmp wrt ..plt
    jz .way_front
    lea rdi, [r12 + SESSION_FACTION]
    lea rsi, [rel faction_ally]
    call strcmp wrt ..plt
    jz .way_ally
    mov rdi, r12
    lea rsi, [rel talk_way_neutral]
    jmp queue_cstr_h
.way_front:
    mov rdi, r12
    lea rsi, [rel talk_way_front]
    jmp queue_line_h
.way_ally:
    mov rdi, r12
    lea rsi, [rel talk_way_ally]
    jmp queue_line_h
.dais:
    cmp qword [r12 + SESSION_ASHSWORN], 0
    jnz .dais_front
    lea rdi, [r12 + SESSION_FACTION]
    lea rsi, [rel faction_front]
    call strcmp wrt ..plt
    jz .dais_front
    lea rdi, [r12 + SESSION_FACTION]
    lea rsi, [rel faction_ally]
    call strcmp wrt ..plt
    jz .dais_ally
    mov rdi, r12
    lea rsi, [rel talk_dais_neutral]
    jmp queue_cstr_h
.dais_front:
    mov rdi, r12
    lea rsi, [rel talk_dais_front]
    jmp queue_cstr_h
.dais_ally:
    mov rdi, r12
    lea rsi, [rel talk_dais_ally]
    jmp queue_cstr_h

; internal: r12=session, r13=arg
buy_workshop:
    push r14
    push r15
    mov r15, r13
    test r15, r15
    jnz .skip
    lea r15, [rel empty_str]
.skip:
    mov rdi, r15
    call skip_spaces
    mov r15, rax
    lea rdi, [rel item_helm]
    mov rsi, r15
    call strcasecmp wrt ..plt
    jz .helm
    lea rdi, [rel item_plating]
    mov rsi, r15
    call strcasecmp wrt ..plt
    jz .plating
    lea rdi, [rel item_rebar]
    mov rsi, r15
    call strcasecmp wrt ..plt
    jz .rebar
    mov rdi, r12
    lea rsi, [rel buy_no_item]
    call queue_line_h
    jmp .out
.helm:
    mov r14d, 14
    lea r15, [rel item_helm]
    lea r13, [rel pretty_helm]
    jmp .pay
.plating:
    mov r14d, 18
    lea r15, [rel item_plating]
    lea r13, [rel pretty_plating]
    jmp .pay
.rebar:
    mov r14d, 20
    lea r15, [rel item_rebar]
    lea r13, [rel pretty_rebar]
.pay:
    mov rax, [r12 + SESSION_GOLD]
    cmp rax, r14
    jl .poor
    sub rax, r14
    mov [r12 + SESSION_GOLD], rax
    mov rdi, r12
    mov rsi, r15
    call inv_add_internal
    mov rdi, r12
    call hg_store_save wrt ..plt
    sub rsp, 168
    mov rdi, rsp
    mov esi, 160
    lea rdx, [rel buy_hand_fmt]
    mov rcx, r13
    xor eax, eax
    call snprintf wrt ..plt
    mov rdi, r12
    mov rsi, rsp
    call queue_line_h
    add rsp, 168
    call emit_vitals_here
    jmp .out
.poor:
    sub rsp, 168
    mov rdi, rsp
    mov esi, 160
    lea rdx, [rel buy_cant_afford_fmt]
    mov ecx, r14d
    mov r8, [r12 + SESSION_GOLD]
    xor eax, eax
    call snprintf wrt ..plt
    mov rdi, r12
    mov rsi, rsp
    call queue_line_h
    add rsp, 168
.out:
    pop r15
    pop r14
    ret

empty_str: db 0

global hg_cmd_buy
hg_cmd_buy:
    call setup_cmd
    push r14
    mov r14, rdx
    mov rax, [r12 + SESSION_ROOM]
    cmp rax, ROOM_TAVERN
    jne .workshop
    test r14, r14
    jz .dust_only
    lea rdi, [rel item_dust]
    mov rsi, r14
    call strstr wrt ..plt
    test rax, rax
    jz .dust_only
    mov rax, [r12 + SESSION_GOLD]
    cmp rax, 10
    jl .short
    sub rax, 10
    mov [r12 + SESSION_GOLD], rax
    mov rdi, r12
    lea rsi, [rel item_dust]
    call inv_add_internal
    mov rdi, r12
    call hg_store_save wrt ..plt
    sub rsp, 168
    mov rdi, rsp
    mov esi, 160
    lea rdx, [rel buy_dust_fmt]
    mov rcx, [r12 + SESSION_GOLD]
    xor eax, eax
    call snprintf wrt ..plt
    mov rdi, r12
    mov rsi, rsp
    call queue_line_h
    add rsp, 168
    call emit_vitals_here
    jmp .out
.dust_only:
    mov rdi, r12
    lea rsi, [rel buy_dust_only]
    call queue_line_h
    jmp .out
.short:
    mov rdi, r12
    lea rsi, [rel buy_short_gold]
    call queue_line_h
    jmp .out
.workshop:
    cmp rax, ROOM_WORKSHOP
    jne .nothing
    mov r13, r14
    call buy_workshop
    jmp .out
.nothing:
    mov rdi, r12
    lea rsi, [rel buy_nothing]
    call queue_line_h
.out:
    pop r14
    ret

global hg_cmd_emote
hg_cmd_emote:
    call setup_cmd
    push r14
    mov r14, rdx
    test r14, r14
    jz .need
    mov rdi, r14
    call skip_spaces
    mov r14, rax
    cmp byte [r14], 0
    je .need
    sub rsp, 296
    mov rdi, rsp
    mov esi, 280
    lea rdx, [rel emote_fmt]
    lea rcx, [r12 + SESSION_NAME]
    mov r8, r14
    xor eax, eax
    call snprintf wrt ..plt
    mov rdi, [r12 + SESSION_ROOM]
    mov rsi, rsp
    xor rdx, rdx
    call hg_deliver_room wrt ..plt
    add rsp, 296
    jmp .out
.need:
    mov rdi, r12
    lea rsi, [rel emote_need]
    call queue_line_h
.out:
    pop r14
    ret

global hg_cmd_war
hg_cmd_war:
    call setup_cmd
    sub rsp, 168
    lea rdi, [rsp + 120]
    call hg_grid_tide wrt ..plt
    movsxd r14, dword [rsp + 120]
    mov rdi, rsp
    mov esi, 120
    lea rdx, [rel war_prose_fmt]
    mov ecx, r14d
    xor eax, eax
    call snprintf wrt ..plt
    mov rdi, r12
    mov rsi, rsp
    call queue_line_h
    lea rdi, [rsp + 120]
    mov esi, 80
    lea rdx, [rel war_evt_fmt]
    mov ecx, r14d
    xor eax, eax
    call snprintf wrt ..plt
    mov rdi, r12
    lea rsi, [rsp + 120]
    call queue_cstr_h
    add rsp, 168
    ret

global hg_cmd_treat
hg_cmd_treat:
    call setup_cmd
    cmp qword [r12 + SESSION_ROOM], ROOM_WAYSTATION
    jne .no_medic
    cmp qword [r12 + SESSION_IN_COMBAT], 0
    jnz .fight
    lea rdi, [r12 + SESSION_FACTION]
    lea rsi, [rel faction_front]
    call strcmp wrt ..plt
    jz .branded
    cmp qword [r12 + SESSION_ASHSWORN], 0
    jnz .branded
    mov rax, [r12 + SESSION_HP]
    mov rcx, [r12 + SESSION_MAX_HP]
    cmp rax, rcx
    jge .whole
    mov r14, rax
    mov [r12 + SESSION_HP], rcx
    mov rdi, r12
    call hg_store_save wrt ..plt
    mov rdi, r12
    lea rsi, [rel treat_done]
    call queue_cstr_h
    sub rsp, 168
    mov rdi, rsp
    mov esi, 160
    lea rdx, [rel treat_evt_fmt]
    mov rcx, [r12 + SESSION_MAX_HP]
    sub rcx, r14
    xor eax, eax
    call snprintf wrt ..plt
    mov rdi, r12
    mov rsi, rsp
    call queue_cstr_h
    add rsp, 168
    call emit_vitals_here
    ret
.whole:
    mov rdi, r12
    lea rsi, [rel treat_whole]
    call queue_cstr_h
    mov rdi, r12
    lea rsi, [rel treat_whole_evt]
    jmp queue_cstr_h
.branded:
    mov rdi, r12
    lea rsi, [rel treat_branded]
    jmp queue_line_h
.fight:
    mov rdi, r12
    lea rsi, [rel treat_in_combat]
    jmp queue_line_h
.no_medic:
    mov rdi, r12
    lea rsi, [rel treat_no_medic]
    jmp queue_line_h

global hg_cmd_mend
hg_cmd_mend:
    call setup_cmd
    push r14
    push r15
    mov r14, rdx
    test r14, r14
    jnz .skip_arg
    lea r14, [rel empty_str]
.skip_arg:
    mov rdi, r14
    call skip_spaces
    mov r14, rax
    mov rdi, [r12 + SESSION_ROOM]
    mov rsi, r14
    lea rdx, [r12 + SESSION_NAME]
    call find_player_prefix
    test rax, rax
    jz .none
    mov r15, rax
    mov rax, [r15 + SESSION_HP]
    cmp rax, [r15 + SESSION_MAX_HP]
    jge .whole
    mov rax, [r12 + SESSION_HP]
    cmp rax, 5
    jle .no_hp
    sub rax, 5
    mov [r12 + SESSION_HP], rax
    mov rax, [r15 + SESSION_HP]
    add rax, 10
    mov rcx, [r15 + SESSION_MAX_HP]
    cmp rax, rcx
    jle .hp_ok
    mov rax, rcx
.hp_ok:
    mov [r15 + SESSION_HP], rax
    sub rsp, 168
    mov rdi, rsp
    mov esi, 160
    lea rdx, [rel mend_you_fmt]
    lea rcx, [r15 + SESSION_NAME]
    xor eax, eax
    call snprintf wrt ..plt
    mov rdi, r12
    mov rsi, rsp
    call queue_line_h
    mov rdi, rsp
    mov esi, 160
    lea rdx, [rel mend_target_fmt]
    lea rcx, [r12 + SESSION_NAME]
    xor eax, eax
    call snprintf wrt ..plt
    mov rdi, r15
    mov rsi, rsp
    call queue_cstr_h
    add rsp, 168
    call emit_vitals_here
    jmp .out
.whole:
    sub rsp, 168
    mov rdi, rsp
    mov esi, 160
    lea rdx, [rel mend_whole_fmt]
    lea rcx, [r15 + SESSION_NAME]
    xor eax, eax
    call snprintf wrt ..plt
    mov rdi, r12
    mov rsi, rsp
    call queue_line_h
    add rsp, 168
    jmp .out
.no_hp:
    mov rdi, r12
    lea rsi, [rel mend_no_hp]
    call queue_line_h
    jmp .out
.none:
    mov rdi, r12
    lea rsi, [rel mend_none]
    call queue_line_h
.out:
    pop r15
    pop r14
    ret

global hg_cmd_give
hg_cmd_give:
    call setup_cmd
    push rbx
    push r14
    push r15
    sub rsp, 280
    mov r14, rdx
    test r14, r14
    jnz .have_arg
    lea r14, [rel empty_str]
.have_arg:
    mov rdi, r14
    call skip_spaces
    mov r14, rax
    cmp byte [r14], 0
    je .need
    mov rdi, rsp
    mov esi, 200
    mov rdx, r14
    call strcpy wrt ..plt
    ; tokenize into rsp+200.., last token is player
    lea r15, [rsp + 200]
    xor ebx, ebx
    mov byte [rsp], 0
    mov rdi, rsp
    movzx eax, byte [rdi]
    test al, al
    jz .need
.tok:
    cmp ebx, 16
    jge .need
    mov [r15 + rbx * 8], rdi
    inc ebx
.scan:
    movzx eax, byte [rdi]
    test al, al
    jz .done_tok
    cmp al, " "
    je .term
    cmp al, 9
    je .term
    inc rdi
    jmp .scan
.term:
    mov byte [rdi], 0
    inc rdi
    movzx eax, byte [rdi]
    test al, al
    jz .done_tok
    cmp al, " "
    je .skip_ws
    cmp al, 9
    je .skip_ws
    jmp .tok
.skip_ws:
    inc rdi
    jmp .skip_ws
.done_tok:
    cmp ebx, 2
    jl .need
    dec ebx
    mov r14, [r15 + rbx * 8]
    cmp ebx, 1
    jle .need
    dec ebx
    lea rdi, [r15 + rbx * 8]
    lea rsi, [rel word_to]
    call strcasecmp wrt ..plt
    test eax, eax
    jnz .item_ok
    dec ebx
    cmp ebx, 0
    jle .need
.item_ok:
    cmp ebx, 0
    jle .need
    mov byte [rsp], 0
    xor ecx, ecx
.build:
    cmp ecx, ebx
    jge .find_item
    test ecx, ecx
    jz .first
    mov rdi, rsp
    call strlen wrt ..plt
    mov byte [rsp + rax], " "
    mov byte [rsp + rax + 1], 0
.first:
    mov rsi, [r15 + rcx * 8]
    mov rdi, rsp
    call strlen wrt ..plt
    lea rdi, [rsp + rax]
    mov rsi, [r15 + rcx * 8]
    call strcpy wrt ..plt
    inc ecx
    jmp .build
.find_item:
    mov rdi, r12
    mov rsi, rsp
    call inv_find_slot
    cmp eax, 0
    jl .not_carry
    movsxd r8, eax
    mov rdi, [r12 + SESSION_ROOM]
    mov rsi, r14
    lea rdx, [r12 + SESSION_NAME]
    call find_player_prefix
    test rax, rax
    jz .no_target
    mov r15, rax
    imul rcx, r8, SESSION_INV_SLOT_SIZE
    lea rsi, [r12 + SESSION_INVENTORY + rcx]
    lea rdi, [rsp + 120]
    mov edx, 16
    call strncpy wrt ..plt
    mov byte [rsp + 135], 0
    mov rdi, r12
    mov esi, r8d
    call inv_remove_slot
    mov rdi, r15
    lea rsi, [rsp + 120]
    call inv_add_internal
    mov rdi, r12
    call hg_store_save wrt ..plt
    mov rdi, r15
    call hg_store_save wrt ..plt
    lea rdi, [rsp + 140]
    mov esi, 120
    lea rdx, [rel give_you_fmt]
    lea rcx, [rsp + 120]
    lea r8, [r15 + SESSION_NAME]
    xor eax, eax
    call snprintf wrt ..plt
    mov rdi, r12
    lea rsi, [rsp + 140]
    call queue_line_h
    lea rdi, [rsp + 140]
    mov esi, 120
    lea rdx, [rel give_target_fmt]
    lea rcx, [r12 + SESSION_NAME]
    lea r8, [rsp + 120]
    xor eax, eax
    call snprintf wrt ..plt
    mov rdi, r15
    lea rsi, [rsp + 140]
    call queue_cstr_h
    add rsp, 280
    pop r15
    pop r14
    pop rbx
    ret
.not_carry:
    lea rdi, [rsp + 140]
    mov esi, 120
    lea rdx, [rel give_not_carry_fmt]
    mov rcx, rsp
    xor eax, eax
    call snprintf wrt ..plt
    mov rdi, r12
    lea rsi, [rsp + 140]
    call queue_line_h
    add rsp, 280
    pop r15
    pop r14
    pop rbx
    ret
.no_target:
    lea rdi, [rsp + 140]
    mov esi, 120
    lea rdx, [rel give_no_target_fmt]
    mov rcx, r14
    xor eax, eax
    call snprintf wrt ..plt
    mov rdi, r12
    lea rsi, [rsp + 140]
    call queue_line_h
    add rsp, 280
    pop r15
    pop r14
    pop rbx
    ret
.need:
    mov rdi, r12
    lea rsi, [rel give_need]
    call queue_line_h
    add rsp, 280
    pop r15
    pop r14
    pop rbx
    ret

; rdi=session, rsi=arg -> tell implementation
tell_impl:
    push r12
    push r13
    push r14
    push r15
    push rbx
    mov r12, rdi
    mov r13, rsi
    sub rsp, 1040
    test r13, r13
    jnz .have
    lea r13, [rel empty_str]
.have:
    mov rdi, r13
    call skip_spaces
    mov r13, rax
    lea r15, [rsp + 960]
    xor ebx, ebx
.copy_target:
    cmp ebx, 39
    jge .t_done
    movzx eax, byte [r13 + rbx]
    test al, al
    jz .t_done
    cmp al, " "
    je .t_done
    mov [r15 + rbx], al
    inc ebx
    jmp .copy_target
.t_done:
    mov byte [r15 + rbx], 0
    cmp byte [r15], 0
    je .need
    lea r14, [r13 + rbx]
    mov rdi, r14
    call skip_spaces
    mov r14, rax
    cmp byte [r14], 0
    je .need
    mov rdi, r15
    call hg_find_session_name
    test rax, rax
    jnz .send
    mov rdi, r15
    call strlen wrt ..plt
    mov r8, rax
    xor ebx, ebx
    xor r10, r10
.search:
    cmp ebx, HG_MAX_SESSIONS
    jge .check_amb
    mov edi, ebx
    call hg_session_at wrt ..plt
    test rax, rax
    jz .next_s
    mov r11, rax
    lea rdi, [r11 + SESSION_NAME]
    mov rsi, r15
    mov rdx, r8
    call strncasecmp wrt ..plt
    test eax, eax
    jnz .next_s
    test r10, r10
    jnz .no_one
    mov r10, r11
.next_s:
    inc ebx
    jmp .search
.check_amb:
    test r10, r10
    jz .no_one
    mov rax, r10
.send:
    mov rbx, rax
    lea rdi, [rbx + SESSION_REPLY_TO]
    lea rsi, [r12 + SESSION_NAME]
    call strcpy wrt ..plt
    lea rdi, [rsp + 720]
    mov esi, 80
    lea rdx, [r12 + SESSION_NAME]
    call hg_json_escape wrt ..plt
    cmp eax, 0
    jl .tell_out
    lea rdi, [rsp + 800]
    mov esi, 80
    mov rdx, r14
    call hg_json_escape wrt ..plt
    cmp eax, 0
    jl .tell_out
    lea rdi, [rsp + 280]
    mov esi, 320
    lea rdx, [rel tell_evt_fmt]
    lea rcx, [rsp + 720]
    mov r8, [rsp + 800]
    xor eax, eax
    call snprintf wrt ..plt
    mov rdi, rsp
    mov esi, 280
    lea rdx, [rel tell_you_fmt]
    lea rcx, [r12 + SESSION_NAME]
    mov r8, r14
    xor eax, eax
    call snprintf wrt ..plt
    lea rdi, [rsp + 600]
    mov rsi, rsp
    call strcpy wrt ..plt
    mov rdi, rsp
    call strlen wrt ..plt
    lea rdi, [rsp + 600]
    add rdi, rax
    lea rsi, [rsp + 280]
    call strcpy wrt ..plt
    mov rdi, rbx
    lea rsi, [rsp + 600]
    call queue_cstr_h
    lea rdi, [rsp + 880]
    mov esi, 120
    lea rdx, [rel tell_self_fmt]
    lea rcx, [rbx + SESSION_NAME]
    mov r8, r14
    xor eax, eax
    call snprintf wrt ..plt
    mov rdi, r12
    lea rsi, [rsp + 880]
    call queue_line_h
.tell_out:
    add rsp, 1040
    jmp .out
.need:
    mov rdi, r12
    lea rsi, [rel tell_need]
    call queue_line_h
    jmp .out
.no_one:
    mov rdi, r12
    lea rsi, [rel tell_no_one]
    call queue_line_h
.out:
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    ret

global hg_cmd_tell
hg_cmd_tell:
    call setup_cmd
    mov rdi, r12
    mov rsi, rdx
    jmp tell_impl

global hg_cmd_reply
hg_cmd_reply:
    call setup_cmd
    push r14
    push r15
    sub rsp, 296
    lea rdi, [r12 + SESSION_REPLY_TO]
    cmp byte [rdi], 0
    je .none
    mov rsi, rdx
    test rsi, rsi
    jnz .have_msg
    lea rsi, [rel empty_str]
.have_msg:
    mov rdi, rsp
    mov esi, 280
    lea rdx, [rel empty_str]
    lea rcx, [r12 + SESSION_REPLY_TO]
    mov r8, rsi
    ; snprintf(buf, 280, "%s %s", to, arg) - use fmt
    mov rdi, rsp
    mov esi, 280
    lea rdx, [rel reply_concat_fmt]
    lea rcx, [r12 + SESSION_REPLY_TO]
    mov r8, rsi
    xor eax, eax
    call snprintf wrt ..plt
    mov rdi, r12
    mov rsi, rsp
    call tell_impl
    add rsp, 296
    pop r15
    pop r14
    ret
.none:
    mov rdi, r12
    lea rsi, [rel reply_none]
    call queue_line_h
    add rsp, 296
    pop r15
    pop r14
    ret

reply_concat_fmt: db "%s %s", 0

global hg_cmd_yell
hg_cmd_yell:
    call setup_cmd
    push rbx
    push r14
    push r15
    mov r14, rdx
    test r14, r14
    jnz .have
    lea r14, [rel empty_str]
.have:
    mov rdi, r14
    call skip_spaces
    mov r14, rax
    cmp byte [r14], 0
    je .need
    sub rsp, 648
    lea rdi, [rsp + 400]
    mov esi, 80
    lea rdx, [r12 + SESSION_NAME]
    call hg_json_escape wrt ..plt
    cmp eax, 0
    jl .yell_out
    lea rdi, [rsp + 480]
    mov esi, 200
    mov rdx, r14
    call hg_json_escape wrt ..plt
    cmp eax, 0
    jl .yell_out
    lea rdi, [rsp + 320]
    mov esi, 320
    lea rdx, [rel yell_evt_fmt]
    lea rcx, [rsp + 400]
    mov r8, [rsp + 480]
    xor eax, eax
    call snprintf wrt ..plt
    xor ebx, ebx
.loop:
    cmp ebx, HG_MAX_SESSIONS
    jge .yell_out
    mov edi, ebx
    call hg_session_at wrt ..plt
    test rax, rax
    jz .next
    mov r15, rax
    lea rdi, [r15 + SESSION_NAME]
    cmp byte [rdi], 0
    je .next
    lea rdi, [r12 + SESSION_NAME]
    mov rsi, [r15 + SESSION_NAME]
    call strcasecmp wrt ..plt
    jz .you
    lea rdi, [rsp]
    mov esi, 280
    lea rdx, [rel yell_other_fmt]
    lea rcx, [r12 + SESSION_NAME]
    mov r8, r14
    xor eax, eax
    call snprintf wrt ..plt
    jmp .send
.you:
    lea rdi, [rsp]
    mov esi, 280
    lea rdx, [rel yell_you_fmt]
    mov rcx, r14
    xor eax, eax
    call snprintf wrt ..plt
.send:
    lea rdi, [rsp + 280]
    mov esi, 360
    mov rdx, rsp
    call strlen wrt ..plt
    lea rdi, [rsp + 280]
    lea rsi, [rsp + rax]
    lea rdx, [rsp + 320]
    call strcpy wrt ..plt
    mov rdi, r15
    lea rsi, [rsp + 280]
    call queue_cstr_h
.next:
    inc ebx
    jmp .loop
.need:
    mov rdi, r12
    lea rsi, [rel yell_need]
    call queue_line_h
    jmp .yell_out
.yell_out:
    add rsp, 648
    pop r15
    pop r14
    pop rbx
    ret

global hg_cmd_wall
hg_cmd_wall:
    call setup_cmd
    push r14
    mov r14, rdx
    lea rdi, [r12 + SESSION_NAME]
    call hg_is_admin wrt ..plt
    test eax, eax
    jz .not_admin
    test r14, r14
    jnz .have
    lea r14, [rel empty_str]
.have:
    mov rdi, r14
    call skip_spaces
    mov r14, rax
    cmp byte [r14], 0
    je .need
    sub rsp, 840
    lea rdi, [rsp + 400]
    mov esi, 80
    lea rdx, [r12 + SESSION_NAME]
    call hg_json_escape wrt ..plt
    cmp eax, 0
    jl .wall_out
    lea rdi, [rsp + 480]
    mov esi, 240
    mov rdx, r14
    call hg_json_escape wrt ..plt
    cmp eax, 0
    jl .wall_out
    lea rdi, [rsp]
    mov esi, 320
    lea rdx, [rel wall_banner_fmt]
    mov rcx, r14
    xor eax, eax
    call snprintf wrt ..plt
    lea rdi, [rsp + 320]
    mov esi, 400
    lea rdx, [rel wall_evt_fmt]
    lea rcx, [rsp + 400]
    mov r8, [rsp + 480]
    xor eax, eax
    call snprintf wrt ..plt
    lea rdi, [rsp + 720]
    mov esi, 800
    lea rdx, [rsp]
    lea rcx, [rsp + 320]
    ; snprintf(both, 800, "%s%s", banner, evt)
    mov rdi, rsp
    mov esi, 320
    call strlen wrt ..plt
    mov r9, rax
    lea rdi, [rsp + 320]
    call strlen wrt ..plt
    add r9, rax
    lea rdi, [rsp + 720]
    mov rsi, rsp
    call strcpy wrt ..plt
    lea rdi, [rsp + 720]
    call strlen wrt ..plt
    lea rsi, [rsp + 320]
    lea rdi, [rsp + 720 + rax]
    call strcpy wrt ..plt
    lea rdi, [rsp + 720]
    xor rsi, rsi
    call hg_deliver_all wrt ..plt
    jmp .wall_out
.not_admin:
    mov rdi, r12
    lea rsi, [rel wall_not_admin]
    call queue_line_h
    jmp .out
.need:
    mov rdi, r12
    lea rsi, [rel wall_need]
    call queue_line_h
.wall_out:
    add rsp, 840
.out:
    pop r14
    ret
