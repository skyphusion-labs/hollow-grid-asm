; Second-wave social commands (separate object linked with social.asm).
default rel
%include "state.inc"

section .bss
forgiven_n:      resd 1
forgiven:        resb 256 * PAIR_SIZE
kept_n:          resd 1
kept:            resb PAIR_MAX * PAIR_SIZE
cache_gold:      resq 64
cells_ready_at:  resq 1
transit_ready_at: resq 1
deed_n:          resd 1
deeds:           resb DEED_MAX_ENTRIES * DEED_ENTRY_SIZE

section .rodata
sp2_empty: db 0
sp2_basalt: db "Basalt Relay", 0
sp2_market: db "market", 0
sp2_dais: db "dais", 0
sp2_nexus: db "nexus", 0
sp2_waystation: db "waystation", 0
sp2_front: db "front", 0
sp2_ally: db "ally", 0
sp2_none: db "none", 0
sp2_returned: db "the Returned", 0
sp2_antidote: db "antidote", 0
sp2_elf: db "elf", 0
sp2_dustkin: db "dustkin", 0
sp2_mira: db "Mira", 0
sp2_rook: db "Rook", 0
sp2_sable: db "Sable", 0
sp2_tess: db "Tess", 0
sp2_jon: db "Jon", 0
sp2_regard_branded: db "branded", 0
sp2_regard_honored: db "honored", 0
sp2_regard_feared: db "feared", 0
sp2_regard_trusted: db "trusted", 0
sp2_regard_front: db "front", 0
sp2_regard_neutral: db "neutral", 0
sp2_steal_bad: db "You can't do that here.", 0
sp2_steal_prose: db "You snag a fistful of coin while the vendor drone's back is turned. Your hands shake anyway.", 0
sp2_steal_shout: db "%s is caught with a hand in the till!", 13, 10, 0
sp2_look_brand_title: db "%s, %s (%s) stands before you, looking steady.", 0
sp2_look_brand: db "%s (%s) stands before you, looking steady.", 0
sp2_look_plain: db "%s stands before you, looking steady.", 0
sp2_look_evt: db "@event player.read {", 34, "name", 34, ":", 34, "%s", 34, ",", 34, "title", 34, ":", 34, "%s", 34, ",", 34, "faction", 34, ":", 34, "%s", 34, ",", 34, "ashsworn", 34, ":%s,", 34, "regard", 34, ":", 34, "%s", 34, "}", 13, 10, 0
sp2_true: db "true", 0
sp2_false: db "false", 0
sp2_forgive_need: db "Forgive whom?  (forgive <player> -- choose to let someone marked back in)", 0
sp2_forgive_self: db "You cannot forgive yourself here; that is a longer road, and a lonelier one.", 0
sp2_forgive_absent: db "There's no one called ", 34, "%s", 34, " here to forgive.", 0
sp2_forgive_twice: db "You have already forgiven %s. It was true the first time; it does not need saying twice.", 0
sp2_forgive_unmarked: db "%s carries nothing that needs your forgiveness. Keep the words for someone who does.", 0
sp2_grace: db "%s forgave %s here.", 0
sp2_forgive_push: db "%s looks at you and chooses to forgive you.", 13, 10, 0
sp2_forgive_ash: db "It reaches something in you. But the ash does not lift; it never will. You carry the mark and the mercy both. Some things are not forgotten, even when they are forgiven.", 13, 10, 0
sp2_forgiven_evt: db "@event char.forgiven {", 34, "by", 34, ":", 34, "%s", 34, ",", 34, "ashsworn", 34, ":%s,", 34, "redeemed", 34, ":%s}", 13, 10, 0
sp2_redemption_evt: db "@event grid.redemption {", 34, "name", 34, ":", 34, "%s", 34, ",", 34, "title", 34, ":", 34, "%s", 34, "}", 13, 10, 0
sp2_forgive_returned: db "Something you had been carrying alone, you are not carrying alone anymore. You found your way back, and someone met you on the road. (you are the Returned)", 13, 10, 0
sp2_forgive_other: db "It lands, and it stays with you. The road is still yours to walk, but you are not walking it unseen.", 13, 10, 0
sp2_forgive_room: db "%s forgives %s.", 13, 10, 0
sp2_forgive_you: db "You choose to forgive %s. Out here that is not nothing; it may be everything.", 0
sp2_cache_announce: db "Someone has cached aid here: %lld gold, left for whoever comes next. (gather)", 0
sp2_cache_evt: db "@event node.cache {", 34, "gold", 34, ":%lld}", 13, 10, 0
sp2_who_evt: db "@event grid.who {", 34, "players", 34, ":%s}", 13, 10, 0
sp2_who_none: db "No one else walks the wastes right now.", 0
sp2_who_some: db "Online: survivors walk the wastes.", 0
sp2_cache_need: db "Cache how much?  (cache <gold> -- leave it here for whoever comes next)", 0
sp2_cache_short: db "You don't have %lld gold to give. (you have %lld)", 0
sp2_cache_echo: db "%s left aid here for whoever comes next.", 0
sp2_cache_prose: db "You tuck %lld gold into a hollow where the next traveler will find it. They'll never know your name. You do it anyway.", 0
sp2_gather_none: db "There's nothing cached here. If you have something to spare, you could change that. (cache <gold>)", 0
sp2_gather_prose: db "You find %lld gold someone cached here. Wherever they are, they meant it for a stranger; tonight that's you. (gold: %lld)", 0
sp2_gridcast_need: db "Gridcast what? (gridcast <message> -- the dead network carries it to every world)", 0
sp2_gridcast_fail: db "The Grid swallows your words; the network is unreachable.", 0
sp2_gridcast_prose: db "You cast your voice into the dead Grid, out across every node: ", 34, "%s", 34, 0
sp2_gridcast_evt: db "@event comm.gridcast {", 34, "world", 34, ":", 34, "%s", 34, ",", 34, "from", 34, ":", 34, "%s", 34, ",", 34, "text", 34, ":", 34, "%s", 34, "}", 13, 10, 0
sp2_free_have: db "The maiden smiles weakly. ", 34, "You already carry my vial. Use it well.", 34, 0
sp2_free_pit: db "You strike the chains free. The captive presses a vial into your hands:", 13, 10, "  ", 34, "Antivenom, for the poison that haunts these wastes. My name is %s. I won't forget yours.", 34, 0
sp2_free_empty: db "The cages stand open and empty; someone already cut them loose. The Front will round up more soon enough -- it always does -- but not yet.", 0
sp2_free_cells: db "You wrench the cages open. Rook and Sable stumble out into the dark, some pausing only to grip your hand on the way past. Whatever else you are, whatever else you've done -- you did this.", 13, 10, 0
sp2_free_none: db "There is no one here to free.", 0
sp2_rescued_one: db "@event grid.rescued {", 34, "savedBy", 34, ":", 34, "%s", 34, ",", 34, "freed", 34, ":[", 34, "%s", 34, "]}", 13, 10, 0
sp2_rescued_two: db "@event grid.rescued {", 34, "savedBy", 34, ":", 34, "%s", 34, ",", 34, "freed", 34, ":[", 34, "%s", 34, ",", 34, "%s", 34, "]}", 13, 10, 0
sp2_shelter_wrong: db "There's no one here to shelter. The distress call comes from the old transit hub, south off the Scorch Road.", 0
sp2_shelter_empty: db "The platform is empty now. Whoever called, you got them moving -- toward the free camp, you have to believe. The Front will strand others here soon enough; it always does, and the call will go out again.", 0
sp2_shelter_prose: db "You answer the call. You get Tess and Jon up and moving -- bottles filled at the tap, the youngest carried -- and stand watch on the cracked platform while they slip out the far side, toward the free camp and whatever the free folk can spare. The hand-radio goes quiet at last. Someone came.", 13, 10, 0
sp2_saved_none: db "No one has been pulled from the cages yet, or the Grid has forgotten. Find the Front's cages and change that.", 0
sp2_saved_head: db "The Grid keeps these, pulled back out of the cages:", 0
sp2_saved_line: db "  - %s, freed by %s", 0
sp2_rescued_roll: db "@event grid.rescued_roll {", 34, "rescued", 34, ":%s}", 13, 10, 0
sp2_strayed: db "Something in you has gone cold and quiet. You have strayed a long way toward the cinders. (the Grid marks it, and so do you)", 0
sp2_ash_good: db "You have clawed back to something good, and it is real. But the ash does not wash off; it never will. That is the cost. Carry it, and keep doing good anyway.", 0
sp2_return_prose: db "The hollow you carried has filled with something else. The free folk have started to meet your eyes again. You found your way back. (you are the Returned)", 0
sp2_return_echo: db "%s found their way back from the cinders.", 0
sp2_dais_none: db "There is no one here to swear to.", 0
sp2_dais_settled: db "The Ashmonger only laughs. There's nothing here to decide that your blood hasn't already settled.", 0
sp2_dais_ash: db "You kneel before the Ashmonger -- an elf, at the feet of the man who cages elves.", 13, 10, "He laughs, delighted, and burns the ash-and-flame into your shoulder with his own hand.", 13, 10, 34, "The best dogs are the ones who hate themselves. You'll do the work my men won't.", 34, 13, 10, "You are ash-sworn now. There is no one left to belong to.", 13, 10, 0
sp2_dais_plain: db "You kneel and swear yourself to the Front. The Ashmonger's hand closes on your shoulder like a trap. ", 34, "Good. The wastes will be ours.", 34, 0
sp2_pledge_echo: db "%s swore themselves to the Cinder Front at the Ashmonger's dais.", 0
sp2_pledge_shout: db "%s swore themselves to the Cinder Front at the Ashmonger's dais.", 13, 10, 0
sp2_defy_none: db "There's no oath here to break.", 0
sp2_defy_ash: db "You spit at the Ashmonger's boots. ", 34, "I'm done being your dog.", 34, " The stronghold turns on you at once.", 13, 10, "You stand with the free folk now -- but the brand on your shoulder stays. For once you wear it turning the right way.", 13, 10, "Whether the people you helped cage can ever look at you again is not a thing the wastes will settle tonight, or maybe ever. You turned. It has to be enough to start.", 13, 10, 0
sp2_defy_plain: db "You spit at the Ashmonger's boots. ", 34, "I'm done being your dog.", 34, " Every soldier in the stronghold turns on you at once -- but you stand with the free folk now, and the wastes will remember THIS above all.", 13, 10, 0
sp2_defy_echo: db "%s turned on the Cinder Front at the Ashmonger's own dais.", 0
sp2_defy_shout: db "%s has turned against the Cinder Front!", 13, 10, 0
sp2_witness_empty: db "The roll is empty for now. No one the Grid remembers has fallen lately; may it stay that way.", 0
sp2_witness_head: db "The Grid remembers these fallen. Speak a name to keep them:  (witness <name>)", 0
sp2_witness_line: db "  %s  -- fell at %s", 0
sp2_fallen_evt: db "@event grid.fallen {", 34, "fallen", 34, ":%s}", 13, 10, 0
sp2_witness_self: db "You cannot hold a vigil for yourself. Someone else will have to remember you.", 0
sp2_witness_absent: db "The Grid holds no recent memory of anyone called ", 34, "%s", 34, ".  (try 'witness' to read the roll)", 0
sp2_witness_twice: db "You have already kept %s's memory. It does not fade, and does not need keeping twice.", 0
sp2_vigil_echo: db "%s kept the memory of %s, whom the wastes tried to forget.", 0
sp2_witness_prose: db "You speak %s into the hum and hold it there a moment. The Grid keeps the name; so do you.", 0
sp2_remembrance_evt: db "@event grid.remembrance {", 34, "fallen", 34, ":", 34, "%s", 34, ",", 34, "world", 34, ":", 34, "%s", 34, ",", 34, "room", 34, ":", 34, "%s", 34, "}", 13, 10, 0
sp2_reckoning_head: db "The Grid has kept count. This is the sum of you so far:", 0
sp2_standing_ash: db "  standing: %s   (morality %lld)   ASH-SWORN", 0
sp2_standing: db "  standing: %s   (morality %lld)", 0
sp2_reckoning_returned: db "  the Returned -- you strayed toward the cinders and found your way back.", 0
sp2_reckoning_ash: db "  ash-marked, and good anyway -- the brand stays; you keep choosing well regardless.", 0
sp2_reckoning_strayed: db "  strayed -- you have gone a long way toward the cinders. (the way back is not closed)", 0
sp2_reckoning_none: db "  Nothing yet weighs on either side. The wastes are still waiting to see who you are.", 0
sp2_reckoning_evt: db "@event char.reckoning {", 34, "morality", 34, ":%lld,", 34, "standing", 34, ":", 34, "%s", 34, ",", 34, "ashsworn", 34, ":%s,", 34, "strayed", 34, ":%s,", 34, "redeemed", 34, ":%s,", 34, "deeds", 34, ":%s}", 13, 10, 0
sp2_dmended: db "mended",0
sp2_dforgave: db "forgave",0
sp2_daided: db "aided",0
sp2_dkept: db "kept",0
sp2_dfreed: db "freed",0
sp2_dsheltered: db "sheltered",0
sp2_dstood: db "stood",0
sp2_dinscribed: db "inscribed",0
sp2_drestored: db "restored",0
sp2_dslain: db "slain",0
sp2_dstolen: db "stolen",0
sp2_dpledged: db "pledged",0
sp2_ddefected: db "defected",0
sp2_lmended: db "  mended the hurt of others: %d",0
sp2_lforgave: db "  souls you chose to forgive: %d",0
sp2_laided: db "  aid left for strangers you'll never meet: %d",0
sp2_lkept: db "  names of the fallen you kept: %d",0
sp2_lfreed: db "  souls you cut out of the cages: %d",0
sp2_lsheltered: db "  distress calls you answered: %d",0
sp2_lstood: db "  times you stood with the free folk: %d",0
sp2_linscribed: db "  words you left for whoever comes next: %d",0
sp2_lrestored: db "  dead nodes you brought back: %d",0
sp2_lslain: db "  lives you took: %d",0
sp2_lstolen: db "  thefts: %d",0
sp2_lpledged: db "  times you swore to the Cinder Front: %d",0
sp2_ldefected: db "  times you turned on the Front: %d",0
sp2_stats_no: db "Only a keeper of the Grid can read its deep memory.",0
sp2_prune_no: db "Only a keeper of the Grid can tend its deep memory.",0
sp2_stats_fail: db "The hub is unreachable; the deep memory cannot be read.",0
sp2_prune_fail: db "The hub is unreachable; the deep memory cannot be tended.",0
sp2_stats_evt: db "@event grid.ledger_stats {",34,"total",34,":%d,",34,"kinds",34,":%s}",13,10,0
sp2_prune_evt: db "@event grid.ledger_pruned {",34,"removed",34,":%d,",34,"before",34,":%d,",34,"after",34,":%d,",34,"kinds",34,":%s}",13,10,0
sp2_stats_head: db "The Grid ledger holds %d trace(s):",0
sp2_stats_line: db "  %-10.32s %d",0
sp2_prune_line: db "Pruned %d ambient trace(s) (ghost, passage, recall).",0
sp2_prune_after: db "The ledger went from %d to %d trace(s); only meaningful memory remains.",0

