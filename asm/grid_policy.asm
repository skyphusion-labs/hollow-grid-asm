; whoami/travel identity merge and target matching (policy in asm).
; Wire-format prose/@event lines come from format.c once values are chosen.
default rel
%include "state.inc"

%define WORLD_ROW_SIZE 216
%define WORLD_ID_OFF 0
%define WORLD_URL_OFF 48
%define WORLD_SEEN_OFF 208
%define WORLD_ACTIVE_MS 60000

%define TRACE_ROW_SIZE 344
%define TRACE_WORLD_OFF 0
%define TRACE_NODE_OFF 48
%define TRACE_KIND_OFF 112
%define TRACE_TEXT_OFF 136
%define TRACE_AT_OFF 336

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
%define LOAD_HUB_OFF 128
%define LOAD_FRAME 256
%define POLICY_BUF_SIZE 3072
%define LISTEN_FETCH_LIMIT 20
%define PING_ALL_LIMIT 8
%define PING_ECHO_MAX 6
%define PING_CALL_SLOT 0
%define PING_TEXTS_OFF 16
%define PING_KINDS_OFF 64
%define PING_ATS_OFF 112
%define PING_NODE_OFF 160
%define PING_KINDPTR_OFF 168
%define PING_TEXTPTR_OFF 176
%define PING_ATVAL_OFF 184
%define PING_COUNT_OFF 192
%define PING_ECHO_FRAME 208

section .bss
align 16
travel_rows: resb 8 * 216
travel_buf: resb 512
travel_handoff: resb 1
    resb 7
policy_rows: resb 8 * 216
policy_reach: resd 8
policy_active: resd 8
policy_here: resd 8
policy_buf: resb POLICY_BUF_SIZE
policy_recent: resb LISTEN_FETCH_LIMIT * 344
policy_ping_all: resb PING_ALL_LIMIT * 344
policy_self_world: resq 1

section .rodata
gp_faction_ally: db "ally", 0
gp_faction_front: db "front", 0
gp_who_unreachable:
    db "(the Grid is unreachable; showing your local self)", 13, 10, 0
gp_arg_all: db "all", 0

section .text
extern strncpy, strcasecmp, strcmp, strstr, tolower, rand, memcpy
extern hg_grid_remote, hg_grid_world_name, hg_grid_list_worlds
extern hg_grid_fetch_character
extern hg_grid_fetch_recent, hg_grid_fetch_recent_across
extern hg_grid_local_trace_at
extern hg_grid_local_echo_count, hg_grid_local_echo_ptrs
extern hg_grid_local_trace_count
extern hg_room_id
extern hg_now_ms
extern hg_whoami_reply
extern hg_fmt_grid_travel_unreachable
extern hg_fmt_grid_travel_missing, hg_fmt_grid_travel_here
extern hg_fmt_grid_travel_handoff
extern hg_fmt_grid_worlds_unreachable, hg_fmt_grid_worlds
extern hg_fmt_grid_listen_empty, hg_fmt_grid_listen_echo
extern hg_fmt_grid_listen_trace
extern hg_fmt_grid_ping_echo, hg_fmt_grid_ping_all
extern hg_session_queue
extern setup_cmd, queue_cstr_h

global hg_cmd_whoami
global hg_cmd_travel
global hg_cmd_worlds
global hg_cmd_listen
global hg_cmd_ping
global hg_grid_load_session

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

identity_apply_to_session:
    push rbx
    push r12
    mov rbx, rdi
    mov r12, rsi
    mov rax, [r12 + IDENT_LEVEL]
    mov [rbx + SESSION_LEVEL], rax
    mov rax, [r12 + IDENT_XP]
    mov [rbx + SESSION_XP], rax
    mov rax, [r12 + IDENT_GOLD]
    mov [rbx + SESSION_GOLD], rax
    mov rax, [r12 + IDENT_MORALITY]
    mov [rbx + SESSION_MORALITY], rax
    mov rax, [r12 + IDENT_ASH]
    mov [rbx + SESSION_ASHSWORN], rax
    lea rdi, [rbx + SESSION_FACTION]
    lea rsi, [r12 + IDENT_FACTION]
    mov edx, 16
    call strncpy wrt ..plt
    mov byte [rbx + SESSION_FACTION + 15], 0
    lea rdi, [rbx + SESSION_TITLE]
    lea rsi, [r12 + IDENT_TITLE]
    mov edx, 48
    call strncpy wrt ..plt
    mov byte [rbx + SESSION_TITLE + 47], 0
    lea rdi, [rbx + SESSION_RACE]
    lea rsi, [r12 + IDENT_RACE]
    mov edx, 16
    call strncpy wrt ..plt
    mov byte [rbx + SESSION_RACE + 15], 0
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

