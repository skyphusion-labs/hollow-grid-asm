; whoami/travel identity merge and target matching (policy in asm).
; Wire-format prose/@event lines come from format.c once values are chosen.
default rel
%include "state.inc"

%define WORLD_ROW_SIZE 216
%define WORLD_ID_OFF 0
%define WORLD_URL_OFF 48

%define CHAR_ROW_SIZE 128
%define CHAR_LEVEL_OFF 0
%define CHAR_XP_OFF 8
%define CHAR_GOLD_OFF 16
%define CHAR_FACTION_OFF 24
%define CHAR_MORALITY_OFF 40
%define CHAR_TITLE_OFF 48
%define CHAR_RACE_OFF 96
%define CHAR_ASH_OFF 112
%define CHAR_PRESENT_OFF 120

%define IDENT_LEVEL 0
%define IDENT_XP 8
%define IDENT_GOLD 16
%define IDENT_FACTION 24
%define IDENT_MORALITY 40
%define IDENT_TITLE 48
%define IDENT_RACE 96
%define IDENT_ASH 112

%define FIELDS_NAME 0
%define FIELDS_LEVEL 8
%define FIELDS_XP 16
%define FIELDS_GOLD 24
%define FIELDS_FACTION 32
%define FIELDS_MORALITY 40
%define FIELDS_TITLE 48
%define FIELDS_RACE 56
%define FIELDS_ASH 64

%define FIELDS_OFF 256
%define WHO_HUB_OFF 128
%define WHO_FRAME 328
%define TRAV_FRAME 16

section .bss
align 16
travel_rows: resb 8 * 216
travel_buf: resb 512
travel_handoff: resb 1
    resb 7

section .rodata
gp_faction_ally: db "ally", 0
gp_faction_front: db "front", 0
gp_who_unreachable:
    db "(the Grid is unreachable; showing your local self)", 13, 10, 0

section .text
extern strncpy, strcasecmp, strcmp, strstr, tolower
extern hg_grid_remote, hg_grid_world_name, hg_grid_list_worlds
extern hg_grid_fetch_character, hg_cmd_worlds
extern hg_whoami_reply
extern hg_fmt_grid_travel_unreachable
extern hg_fmt_grid_travel_missing, hg_fmt_grid_travel_here
extern hg_fmt_grid_travel_handoff
extern hg_session_queue
extern setup_cmd, queue_cstr_h

global hg_cmd_whoami
global hg_cmd_travel

; r12=session, r13=wsi, rdx=buf, rcx=len
queue_buf_h:
    mov rdi, r12
    mov rsi, r13
    ; rdx=buf, rcx=len set by caller
    jmp hg_session_queue

grid_lower_inplace:
    test rdi, rdi
    jz .done
.loop:
    movzx eax, byte [rdi]
    test al, al
    jz .done
    mov esi, eax
    call tolower wrt ..plt
    mov [rdi], al
    inc rdi
    jmp .loop
.done:
    ret

hub_char_canonical:
    cmp dword [rdi + CHAR_PRESENT_OFF], 0
    je .no
    cmp byte [rdi + CHAR_RACE_OFF], 0
    jne .yes
    cmp qword [rdi + CHAR_LEVEL_OFF], 1
    jg .yes
    cmp qword [rdi + CHAR_XP_OFF], 0
    jg .yes
    cmp byte [rdi + CHAR_FACTION_OFF], 0
    jne .yes
    cmp qword [rdi + CHAR_MORALITY_OFF], 0
    jne .yes
.no:
    xor eax, eax
    ret
.yes:
    mov eax, 1
    ret

identity_merge_hub:
    push rbx
    push r12
    sub rsp, 8
    mov rbx, rdi
    mov r12, rsi
    mov rax, [r12 + CHAR_LEVEL_OFF]
    mov [rbx + IDENT_LEVEL], rax
    mov rax, [r12 + CHAR_XP_OFF]
    mov [rbx + IDENT_XP], rax
    mov rax, [r12 + CHAR_GOLD_OFF]
    mov [rbx + IDENT_GOLD], rax
    mov rax, [r12 + CHAR_MORALITY_OFF]
    mov [rbx + IDENT_MORALITY], rax
    lea rdi, [rbx + IDENT_RACE]
    lea rsi, [r12 + CHAR_RACE_OFF]
    mov edx, 16
    call strncpy wrt ..plt
    mov byte [rbx + IDENT_RACE + 15], 0
    lea rdi, [rbx + IDENT_FACTION]
    lea rsi, [rel gp_faction_ally]
    call strcmp wrt ..plt
    test eax, eax
    jz .title
    lea rdi, [rbx + IDENT_FACTION]
    lea rsi, [rel gp_faction_front]
    call strcmp wrt ..plt
    test eax, eax
    jz .title
    lea rdi, [rbx + IDENT_FACTION]
    lea rsi, [r12 + CHAR_FACTION_OFF]
    mov edx, 16
    call strncpy wrt ..plt
    mov byte [rbx + IDENT_FACTION + 15], 0