section .data.rel.ro align=8
sp2_deed_names: dq sp2_dmended, sp2_dforgave, sp2_daided, sp2_dkept, sp2_dfreed, sp2_dsheltered, sp2_dstood, sp2_dinscribed, sp2_drestored, sp2_dslain, sp2_dstolen, sp2_dpledged, sp2_ddefected
sp2_deed_labels: dq sp2_lmended, sp2_lforgave, sp2_laided, sp2_lkept, sp2_lfreed, sp2_lsheltered, sp2_lstood, sp2_linscribed, sp2_lrestored, sp2_lslain, sp2_lstolen, sp2_lpledged, sp2_ldefected

section .text

extern snprintf, strlen, strcpy, strncpy, strcasecmp, strncasecmp, strcmp, memset, atoll
extern hg_queue_line, hg_queue_cstr, hg_deliver_room, hg_deliver_all, hg_json_escape, hg_is_admin
extern hg_emit_vitals_now, hg_emit_affects_now, hg_emit_room_actions_now, hg_store_save, hg_room_id_cstr
extern hg_brand_standing, hg_now_ms, hg_session_at, hg_grid_record_local_echo, hg_grid_shift_tide
extern hg_grid_gridcast, hg_grid_presence, hg_grid_record_rescued, hg_grid_recent_rescued
extern hg_grid_recent_fallen, hg_grid_ledger_stats, hg_grid_prune_ledger
extern hg_emit_grid_who_now, hg_emit_char_reckoning_now
extern setup_cmd, queue_line_h, queue_cstr_h, skip_spaces, find_player_prefix
extern inv_add_internal, inv_find_slot

