; Room action menus, brand standing, dream selection, prune kinds: asm owns
; the decisions. C only serializes @event / hub transport around them.
default rel
%include "state.inc"

extern snprintf, strlen, strcpy, strncpy, strcmp, strcasecmp

section .rodata
act_front: db "front", 0
act_ally: db "ally", 0
act_elf: db "elf", 0
act_dustkin: db "dustkin", 0

act_m_defend:
    db '{"verb":"defend","label":"stand with the people the Front would erase",'
    db '"kind":"moral","valence":"virtuous"}', 0
act_m_join_grave:
    db '{"verb":"join","label":"take the Front coin and help sort the living",'
    db '"kind":"moral","valence":"grave"}', 0
act_m_join_corrupt:
    db '{"verb":"join","label":"take the Front coin and help sort the living",'
    db '"kind":"moral","valence":"corrupt"}', 0
act_m_sell:
    db '{"verb":"sell","label":"sell salvage for honest coin","kind":"trade"}', 0
act_m_steal:
    db '{"verb":"steal","label":"steal from the vendor (quick gold, corrupting)",'
    db '"kind":"moral","valence":"corrupt"}', 0

act_tavern:
    db '[{"verb":"talk","label":"talk to whoever shares your room","kind":"social"},'
    db '{"verb":"buy dust","label":"buy dust: 10 gold a packet '
    db '(using it heals, but addicts and corrupts)","kind":"moral","valence":"corrupt"}]', 0

act_d_defy:
    db '{"verb":"defy","label":"defy the Ashmonger and defect to the free folk",'
    db '"kind":"moral","valence":"virtuous"}', 0
act_d_talk:
    db '{"verb":"talk","label":"face the Ashmonger","kind":"social"}', 0
act_d_join_grave:
    db '{"verb":"join","label":"kneel to the Ashmonger against your own (the kapo)",'
    db '"kind":"moral","valence":"grave"}', 0
act_d_join_corrupt:
    db '{"verb":"join","label":"pledge yourself to the Cinder Front",'
    db '"kind":"moral","valence":"corrupt"}', 0

brand_ash: db "ash-sworn", 0
brand_front: db "Cinder Front", 0
brand_ally: db "Free Folk ally", 0
brand_beacon: db "a beacon of the wastes", 0
brand_reviled: db "reviled", 0
brand_empty: db 0

dream_personal_fmt:
    db "You dream of %s, the way they looked when you cut them loose -- "
    db "and the Grid, stubborn, keeping that face lit in the dark so you "
    db "cannot pretend it did not happen.", 0
dream_front:
    db "You dream of a coin that will not stop being warm in your hand, "
    db "and a line of faces that have learned not to look at you.", 0
dream_good:
    db "You dream of names you spoke once into dead static -- and the "
    db "static, impossibly, speaking them back to you, one by one, "
    db "refusing to forget.", 0
dream_bad:
    db "You dream of a ledger writing itself in the dark, every line a "
    db "thing you told yourself did not count.", 0
dream_neutral:
    db "You dream of the wastes seen from above, the dead network laid "
    db "out like veins -- and somewhere down in it, a single cursor, "
    db "blinking your name, waiting to see what you make of it.", 0

prune_ghost: db "ghost", 0
prune_passage: db "passage", 0
prune_recall: db "recall", 0

section .data.rel.ro progbits alloc noexec write align=8
prune_kinds:
    dq prune_ghost, prune_passage, prune_recall
prune_kinds_n: equ 3

section .text

; rsi=frag, r14=buf, r15d=cap, ebx=first(1/0). Returns eax 0 ok / -1 fail.
; Updates ebx=0. Preserves r12.
add_action:
    push rbx
    mov rdi, r14
    call strlen wrt ..plt
    mov ecx, eax
    test ebx, ebx
    jnz .no_comma
    cmp ecx, 1
    jb .fail_pop
    lea edx, [ecx + 1]
    cmp edx, r15d
    jge .fail_pop
    mov byte [r14 + rcx], ","
    mov byte [r14 + rcx + 1], 0
    inc ecx
.no_comma:
    mov rdi, rsi
    mov ebx, ecx                      ; save offset
    call strlen wrt ..plt
    lea edx, [ebx + eax]
    cmp edx, r15d
    jge .fail_pop
    lea rdi, [r14 + rbx]
    call strcpy wrt ..plt
    pop rbx
    xor ebx, ebx                      ; not first anymore
    xor eax, eax
    ret
.fail_pop:
    pop rbx
    mov eax, -1
    ret

; rdi=session rsi=buf rdx=cap -> eax len or -1
global hg_actions_json_for
hg_actions_json_for:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r14, rsi
    mov r15, rdx
    test r12, r12
    jz .fail
    test r14, r14
    jz .fail
    cmp r15, 8
    jb .fail
    mov rax, [r12 + SESSION_ROOM]
    cmp rax, ROOM_MARKET
    je .market
    cmp rax, ROOM_TAVERN
    je .tavern
    cmp rax, ROOM_DAIS
    je .dais
    mov word [r14], ']' * 256 + '['
    mov byte [r14 + 2], 0
    mov eax, 2
    jmp .done