.title:
    cmp byte [rbx + IDENT_TITLE], 0
    jne .ash
    lea rdi, [rbx + IDENT_TITLE]
    lea rsi, [r12 + CHAR_TITLE_OFF]
    mov edx, 48
    call strncpy wrt ..plt
    mov byte [rbx + IDENT_TITLE + 47], 0
.ash:
    mov rax, [r12 + CHAR_ASH_OFF]
    mov [rbx + IDENT_ASH], rax
    add rsp, 8
    pop r12
    pop rbx
    ret

grid_match_world:
    push rbx
    push r12
    push r13
    push r14
    mov r12, rdi
    mov r13d, esi
    mov r14, rdx
    test r14, r14
    jz .miss
    cmp byte [r14], 0
    je .miss
    xor ebx, ebx
.exact_loop:
    cmp ebx, r13d
    jge .sub
    mov eax, ebx
    imul rax, WORLD_ROW_SIZE
    lea rdi, [r12 + rax + WORLD_ID_OFF]
    mov rsi, r14
    call strcasecmp wrt ..plt
    test eax, eax
    jz .hit
    inc ebx
    jmp .exact_loop
.sub:
    sub rsp, 136
    xor ebx, ebx
.sub_loop:
    cmp ebx, r13d
    jge .sub_done
    mov eax, ebx
    imul rax, WORLD_ROW_SIZE
    lea rdi, [rsp]
    lea rsi, [r12 + rax + WORLD_ID_OFF]
    mov edx, 64
    call strncpy wrt ..plt
    mov byte [rsp + 63], 0
    lea rdi, [rsp + 64]
    mov rsi, r14
    mov edx, 64
    call strncpy wrt ..plt
    mov byte [rsp + 127], 0
    lea rdi, [rsp]
    call grid_lower_inplace
    lea rdi, [rsp + 64]
    call grid_lower_inplace
    lea rdi, [rsp]
    lea rsi, [rsp + 64]
    call strstr wrt ..plt
    test rax, rax
    jnz .sub_hit
    inc ebx
    jmp .sub_loop
.sub_hit:
    add rsp, 136
    mov eax, ebx
    jmp .out
.sub_done:
    add rsp, 136
.miss:
    mov eax, -1
    jmp .out
.hit:
    mov eax, ebx
.out:
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