; rdi=session -> rax=regard string
global hg_regard_of, hg_deed_add_str, hg_deed_count_str
global hg_forgiven_has, hg_forgiven_mark, hg_kept_has, hg_kept_mark

hg_regard_of:
regard_of_ptr:
    push rbx
    mov rbx, rdi
    cmp qword [rbx + SESSION_ASHSWORN], 0
    jne .brand
    mov rax, [rbx + SESSION_MORALITY]
    cmp rax, 50
    jge .honor
    cmp rax, -50
    jle .fear
    lea rdi, [rbx + SESSION_FACTION]
    lea rsi, [rel sp2_ally]
    call strcmp wrt ..plt
    test eax,eax
    jz .trust
    lea rdi, [rbx + SESSION_FACTION]
    lea rsi, [rel sp2_front]
    call strcmp wrt ..plt
    test eax,eax
    jz .front
    lea rax,[rel sp2_regard_neutral]
    jmp .out
.brand: lea rax,[rel sp2_regard_branded] ; fall through
    jmp .out
.honor: lea rax,[rel sp2_regard_honored]
    jmp .out
.fear: lea rax,[rel sp2_regard_feared]
    jmp .out
.trust: lea rax,[rel sp2_regard_trusted]
    jmp .out
.front: lea rax,[rel sp2_regard_front]
.out:
    pop rbx
    ret