hg_cmd_worlds:
    call setup_cmd
    sub rsp, 24
    lea rdi, [rel policy_rows]
    mov esi, 8
    xor edx, edx
    call hg_grid_list_worlds wrt ..plt
    cmp eax, 0
    jl .worlds_unreach
    mov r14d, eax
    call hg_now_ms wrt ..plt
    mov r15, rax
    call hg_grid_world_name wrt ..plt
    mov [rsp + 8], rax
    lea rax, [rel policy_here]
    mov [rsp], rax
    xor ebx, ebx
.worlds_tag:
    cmp ebx, r14d
    jge .worlds_fmt
    mov eax, ebx
    imul rax, WORLD_ROW_SIZE
    lea r8, [rel policy_rows]
    add r8, rax
    lea r10, [rel policy_reach]
    lea r11, [rel policy_active]
    mov dword [r10 + rbx * 4], 0
    mov dword [r11 + rbx * 4], 0
    mov rax, [rsp]
    mov dword [rax + rbx * 4], 0
    mov rax, [r8 + WORLD_SEEN_OFF]
    test rax, rax
    jle .worlds_here
    mov dword [r10 + rbx * 4], 1
    mov rcx, r15
    sub rcx, WORLD_ACTIVE_MS
    cmp rax, rcx
    jle .worlds_here
    mov dword [r11 + rbx * 4], 1
.worlds_here:
    mov rdi, r8
    mov rsi, [rsp + 8]
    call strcmp wrt ..plt
    jnz .worlds_next
    mov rax, [rsp]
    mov dword [rax + rbx * 4], 1
.worlds_next:
    inc ebx
    jmp .worlds_tag
.worlds_fmt:
    sub rsp, 8
    push r14
    lea rdi, [rel policy_buf]
    mov esi, POLICY_BUF_SIZE
    lea rdx, [rel policy_rows]
    lea rcx, [rel policy_reach]
    lea r8, [rel policy_active]
    lea r9, [rel policy_here]
    call hg_fmt_grid_worlds wrt ..plt
    add rsp, 16
    jmp .worlds_emit
.worlds_unreach:
    lea rdi, [rel policy_buf]
    mov esi, POLICY_BUF_SIZE
    call hg_fmt_grid_worlds_unreachable wrt ..plt
.worlds_emit:
    cmp eax, 0
    jl .worlds_done
    mov ecx, eax
    lea rdx, [rel policy_buf]
    call queue_buf_h
.worlds_done:
    add rsp, 24
    ret

hg_cmd_listen:
    call setup_cmd
    sub rsp, 8
    call hg_grid_local_echo_count wrt ..plt
    test eax, eax
    jle .listen_not_echo
    mov r14d, eax
    call rand wrt ..plt
    cdq
    idiv r14d
    mov edi, edx
    sub rsp, 32
    lea rsi, [rsp]
    lea rdx, [rsp + 8]
    lea rcx, [rsp + 16]
    lea r8, [rsp + 24]
    call hg_grid_local_echo_ptrs wrt ..plt
    cmp eax, 0
    jl .listen_echo_bad
    mov rdx, [rsp + 16]
    lea rdi, [rel policy_buf]
    mov esi, POLICY_BUF_SIZE
    call hg_fmt_grid_listen_echo wrt ..plt
.listen_echo_bad:
    add rsp, 32
    jmp .listen_emit