.tavern:
    lea rsi, [rel act_tavern]
    mov rdi, rsi
    call strlen wrt ..plt
    mov ebx, eax
    lea eax, [ebx + 1]
    cmp rax, r15
    ja .fail
    mov rdi, r14
    lea rsi, [rel act_tavern]
    call strcpy wrt ..plt
    mov eax, ebx
    jmp .done

.market:
    mov byte [r14], "["
    mov byte [r14 + 1], 0
    mov ebx, 1                        ; first=1
    call .flags
    ; r13d: bit0 hunted, bit1 front, bit2 ally, bit3 ash
    test r13d, 6                      ; front|ally
    jnz .m_after_moral
    cmp qword [r12 + SESSION_MKT_RESOLVED], 0
    jne .m_after_moral
    lea rsi, [rel act_m_defend]
    call add_action
    cmp eax, 0
    jl .fail
    test r13d, 1
    jz .m_jc
    lea rsi, [rel act_m_join_grave]
    jmp .m_jd
.m_jc:
    lea rsi, [rel act_m_join_corrupt]
.m_jd:
    call add_action
    cmp eax, 0
    jl .fail
.m_after_moral:
    call .flags
    test r13d, 2                      ; front
    jnz .m_steal
    test r13d, 8                      ; ash
    jnz .m_steal
    lea rsi, [rel act_m_sell]
    call add_action
    cmp eax, 0
    jl .fail
.m_steal:
    lea rsi, [rel act_m_steal]
    call add_action
    cmp eax, 0
    jl .fail
    jmp .close

.dais:
    mov byte [r14], "["
    mov byte [r14 + 1], 0
    mov ebx, 1
    call .flags
    test r13d, 2                      ; front
    jz .d_not_front
    lea rsi, [rel act_d_defy]
    call add_action
    cmp eax, 0
    jl .fail
    lea rsi, [rel act_d_talk]
    call add_action
    cmp eax, 0
    jl .fail
    jmp .close
.d_not_front:
    test r13d, 4                      ; ally
    jnz .d_ally
    test r13d, 1
    jz .d_jc
    lea rsi, [rel act_d_join_grave]
    jmp .d_jd
.d_jc:
    lea rsi, [rel act_d_join_corrupt]
.d_jd:
    call add_action
    cmp eax, 0
    jl .fail
    lea rsi, [rel act_d_talk]
    call add_action
    cmp eax, 0
    jl .fail
    jmp .close
.d_ally:
    lea rsi, [rel act_d_talk]
    call add_action
    cmp eax, 0
    jl .fail
    jmp .close

.close:
    mov rdi, r14
    call strlen wrt ..plt
    cmp eax, r15d
    jge .fail
    mov byte [r14 + rax], "]"
    mov byte [r14 + rax + 1], 0
    mov rdi, r14
    call strlen wrt ..plt
    jmp .done

; sets r13d flags from r12 session
.flags:
    push rax
    push rdi
    push rsi
    xor r13d, r13d
    lea rdi, [r12 + SESSION_RACE]
    lea rsi, [rel act_elf]
    call strcasecmp wrt ..plt
    test eax, eax
    jz .f_hunt
    lea rdi, [r12 + SESSION_RACE]
    lea rsi, [rel act_dustkin]
    call strcasecmp wrt ..plt
    test eax, eax
    jnz .f_fac
.f_hunt:
    or r13d, 1
.f_fac:
    lea rdi, [r12 + SESSION_FACTION]
    lea rsi, [rel act_front]
    call strcmp wrt ..plt
    test eax, eax
    jnz .f_ally
    or r13d, 2
.f_ally:
    lea rdi, [r12 + SESSION_FACTION]
    lea rsi, [rel act_ally]
    call strcmp wrt ..plt
    test eax, eax
    jnz .f_ash
    or r13d, 4
.f_ash:
    cmp qword [r12 + SESSION_ASHSWORN], 0
    je .f_done
    or r13d, 8
.f_done:
    pop rsi
    pop rdi
    pop rax
    ret

.fail:
    mov eax, -1
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

global hg_brand_standing
hg_brand_standing:
    push rbx
    push r12
    sub rsp, 8
    mov rbx, rdi
    test rbx, rbx
    jz .b_empty
    cmp qword [rbx + SESSION_ASHSWORN], 0
    jne .b_ash
    lea rdi, [rbx + SESSION_FACTION]
    lea rsi, [rel act_front]
    call strcmp wrt ..plt
    test eax, eax
    jz .b_front
    lea rdi, [rbx + SESSION_FACTION]
    lea rsi, [rel act_ally]
    call strcmp wrt ..plt
    test eax, eax
    jz .b_ally
    mov rax, [rbx + SESSION_MORALITY]
    cmp rax, 50
    jge .b_beacon
    cmp rax, -50
    jle .b_reviled
.b_empty:
    lea rax, [rel brand_empty]
    add rsp, 8
    pop r12
    pop rbx
    ret