; rdi=player rsi=DEED_* kind
global hg_add_deed_h
hg_add_deed_h:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    test r12,r12
    jz .out
    cmp byte [r12],0
    je .out
    xor ebx,ebx
.find:
    cmp ebx,[rel deed_n]
    jge .new
    imul rax,rbx,DEED_ENTRY_SIZE
    lea r11, [rel deeds]
    lea rdi, [r11 + rax]
    mov rsi,r12
    call strcasecmp wrt ..plt
    test eax,eax
    jz .got
    inc ebx
    jmp .find
.new:
    cmp ebx,DEED_MAX_ENTRIES
    jge .out
    imul rax,rbx,DEED_ENTRY_SIZE
    lea r11, [rel deeds]
    lea rdi, [r11 + rax]
    xor esi,esi
    mov edx,DEED_ENTRY_SIZE
    call memset wrt ..plt
    imul rax,rbx,DEED_ENTRY_SIZE
    lea r11, [rel deeds]
    lea rdi, [r11 + rax]
    mov rsi, r12
    mov edx,40
    call strncpy wrt ..plt
    inc dword [rel deed_n]
.got:
    imul rax,rbx,DEED_ENTRY_SIZE
    lea r11, [rel deeds]
    lea rax, [r11 + rax + DEED_ENTRY_COUNTS]
    inc qword [rax + r13*8]
.out:
    pop r13
    pop r12
    pop rbx
    ret

; rdi=player rsi=DEED_* -> eax=count
hg_deed_count_h:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    xor ebx,ebx
.loop:
    cmp ebx,[rel deed_n]
    jge .zero
    imul rax,rbx,DEED_ENTRY_SIZE
    lea r11, [rel deeds]
    lea rdi, [r11 + rax]
    mov rsi,r12
    call strcasecmp wrt ..plt
    test eax,eax
    jz .found
    inc ebx
    jmp .loop
.found:
    imul rax,rbx,DEED_ENTRY_SIZE
    lea r11, [rel deeds]
    lea r10, [r11 + rax + DEED_ENTRY_COUNTS]
    mov eax, [r10 + r13*8]
    jmp .out
.zero: xor eax, eax
.out:
    pop r13
    pop r12
    pop rbx
    ret