identity_load_local:
    ; rdi = ident scratch base (caller-owned; not this function's rsp)
    push rbx
    mov rbx, rdi
    mov rax, [r12 + SESSION_LEVEL]
    mov [rbx + IDENT_LEVEL], rax
    mov rax, [r12 + SESSION_XP]
    mov [rbx + IDENT_XP], rax
    mov rax, [r12 + SESSION_GOLD]
    mov [rbx + IDENT_GOLD], rax
    mov rax, [r12 + SESSION_MORALITY]
    mov [rbx + IDENT_MORALITY], rax
    mov rax, [r12 + SESSION_ASHSWORN]
    mov [rbx + IDENT_ASH], rax
    lea rdi, [rbx + IDENT_FACTION]
    lea rsi, [r12 + SESSION_FACTION]
    mov edx, 16
    call strncpy wrt ..plt
    mov byte [rbx + IDENT_FACTION + 15], 0
    lea rdi, [rbx + IDENT_TITLE]
    lea rsi, [r12 + SESSION_TITLE]
    mov edx, 48
    call strncpy wrt ..plt
    mov byte [rbx + IDENT_TITLE + 47], 0
    lea rdi, [rbx + IDENT_RACE]
    lea rsi, [r12 + SESSION_RACE]
    mov edx, 16
    call strncpy wrt ..plt
    mov byte [rbx + IDENT_RACE + 15], 0
    pop rbx
    ret

hg_cmd_whoami:
    call setup_cmd
    sub rsp, WHO_FRAME
    lea rax, [r12 + SESSION_NAME]
    mov [rsp + FIELDS_OFF + FIELDS_NAME], rax
    mov rax, [r12 + SESSION_LEVEL]
    mov [rsp + FIELDS_OFF + FIELDS_LEVEL], rax
    mov rax, [r12 + SESSION_XP]
    mov [rsp + FIELDS_OFF + FIELDS_XP], rax
    mov rax, [r12 + SESSION_GOLD]
    mov [rsp + FIELDS_OFF + FIELDS_GOLD], rax
    lea rax, [r12 + SESSION_FACTION]
    mov [rsp + FIELDS_OFF + FIELDS_FACTION], rax
    mov rax, [r12 + SESSION_MORALITY]
    mov [rsp + FIELDS_OFF + FIELDS_MORALITY], rax
    lea rax, [r12 + SESSION_TITLE]
    mov [rsp + FIELDS_OFF + FIELDS_TITLE], rax
    lea rax, [r12 + SESSION_RACE]
    mov [rsp + FIELDS_OFF + FIELDS_RACE], rax
    mov rax, [r12 + SESSION_ASHSWORN]
    mov [rsp + FIELDS_OFF + FIELDS_ASH], rax
    call hg_grid_remote wrt ..plt
    test eax, eax
    jz .emit
    lea rdi, [rsp]
    call identity_load_local
    lea rdi, [r12 + SESSION_NAME]
    lea rsi, [rsp + WHO_HUB_OFF]
    call hg_grid_fetch_character wrt ..plt
    cmp eax, 0
    jl .unreachable
    lea rdi, [rsp + WHO_HUB_OFF]
    call hub_char_canonical
    test eax, eax
    jz .copy_merged
    lea rdi, [rsp]
    lea rsi, [rsp + WHO_HUB_OFF]
    call identity_merge_hub
.copy_merged:
    lea rax, [rsp + IDENT_FACTION]
    mov [rsp + FIELDS_OFF + FIELDS_FACTION], rax
    mov rax, [rsp + IDENT_MORALITY]
    mov [rsp + FIELDS_OFF + FIELDS_MORALITY], rax
    lea rax, [rsp + IDENT_TITLE]
    mov [rsp + FIELDS_OFF + FIELDS_TITLE], rax
    lea rax, [rsp + IDENT_RACE]
    mov [rsp + FIELDS_OFF + FIELDS_RACE], rax
    mov rax, [rsp + IDENT_ASH]
    mov [rsp + FIELDS_OFF + FIELDS_ASH], rax
    mov rax, [rsp + IDENT_LEVEL]
    mov [rsp + FIELDS_OFF + FIELDS_LEVEL], rax
    mov rax, [rsp + IDENT_XP]
    mov [rsp + FIELDS_OFF + FIELDS_XP], rax
    mov rax, [rsp + IDENT_GOLD]
    mov [rsp + FIELDS_OFF + FIELDS_GOLD], rax
    jmp .emit
.unreachable:
    mov rdi, r12
    lea rsi, [rel gp_who_unreachable]
    call queue_cstr_h
.emit:
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rsp + FIELDS_OFF]
    call hg_whoami_reply wrt ..plt
    add rsp, WHO_FRAME
    ret

hg_cmd_travel:
    call setup_cmd
    test rdx, rdx
    jz .list
    cmp byte [rdx], 0
    je .list
    push rbx
    push r14
    push r15
    mov r14, rdx
    sub rsp, TRAV_FRAME
    mov byte [rel travel_handoff], 0
    lea rdi, [rel travel_rows]
    mov esi, 8
    xor edx, edx
    call hg_grid_list_worlds wrt ..plt
    cmp eax, 0
    jl .unreachable
    mov r15d, eax
    lea rdi, [rel travel_rows]
    mov esi, r15d
    mov rdx, r14
    call grid_match_world
    cmp eax, 0
    jl .missing
    movsxd rbx, eax
    call hg_grid_world_name wrt ..plt
    mov rsi, rax
    lea r8, [rel travel_rows]
    mov rax, rbx
    imul rax, WORLD_ROW_SIZE
    lea rdi, [r8 + rax + WORLD_ID_OFF]
    call strcmp wrt ..plt
    test eax, eax
    jz .here
    mov rax, rbx
    imul rax, WORLD_ROW_SIZE
    lea rdx, [r8 + rax + WORLD_ID_OFF]
    lea rcx, [r8 + rax + WORLD_URL_OFF]
    lea rdi, [rel travel_buf]
    mov esi, 512
    call hg_fmt_grid_travel_handoff wrt ..plt
    mov byte [rel travel_handoff], 1
    jmp .queue
.here:
    call hg_grid_world_name wrt ..plt
    lea rdi, [rel travel_buf]
    mov esi, 512
    mov rdx, rax
    call hg_fmt_grid_travel_here wrt ..plt
    jmp .queue
.missing:
    lea rdi, [rel travel_buf]
    mov esi, 512
    mov rdx, r14
    call hg_fmt_grid_travel_missing wrt ..plt
    jmp .queue
.unreachable:
    lea rdi, [rel travel_buf]
    mov esi, 512
    call hg_fmt_grid_travel_unreachable wrt ..plt
.queue:
    cmp eax, 0
    jl .done
    mov r15d, eax
    mov ecx, r15d
    lea rdx, [rel travel_buf]
    call queue_buf_h
    cmp byte [rel travel_handoff], 0
    je .done
    mov qword [r12 + SESSION_CLOSE], 1
.done:
    add rsp, TRAV_FRAME
    pop r15
    pop r14
    pop rbx
    ret
.list:
    jmp hg_cmd_worlds