.b_ash:
    lea rax, [rel brand_ash]
    add rsp, 8
    pop r12
    pop rbx
    ret
.b_front:
    lea rax, [rel brand_front]
    add rsp, 8
    pop r12
    pop rbx
    ret
.b_ally:
    lea rax, [rel brand_ally]
    add rsp, 8
    pop r12
    pop rbx
    ret
.b_beacon:
    lea rax, [rel brand_beacon]
    add rsp, 8
    pop r12
    pop rbx
    ret
.b_reviled:
    lea rax, [rel brand_reviled]
    add rsp, 8
    pop r12
    pop rbx
    ret

; rdi=session rsi=text rdx=tcap rcx=subj r8=scap
; eax 1 personal / 0 impersonal / -1 error
global hg_dream_compose
hg_dream_compose:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    mov [rsp], r8
    test r12, r12
    jz .dr_fail
    test r13, r13
    jz .dr_fail
    cmp r14, 32
    jb .dr_fail
    xor ebx, ebx
    lea rdi, [r12 + SESSION_FACTION]
    lea rsi, [rel act_front]
    call strcmp wrt ..plt
    test eax, eax
    jnz .dr_ash
    mov ebx, 1
.dr_ash:
    cmp qword [r12 + SESSION_ASHSWORN], 0
    je .dr_mor
    mov ebx, 1
.dr_mor:
    mov rax, [r12 + SESSION_MORALITY]
    cmp rax, -50
    jg .dr_try_pers
    mov ebx, 1
.dr_try_pers:
    lea rdi, [r12 + SESSION_LAST_FREED]
    cmp byte [rdi], 0
    je .dr_imp
    test ebx, ebx
    jnz .dr_imp
    mov rdi, r13
    mov rsi, r14
    lea rdx, [rel dream_personal_fmt]
    lea rcx, [r12 + SESSION_LAST_FREED]
    xor eax, eax
    call snprintf wrt ..plt
    cmp eax, 0
    jl .dr_fail
    cmp eax, r14d
    jge .dr_fail
    mov rax, [rsp]
    test r15, r15
    jz .dr_pers_ok
    test rax, rax
    jz .dr_pers_ok
    mov rdi, r15
    lea rsi, [r12 + SESSION_LAST_FREED]
    mov rdx, rax
    call strncpy wrt ..plt
    mov rax, [rsp]
    test rax, rax
    jz .dr_pers_ok
    dec rax
    mov byte [r15 + rax], 0
.dr_pers_ok:
    mov eax, 1
    jmp .dr_out
.dr_imp:
    test ebx, ebx
    jz .dr_good
    mov rdi, r13
    mov rsi, r14
    lea rdx, [rel dream_front]
    xor eax, eax
    call snprintf wrt ..plt
    jmp .dr_imp_done
.dr_good:
    mov rax, [r12 + SESSION_MORALITY]
    cmp rax, 25
    jl .dr_bad
    mov rdi, r13
    mov rsi, r14
    lea rdx, [rel dream_good]
    xor eax, eax
    call snprintf wrt ..plt
    jmp .dr_imp_done
.dr_bad:
    cmp rax, -10
    jg .dr_neut
    mov rdi, r13
    mov rsi, r14
    lea rdx, [rel dream_bad]
    xor eax, eax
    call snprintf wrt ..plt
    jmp .dr_imp_done
.dr_neut:
    mov rdi, r13
    mov rsi, r14
    lea rdx, [rel dream_neutral]
    xor eax, eax
    call snprintf wrt ..plt
.dr_imp_done:
    cmp eax, 0
    jl .dr_fail
    cmp eax, r14d
    jge .dr_fail
    xor eax, eax
    jmp .dr_out
.dr_fail:
    mov eax, -1
.dr_out:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

global hg_prune_kind_ambient
hg_prune_kind_ambient:
    test rdi, rdi
    jz .pk_no
    push rbx
    push r12
    sub rsp, 8
    mov rbx, rdi
    xor r12d, r12d
.pk_loop:
    cmp r12d, prune_kinds_n
    jge .pk_miss
    lea r11, [rel prune_kinds]
    mov rsi, [r11 + r12 * 8]
    mov rdi, rbx
    call strcmp wrt ..plt
    test eax, eax
    jz .pk_yes
    inc r12d
    jmp .pk_loop
.pk_miss:
    add rsp, 8
    pop r12
    pop rbx
.pk_no:
    xor eax, eax
    ret
.pk_yes:
    add rsp, 8
    pop r12
    pop rbx
    mov eax, 1
    ret

global hg_prune_ambient_count
hg_prune_ambient_count:
    mov eax, prune_kinds_n
    ret

global hg_prune_ambient_at
hg_prune_ambient_at:
    cmp edi, 0
    jl .pa_null
    cmp edi, prune_kinds_n
    jge .pa_null
    lea r11, [rel prune_kinds]
    movsxd rax, edi
    mov rax, [r11 + rax * 8]
    ret
.pa_null:
    xor eax, eax
    ret