; C-facing deed accessors retain string kinds at the ABI boundary.
; rdi=player, rsi=kind string; add returns void, count returns eax.
hg_deed_add_str:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    test r12,r12
    jz .out
    test r13,r13
    jz .out
    xor ebx,ebx
.loop:
    cmp ebx,DEED_KINDS
    jge .out
    lea r11, [rel sp2_deed_names]
    mov rdi, [r11 + rbx*8]
    mov rsi, r13
    call strcmp wrt ..plt
    test eax, eax
    jz .found
    inc ebx
    jmp .loop
.found:
    mov rdi, r12
    mov esi, ebx
    call hg_add_deed_h
.out:
    pop r13
    pop r12
    pop rbx
    ret

hg_deed_count_str:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    test r12, r12
    jz .zero
    test r13, r13
    jz .zero
    xor ebx, ebx
.loop:
    cmp ebx, DEED_KINDS
    jge .zero
    lea r11, [rel sp2_deed_names]
    mov rdi, [r11 + rbx*8]
    mov rsi,r13
    call strcmp wrt ..plt
    test eax,eax
    jz .found
    inc ebx
    jmp .loop
.found:
    mov rdi,r12
    mov esi,ebx
    call hg_deed_count_h
    jmp .out
.zero: xor eax, eax
.out:
    pop r13
    pop r12
    pop rbx
    ret

; rdi=forgiver/keeper, rsi=subject/fallen -> eax=boolean
hg_forgiven_has:
already_forgiven_h:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    xor ebx,ebx
.loop:
    cmp ebx,[rel forgiven_n]
    jge .no
    imul rax,rbx,PAIR_SIZE
    lea r11, [rel forgiven]
    lea rdi, [r11 + rax + PAIR_A]
    mov rsi,r12
    call strcasecmp wrt ..plt
    test eax,eax
    jnz .next
    imul rax,rbx,PAIR_SIZE
    lea r11, [rel forgiven]
    lea rdi, [r11 + rax + PAIR_B]
    mov rsi,r13
    call strcasecmp wrt ..plt
    test eax,eax
    jz .yes
.next:
    inc ebx
    jmp .loop
.yes: mov eax,1
    jmp .out
.no: xor eax, eax
.out:
    pop r13
    pop r12
    pop rbx
    ret

hg_forgiven_mark:
mark_forgiven_h:
    push rbx
    push r12
    push r13
    mov rbx, rdi
    mov r12, rsi
    call already_forgiven_h
    test eax,eax
    jnz .out
    mov r13d,[rel forgiven_n]
    cmp r13d,256
    jge .out
    imul rax,r13,PAIR_SIZE
    lea r11, [rel forgiven]
    lea rdi, [r11 + rax + PAIR_A]
    mov rsi,rbx
    mov edx,40
    call strncpy wrt ..plt
    imul rax,r13,PAIR_SIZE
    lea r11, [rel forgiven]
    lea rdi, [r11 + rax + PAIR_B]
    mov rsi,r12
    mov edx,40
    call strncpy wrt ..plt
    inc dword [rel forgiven_n]
.out:
    pop r13
    pop r12
    pop rbx
    ret

hg_kept_has:
has_kept_h:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    xor ebx,ebx
.loop:
    cmp ebx,[rel kept_n]
    jge .no
    imul rax,rbx,PAIR_SIZE
    lea r11, [rel kept]
    lea rdi, [r11 + rax + PAIR_A]
    mov rsi,r12
    call strcasecmp wrt ..plt
    test eax,eax
    jnz .next
    imul rax,rbx,PAIR_SIZE
    lea r11, [rel kept]
    lea rdi, [r11 + rax + PAIR_B]
    mov rsi,r13
    call strcasecmp wrt ..plt
    test eax,eax
    jz .yes
.next:
    inc ebx
    jmp .loop
.yes: mov eax,1
    jmp .out
.no: xor eax, eax
.out:
    pop r13
    pop r12
    pop rbx
    ret

hg_kept_mark:
mark_kept_h:
    push rbx
    push r12
    push r13
    mov rbx, rdi
    mov r12, rsi
    call has_kept_h
    test eax,eax
    jnz .out
    mov r13d,[rel kept_n]
    cmp r13d,PAIR_MAX
    jge .out
    imul rax,r13,PAIR_SIZE
    lea r11, [rel kept]
    lea rdi, [r11 + rax + PAIR_A]
    mov rsi,rbx
    mov edx,40
    call strncpy wrt ..plt
    imul rax,r13,PAIR_SIZE
    lea r11, [rel kept]
    lea rdi, [r11 + rax + PAIR_B]
    mov rsi,r12
    mov edx,40
    call strncpy wrt ..plt
    inc dword [rel kept_n]
.out:
    pop r13
    pop r12
    pop rbx
    ret

global resolve_return_h
resolve_return_h:
    ; r12=session. Keep it across all formatter calls.
    push rbx
    mov rbx,r12
    mov qword [rbx + SESSION_REDEEMED],1
    cmp byte [rbx + SESSION_TITLE],0
    jne .saved
    lea rdi,[rbx + SESSION_TITLE]
    lea rsi,[rel sp2_returned]
    mov edx,48
    call strncpy wrt ..plt