.listen_not_echo:
    call hg_grid_remote wrt ..plt
    test eax, eax
    jnz .listen_remote
    call hg_grid_local_trace_count wrt ..plt
    test eax, eax
    jle .listen_empty
    mov r14d, eax
    call rand wrt ..plt
    cdq
    idiv r14d
    mov edi, edx
    lea rsi, [rel policy_recent]
    call hg_grid_local_trace_at wrt ..plt
    cmp eax, 0
    jl .listen_empty
    call hg_grid_world_name wrt ..plt
    mov r8, rax
    lea rdx, [rel policy_recent + TRACE_TEXT_OFF]
    lea rcx, [rel policy_recent + TRACE_WORLD_OFF]
    lea rdi, [rel policy_buf]
    mov esi, POLICY_BUF_SIZE
    call hg_fmt_grid_listen_trace wrt ..plt
    jmp .listen_emit
.listen_remote:
    mov edi, LISTEN_FETCH_LIMIT
    lea rsi, [rel policy_recent]
    mov edx, LISTEN_FETCH_LIMIT
    lea rcx, [rsp]
    call hg_grid_fetch_recent wrt ..plt
    cmp eax, 0
    jl .listen_empty
    mov r14d, eax
    test r14d, r14d
    jz .listen_empty
    call rand wrt ..plt
    cdq
    idiv r14d
    movsxd rbx, edx
    imul rbx, TRACE_ROW_SIZE
    call hg_grid_world_name wrt ..plt
    mov r8, rax
    lea r10, [rel policy_recent]
    lea rdx, [r10 + rbx + TRACE_TEXT_OFF]
    lea rcx, [r10 + rbx + TRACE_WORLD_OFF]
    lea rdi, [rel policy_buf]
    mov esi, POLICY_BUF_SIZE
    call hg_fmt_grid_listen_trace wrt ..plt
    jmp .listen_emit
.listen_empty:
    lea rdi, [rel policy_buf]
    mov esi, POLICY_BUF_SIZE
    call hg_fmt_grid_listen_empty wrt ..plt
.listen_emit:
    cmp eax, 0
    jl .listen_done
    mov ecx, eax
    lea rdx, [rel policy_buf]
    call queue_buf_h
.listen_done:
    add rsp, 8
    ret

hg_cmd_ping:
    call setup_cmd
    push r14
    push r15
    sub rsp, 8
    sub rsp, PING_ECHO_FRAME
    mov r14, rdx
    test r14, r14
    jz .ping_room
    mov rdi, r14
    lea rsi, [rel gp_arg_all]
    call strcasecmp wrt ..plt
    test eax, eax
    jnz .ping_room
    call hg_grid_remote wrt ..plt
    test eax, eax
    jnz .ping_all_remote
    xor r15d, r15d
    call hg_grid_local_trace_count wrt ..plt
    mov r14d, eax
    xor ebx, ebx
.ping_all_local:
    cmp ebx, r14d
    jge .ping_all_fmt
    cmp r15d, PING_ALL_LIMIT
    jge .ping_all_fmt
    mov edi, ebx
    movsxd rax, r15d
    imul rax, TRACE_ROW_SIZE
    lea r10, [rel policy_ping_all]
    lea rsi, [r10 + rax]
    call hg_grid_local_trace_at wrt ..plt
    cmp eax, 0
    jl .ping_all_next
    movsxd rax, r15d
    imul rax, TRACE_ROW_SIZE
    lea r10, [rel policy_ping_all]
    lea rdi, [r10 + rax + TRACE_WORLD_OFF]
    push rdi
    call hg_grid_world_name wrt ..plt
    mov rsi, rax
    pop rdi
    call strcmp wrt ..plt
    test eax, eax
    jz .ping_all_next
    cmp byte [rdi], 0
    je .ping_all_next
    inc r15d
.ping_all_next:
    inc ebx
    jmp .ping_all_local
.ping_all_remote:
    lea rdi, [rel policy_ping_all]
    mov esi, PING_ALL_LIMIT
    mov edx, PING_ALL_LIMIT
    lea rcx, [rsp + 160]
    call hg_grid_fetch_recent_across wrt ..plt
    cmp eax, 0
    jl .ping_all_zero
    mov r15d, eax
    cmp r15d, PING_ALL_LIMIT
    jle .ping_all_fmt
    mov r15d, PING_ALL_LIMIT
    jmp .ping_all_fmt
.ping_all_zero:
    xor r15d, r15d