.saved:
    mov rdi,rbx
    call hg_store_save wrt ..plt
    sub rsp,256
    lea rdi,[rsp]
    mov esi,80
    lea rdx,[rbx + SESSION_NAME]
    call hg_json_escape wrt ..plt
    lea rdi,[rsp+80]
    mov esi,80
    lea rdx,[rbx + SESSION_TITLE]
    call hg_json_escape wrt ..plt
    lea rdi,[rsp+160]
    mov esi,96
    lea rdx,[rel sp2_redemption_evt]
    mov rcx,rsp
    lea r8,[rsp+80]
    xor eax,eax
    call snprintf wrt ..plt
    mov rdi,rbx
    lea rsi,[rsp+160]
    call queue_cstr_h
    lea rdi,[rsp+160]
    mov esi,160
    lea rdx,[rel sp2_return_echo]
    lea rcx,[rbx + SESSION_NAME]
    xor eax,eax
    call snprintf wrt ..plt
    mov rdi,[rbx + SESSION_ROOM]
    call hg_room_id_cstr wrt ..plt
    test rax,rax
    jnz .echo
    lea rax,[rel sp2_dais]
.echo:
    mov rdi,rax
    lea rsi,[rel sp2_dredemption]
    lea rdx,[rsp+160]
    call hg_grid_record_local_echo wrt ..plt
    add rsp,256
    pop rbx
    ret
sp2_dredemption: db "redemption",0

moral_arc_h:
    test r12,r12
    jz .out
    cmp byte [r12 + SESSION_NAME],0
    je .out
    mov rax,[r12 + SESSION_MORALITY]
    cmp qword [r12 + SESSION_STRAYED],0
    jne .check_return
    cmp rax,STRAY_FLOOR
    jg .out
    mov qword [r12 + SESSION_STRAYED],1
    mov rdi,r12
    call hg_store_save wrt ..plt
    mov rdi,r12
    lea rsi,[rel sp2_strayed]
    call queue_line_h
    ret
.check_return:
    cmp qword [r12 + SESSION_REDEEMED],0
    jne .out
    cmp rax,REDEEM_CEIL
    jl .out
    lea rdi,[r12 + SESSION_FACTION]
    lea rsi,[rel sp2_front]
    call strcmp wrt ..plt
    test eax,eax
    jz .out
    cmp qword [r12 + SESSION_ASHSWORN],0
    jz .returned
    mov qword [r12 + SESSION_REDEEMED],1
    mov rdi,r12
    call hg_store_save wrt ..plt
    mov rdi,r12
    lea rsi,[rel sp2_ash_good]
    jmp queue_line_h
.returned:
    call resolve_return_h
    mov rdi,r12
    lea rsi,[rel sp2_return_prose]
    call queue_line_h
.out: ret

; Cache / cooldown accessors for remaining C handlers during migration.
global hg_cache_gold_peek, hg_cache_gold_add, hg_cache_gold_take
global hg_cells_ready_at_get, hg_cells_ready_at_set
global hg_transit_ready_at_get, hg_transit_ready_at_set

hg_cache_gold_peek:
    cmp rdi, 0
    jl .z
    cmp rdi, 64
    jge .z
    lea r11, [rel cache_gold]
    mov rax, [r11 + rdi*8]
    ret
.z: xor rax, rax
    ret

hg_cache_gold_add:
    cmp rdi, 0
    jl .r
    cmp rdi, 64
    jge .r
    lea r11, [rel cache_gold]
    add qword [r11 + rdi*8], rsi
.r: ret

hg_cache_gold_take:
    cmp rdi, 0
    jl .z
    cmp rdi, 64
    jge .z
    lea r11, [rel cache_gold]
    mov rax, [r11 + rdi*8]
    lea r11, [rel cache_gold]
    mov qword [r11 + rdi*8], 0
    ret
.z: xor rax, rax
    ret

hg_cells_ready_at_get:
    mov rax, [rel cells_ready_at]
    ret

hg_cells_ready_at_set:
    mov [rel cells_ready_at], rdi
    ret

hg_transit_ready_at_get:
    mov rax, [rel transit_ready_at]
    ret

hg_transit_ready_at_set:
    mov [rel transit_ready_at], rdi
    ret

global hg_announce_cache_now
hg_announce_cache_now:
    push r12
    push r13
    mov r12,rdi
    mov rax,[r12 + SESSION_ROOM]
    cmp rax,0
    jl .out
    cmp rax,64
    jge .out
    lea r11, [rel cache_gold]
    mov r13, [r11 + rax*8]
    test r13,r13
    jle .out
    sub rsp,168
    mov rdi,rsp
    mov esi,160
    lea rdx,[rel sp2_cache_announce]
    mov rcx,r13
    xor eax,eax
    call snprintf wrt ..plt
    mov rdi,r12
    mov rsi,rsp
    call queue_line_h
    mov rdi,rsp
    mov esi,80
    lea rdx,[rel sp2_cache_evt]
    mov rcx,r13
    xor eax,eax
    call snprintf wrt ..plt
    mov rdi,r12
    mov rsi,rsp
    call queue_cstr_h
    add rsp,168
.out: pop r13
    pop r12
    ret

global hg_join_record_oath
hg_join_record_oath:
    push rbx
    push r12
    mov r12, rdi
    ; entry rsp≡8; 2 pushes keep ≡8; sub 8-mod-16 -> rsp≡0 before C calls.
    sub rsp, 168
    mov rdi, rsp
    mov esi, 160
    cmp qword [r12 + SESSION_ASHSWORN], 0
    lea rdx, [rel sp2_join_oath]
    je .text
    lea rdx, [rel sp2_join_oath_ash]
.text:
    lea rcx, [r12 + SESSION_NAME]
    xor eax, eax
    call snprintf wrt ..plt
    mov rdi, [r12 + SESSION_ROOM]
    call hg_room_id_cstr wrt ..plt
    mov rdi, rax
    test rdi, rdi
    jnz .node
    lea rdi, [rel sp2_market]
.node:
    lea rsi, [rel sp2_doath]
    mov rdx, rsp
    call hg_grid_record_local_echo wrt ..plt
    mov rdi, r12
    call hg_emit_room_actions_now wrt ..plt
    add rsp, 168
    pop r12
    pop rbx
    ret
sp2_doath: db "oath",0
sp2_join_oath: db "%s swore to the Cinder Front.",0
sp2_join_oath_ash: db "%s swore to the Cinder Front as ash-sworn.",0

global hg_cmd_steal
hg_cmd_steal:
    call setup_cmd
    cmp qword [r12+SESSION_ROOM],ROOM_MARKET
    jne .bad
    sub qword [r12+SESSION_MORALITY],8
    add qword [r12+SESSION_GOLD],12
    lea rdi,[r12+SESSION_NAME]
    mov esi,DEED_STOLEN
    call hg_add_deed_h
    mov rdi,r12
    call hg_store_save wrt ..plt
    sub rsp,168
    mov rdi,rsp
    mov esi,120
    lea rdx,[rel sp2_steal_shout]
    lea rcx,[r12+SESSION_NAME]
    xor eax,eax
    call snprintf wrt ..plt
    mov rdi,[r12+SESSION_ROOM]
    mov rsi,rsp
    lea rdx,[r12+SESSION_NAME]
    call hg_deliver_room wrt ..plt
    add rsp,168
    mov rdi,r12
    lea rsi,[rel sp2_steal_prose]
    call queue_line_h
    mov rdi,[r12+SESSION_ROOM]
    call hg_room_id_cstr wrt ..plt
    mov rsi,rax
    mov rdi,r12
    call hg_emit_vitals_now wrt ..plt
    mov rdi,r12
    call hg_emit_affects_now wrt ..plt
    call moral_arc_h
    ret
.bad: mov rdi,r12
    lea rsi,[rel sp2_steal_bad]
    jmp queue_line_h