.ping_all_fmt:
    lea rdi, [rel policy_buf]
    mov esi, POLICY_BUF_SIZE
    lea rdx, [rel policy_ping_all]
    mov ecx, r15d
    call hg_fmt_grid_ping_all wrt ..plt
    jmp .ping_emit
.ping_room:
    mov rdi, [r12 + SESSION_ROOM]
    call hg_room_id
    mov r15, rax
    mov dword [rsp + PING_COUNT_OFF], 0
    xor ebx, ebx
    call hg_grid_local_echo_count wrt ..plt
    mov r14d, eax
.ping_echo_loop:
    cmp ebx, r14d
    jge .ping_echo_fmt
    cmp dword [rsp + PING_COUNT_OFF], PING_ECHO_MAX
    jge .ping_echo_fmt
    mov edi, ebx
    lea rsi, [rsp + PING_NODE_OFF]
    lea rdx, [rsp + PING_KINDPTR_OFF]
    lea rcx, [rsp + PING_TEXTPTR_OFF]
    lea r8, [rsp + PING_ATVAL_OFF]
    call hg_grid_local_echo_ptrs wrt ..plt
    cmp eax, 0
    jl .ping_echo_next
    mov rdi, [rsp + PING_NODE_OFF]
    test rdi, rdi
    jz .ping_echo_next
    test r15, r15
    jz .ping_echo_next
    mov rsi, r15
    call strcmp wrt ..plt
    test eax, eax
    jnz .ping_echo_next
    mov eax, [rsp + PING_COUNT_OFF]
    mov rcx, [rsp + PING_TEXTPTR_OFF]
    mov [rsp + PING_TEXTS_OFF + rax * 8], rcx
    mov rcx, [rsp + PING_KINDPTR_OFF]
    mov [rsp + PING_KINDS_OFF + rax * 8], rcx
    mov rcx, [rsp + PING_ATVAL_OFF]
    mov [rsp + PING_ATS_OFF + rax * 8], rcx
    inc dword [rsp + PING_COUNT_OFF]
.ping_echo_next:
    inc ebx
    jmp .ping_echo_loop
.ping_echo_fmt:
    lea rdi, [rel policy_buf]
    mov esi, POLICY_BUF_SIZE
    mov rdx, r15
    lea rcx, [rsp + PING_TEXTS_OFF]
    lea r8, [rsp + PING_KINDS_OFF]
    lea r9, [rsp + PING_ATS_OFF]
    mov eax, [rsp + PING_COUNT_OFF]
    mov [rsp + PING_CALL_SLOT], rax
    call hg_fmt_grid_ping_echo wrt ..plt
.ping_emit:
    cmp eax, 0
    jl .ping_done
    mov ecx, eax
    lea rdx, [rel policy_buf]
    call queue_buf_h
.ping_done:
    add rsp, PING_ECHO_FRAME
    add rsp, 8
    pop r15
    pop r14
    ret

hg_grid_load_session:
    push rbx
    push r12
    push r13
    mov r12, rdi
    call hg_grid_remote wrt ..plt
    test eax, eax
    jz .ret0
    test r12, r12
    jz .ret0
    cmp byte [r12 + SESSION_NAME], 0
    je .ret0
    sub rsp, LOAD_FRAME
    lea rdi, [r12 + SESSION_NAME]
    lea rsi, [rsp + LOAD_HUB_OFF]
    call hg_grid_fetch_character wrt ..plt
    cmp eax, 0
    jl .retm1
    cmp byte [rsp + LOAD_HUB_OFF + CHAR_RACE_OFF], 0
    je .ret0f
    lea rdi, [rsp]
    call identity_load_local
    lea rdi, [rsp]
    lea rsi, [rsp + LOAD_HUB_OFF]
    call identity_merge_hub
    mov rdi, r12
    lea rsi, [rsp]
    call identity_apply_to_session
    add rsp, LOAD_FRAME
    mov eax, 1
    jmp .out
.retm1:
    add rsp, LOAD_FRAME
    mov eax, -1
    jmp .out
.ret0f:
    add rsp, LOAD_FRAME
.ret0:
    xor eax, eax
.out:
    pop r13
    pop r12
    pop rbx
    ret