global hg_cmd_look_player
hg_cmd_look_player:
    ; world.asm keeps the command line in r14 across look_player -> look_mob.
    push r14
    push r15
    push rbx
    call setup_cmd
    mov r15, rdx                      ; arg (do not clobber caller's r14)
    test r15, r15
    jz .miss
    mov rdi, r15
    call skip_spaces
    mov r15, rax
    cmp byte [r15], 0
    je .miss
    mov rdi, [r12 + SESSION_ROOM]
    mov rsi, r15
    lea rdx, [r12 + SESSION_NAME]
    call find_player_prefix
    test rax, rax
    jz .miss
    mov r14, rax                      ; target session
    ; 3 pushes left rsp≡0; keep 0-mod-16 locals so C calls stay aligned.
    sub rsp, 656
    mov rdi, r14
    call hg_brand_standing wrt ..plt
    mov rbx, rax
    test rbx, rbx
    jz .plain
    cmp byte [rbx], 0
    je .plain
    cmp byte [r14 + SESSION_TITLE], 0
    je .brand
    mov rdi, rsp
    mov esi, 240
    lea rdx, [rel sp2_look_brand_title]
    lea rcx, [r14 + SESSION_NAME]
    lea r8, [r14 + SESSION_TITLE]
    mov r9, rbx
    xor eax, eax
    call snprintf wrt ..plt
    jmp .queued
.brand:
    mov rdi, rsp
    mov esi, 240
    lea rdx, [rel sp2_look_brand]
    lea rcx, [r14 + SESSION_NAME]
    mov r8, rbx
    xor eax, eax
    call snprintf wrt ..plt
    jmp .queued
.plain:
    mov rdi, rsp
    mov esi, 240
    lea rdx, [rel sp2_look_plain]
    lea rcx, [r14 + SESSION_NAME]
    xor eax, eax
    call snprintf wrt ..plt
.queued:
    mov rdi, r12
    mov rsi, rsp
    call queue_line_h
    lea rdi, [rsp + 240]
    mov esi, 80
    lea rdx, [r14 + SESSION_NAME]
    call hg_json_escape wrt ..plt
    lea rdi, [rsp + 320]
    mov esi, 80
    lea rdx, [r14 + SESSION_TITLE]
    call hg_json_escape wrt ..plt
    lea rdi, [rsp + 400]
    mov esi, 40
    lea rdx, [r14 + SESSION_FACTION]
    call hg_json_escape wrt ..plt
    mov rdi, r14
    call regard_of_ptr
    lea rdi, [rsp + 440]
    mov esi, 40
    mov rdx, rax
    call hg_json_escape wrt ..plt
    cmp qword [r14 + SESSION_ASHSWORN], 0
    lea r9, [rel sp2_false]
    je .bool
    lea r9, [rel sp2_true]
.bool:
    sub rsp, 16
    mov [rsp], r9
    lea rax, [rsp + 456]
    mov [rsp + 8], rax
    lea rdi, [rsp + 496]
    mov esi, 168
    lea rdx, [rel sp2_look_evt]
    lea rcx, [rsp + 256]
    lea r8, [rsp + 336]
    lea r9, [rsp + 416]
    xor eax, eax
    call snprintf wrt ..plt
    mov rdi, r12
    lea rsi, [rsp + 496]
    call queue_cstr_h
    add rsp, 16
    add rsp, 656
    pop rbx
    pop r15
    pop r14
    mov eax, 1
    ret
.miss:
    pop rbx
    pop r15
    pop r14
    xor eax, eax
    ret

global hg_cmd_cache, hg_cmd_gather, hg_cmd_who, hg_cmd_reckoning, hg_moral_arc_now


; --- complete handlers (replace shims) ---

hg_cmd_who:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    call hg_emit_grid_who_now wrt ..plt
    add rsp, 8
    ret

hg_cmd_reckoning:
    call setup_cmd
    sub rsp, 8
    mov rdi, r12
    call hg_emit_char_reckoning_now wrt ..plt
    add rsp, 8
    ret

hg_cmd_cache:
    call setup_cmd
    mov r14,rdx
    xor rax,rax
    test r14,r14
    jz .need
    mov rdi,r14
    call skip_spaces
    mov rdi,rax
    call atoll wrt ..plt
    test rax,rax
    jle .need
    mov r14,rax
    mov rax,[r12+SESSION_GOLD]
    cmp rax,r14
    jl .short
    sub [r12+SESSION_GOLD],r14
    mov rax,[r12+SESSION_ROOM]
    cmp rax,0
    jl .out
    cmp rax,64
    jge .out
    lea r11, [rel cache_gold]
    add qword [r11 + rax*8], r14
    add qword [r12+SESSION_MORALITY],2
    mov rdi,r12
    call hg_store_save wrt ..plt
    sub rsp,280
    mov rdi,rsp
    mov esi,160
    lea rdx,[rel sp2_cache_echo]
    lea rcx,[r12+SESSION_NAME]
    xor eax,eax
    call snprintf wrt ..plt
    mov rdi,[r12+SESSION_ROOM]
    call hg_room_id_cstr wrt ..plt
    mov rdi,rax
    test rdi,rdi
    jnz .node
    lea rdi,[rel sp2_nexus]
.node:
    lea rsi,[rel sp2_aid_kind]
    mov rdx,rsp
    call hg_grid_record_local_echo wrt ..plt
    lea rdi,[rsp+160]
    mov esi,120
    lea rdx,[rel sp2_cache_prose]
    mov rcx,r14
    xor eax,eax
    call snprintf wrt ..plt
    mov rdi,r12
    lea rsi,[rsp+160]
    call queue_line_h
    mov rdi,[r12+SESSION_ROOM]
    call hg_room_id_cstr wrt ..plt
    mov rsi,rax
    mov rdi,r12
    call hg_emit_vitals_now wrt ..plt
    mov rdi,r12
    call hg_emit_affects_now wrt ..plt
    add rsp,280
    ret
.short:
    sub rsp,136
    mov rdi,rsp
    mov esi,120
    lea rdx,[rel sp2_cache_short]
    mov rcx,r14
    mov r8,[r12+SESSION_GOLD]
    xor eax,eax
    call snprintf wrt ..plt
    mov rdi,r12
    mov rsi,rsp
    call queue_line_h
    add rsp,136
    ret
.need:
    mov rdi,r12
    lea rsi,[rel sp2_cache_need]
    jmp queue_line_h
.out:
    ret
sp2_aid_kind: db "aid",0

hg_cmd_gather:
    call setup_cmd
    mov rax,[r12+SESSION_ROOM]
    cmp rax,0
    jl .gnone
    cmp rax,64
    jge .gnone
    lea r11, [rel cache_gold]
    mov r14, [r11 + rax*8]
    test r14,r14
    jle .gnone
    lea r11, [rel cache_gold]
    mov qword [r11 + rax*8], 0
    add [r12+SESSION_GOLD],r14
    mov rdi,r12
    call hg_store_save wrt ..plt
    sub rsp,216
    mov rdi,rsp
    mov esi,200
    lea rdx,[rel sp2_gather_prose]
    mov rcx,r14
    mov r8,[r12+SESSION_GOLD]
    xor eax,eax
    call snprintf wrt ..plt
    mov rdi,r12
    mov rsi,rsp
    call queue_line_h
    mov rdi,[r12+SESSION_ROOM]
    call hg_room_id_cstr wrt ..plt
    mov rsi,rax
    mov rdi,r12
    call hg_emit_vitals_now wrt ..plt
    add rsp,216
    ret
.gnone:
    mov rdi,r12
    lea rsi,[rel sp2_gather_none]
    jmp queue_line_h

hg_moral_arc_now:
    mov r12, rdi
    jmp moral_arc_h
