; LocalHub in-memory federation store. Asm owns mutations + tide clamp.
; C (grid_hub.c) keeps RemoteHub libcurl/cJSON and prose/@event wrappers.
default rel
%include "state.inc"

%define GL_MAX_TRACES  200
%define GL_MAX_ECHO    128
%define GL_MAX_RESCUED 200
%define GL_MAX_FALLEN  200
%define GL_MAX_CASTS   200

%define TRACE_WORLD 0
%define TRACE_NODE  48
%define TRACE_KIND  112
%define TRACE_TEXT  136
%define TRACE_AT    336
%define TRACE_SIZE  344

%define ECHO_NODE 0
%define ECHO_KIND 64
%define ECHO_TEXT 88
%define ECHO_AT   288
%define ECHO_SIZE 296

%define RESC_WORLD 0
%define RESC_NAME  48
%define RESC_BY    88
%define RESC_AT    128
%define RESC_SIZE  136

%define FALL_WORLD 0
%define FALL_NAME  48
%define FALL_ROOM  88
%define FALL_AT    120
%define FALL_SIZE  128

%define CAST_ID     0
%define CAST_WORLD  4
%define CAST_SENDER 52
%define CAST_TEXT   85
%define CAST_SIZE   328

; C hg_grid_*_row layouts (verified offsetof)
%define C_RESC_SIZE 128
%define C_RESC_NAME 48
%define C_RESC_BY   81
%define C_RESC_AT   120
%define C_FALL_SIZE 128
%define C_FALL_NAME 48
%define C_FALL_ROOM 81
%define C_FALL_AT   120
%define C_LEDGER_SIZE 36
%define C_LEDGER_COUNT 32
%define C_CAST_SIZE 328

extern hg_now_ms, hg_prune_kind_ambient
extern memset, strcmp, snprintf

section .bss
gl_world_name: resb 64
gl_world_url:  resb 160
gl_tide:       resd 1
gl_trace_n:    resd 1
gl_echo_n:     resd 1
gl_rescued_n:  resd 1
gl_fallen_n:   resd 1
gl_cast_n:     resd 1
gl_next_cast:  resd 1
resb 4
gl_traces:     resb GL_MAX_TRACES * TRACE_SIZE
gl_echo:       resb GL_MAX_ECHO * ECHO_SIZE
gl_rescued:    resb GL_MAX_RESCUED * RESC_SIZE
gl_fallen:     resb GL_MAX_FALLEN * FALL_SIZE
gl_casts:      resb GL_MAX_CASTS * CAST_SIZE

section .rodata
gl_empty: db 0
gl_pct_s: db "%s", 0
gl_seed_w0: db "Dustfall", 0
gl_seed_n0: db "the long market", 0
gl_seed_k0: db "slain", 0
gl_seed_t0: db "a trader put down a chrome-jackal with a length of pipe.", 0
gl_seed_w1: db "the Ninth Server", 0
gl_seed_n1: db "cell block C", 0
gl_seed_k1: db "oath", 0
gl_seed_t1: db "someone swore off the dust for the ninth time.", 0
gl_seed_w2: db "Saltreach", 0
gl_seed_n2: db "the drowned pier", 0
gl_seed_k2: db "death", 0
gl_seed_t2: db "a runner called Mox bled out, cursing the tide.", 0
gl_seed_w3: db "Basalt Relay", 0
gl_seed_n3: db "nexus", 0
gl_seed_k3: db "ghost", 0
gl_seed_t3: db "a faint cursor blinks once and is gone.", 0
gl_seed_n4: db "market", 0
gl_seed_k4: db "passage", 0
gl_seed_t4: db "someone passed through without leaving a name.", 0
gl_seed_n5: db "roof", 0
gl_seed_k5: db "recall", 0
gl_seed_t5: db "a half-remembered transmission dissolves into static.", 0
gl_rescue_kind: db "rescue", 0
gl_rescue_node: db "rescued", 0
gl_rescue_fmt: db "%s freed by %s", 0
gl_reg_kind: db "register", 0
gl_reg_text: db "a new node joined the network.", 0
gl_salt: db "Saltreach", 0
gl_salt_url: db "wss://saltreach.example/ws", 0
gl_dust: db "Dustfall", 0
gl_dust_url: db "wss://dustfall.skyphusion.org/ws", 0

section .text

; rdi=dst esi=cap rdx=src  (safe from any entry alignment)
copy_cap:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    and rsp, -16
    mov rbx, rdi
    mov r12d, esi
    test rdx, rdx
    jnz .ok
    lea rdx, [rel gl_empty]
.ok:
    mov rdi, rbx
    mov esi, r12d
    mov rcx, rdx
    lea rdx, [rel gl_pct_s]
    xor eax, eax
    call snprintf wrt ..plt
    lea rsp, [rbp - 16]
    pop r12
    pop rbx
    pop rbp
    ret

global hg_grid_local_clear
hg_grid_local_clear:
    push rbp
    mov rbp, rsp
    and rsp, -16
    lea rdi, [rel gl_world_name]
    xor esi, esi
    mov edx, 64+160
    call memset wrt ..plt
    mov dword [rel gl_tide], 0
    mov dword [rel gl_trace_n], 0
    mov dword [rel gl_echo_n], 0
    mov dword [rel gl_rescued_n], 0
    mov dword [rel gl_fallen_n], 0
    mov dword [rel gl_cast_n], 0
    mov dword [rel gl_next_cast], 0
    lea rdi, [rel gl_traces]
    xor esi, esi
    mov edx, GL_MAX_TRACES * TRACE_SIZE
    call memset wrt ..plt
    lea rdi, [rel gl_echo]
    xor esi, esi
    mov edx, GL_MAX_ECHO * ECHO_SIZE
    call memset wrt ..plt
    lea rdi, [rel gl_rescued]
    xor esi, esi
    mov edx, GL_MAX_RESCUED * RESC_SIZE
    call memset wrt ..plt
    lea rdi, [rel gl_fallen]
    xor esi, esi
    mov edx, GL_MAX_FALLEN * FALL_SIZE
    call memset wrt ..plt
    lea rdi, [rel gl_casts]
    xor esi, esi
    mov edx, GL_MAX_CASTS * CAST_SIZE
    call memset wrt ..plt
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret

global hg_grid_local_boot
hg_grid_local_boot:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    and rsp, -16
    mov r12, rdi
    mov r13, rsi
    call hg_grid_local_clear
    lea rdi, [rel gl_world_name]
    mov esi, 64
    mov rdx, r12
    call copy_cap
    lea rdi, [rel gl_world_url]
    mov esi, 160
    mov rdx, r13
    call copy_cap
    lea rdi, [rel gl_seed_w0]
    lea rsi, [rel gl_seed_n0]
    lea rdx, [rel gl_seed_k0]
    lea rcx, [rel gl_seed_t0]
    xor r8d, r8d
    call hg_grid_local_record
    lea rdi, [rel gl_seed_w1]
    lea rsi, [rel gl_seed_n1]
    lea rdx, [rel gl_seed_k1]
    lea rcx, [rel gl_seed_t1]
    xor r8d, r8d
    call hg_grid_local_record
    lea rdi, [rel gl_seed_w2]
    lea rsi, [rel gl_seed_n2]
    lea rdx, [rel gl_seed_k2]
    lea rcx, [rel gl_seed_t2]
    xor r8d, r8d
    call hg_grid_local_record
    lea rdi, [rel gl_seed_w3]
    lea rsi, [rel gl_seed_n3]
    lea rdx, [rel gl_seed_k3]
    lea rcx, [rel gl_seed_t3]
    xor r8d, r8d
    call hg_grid_local_record
    lea rdi, [rel gl_seed_w3]
    lea rsi, [rel gl_seed_n4]
    lea rdx, [rel gl_seed_k4]
    lea rcx, [rel gl_seed_t4]
    xor r8d, r8d
    call hg_grid_local_record
    lea rdi, [rel gl_seed_w3]
    lea rsi, [rel gl_seed_n5]
    lea rdx, [rel gl_seed_k5]
    lea rcx, [rel gl_seed_t5]
    xor r8d, r8d
    call hg_grid_local_record
    xor eax, eax
    lea rsp, [rbp - 24]
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

global hg_grid_local_world_name
hg_grid_local_world_name:
    lea rax, [rel gl_world_name]
    ret

global hg_grid_local_world_url
hg_grid_local_world_url:
    lea rax, [rel gl_world_url]
    ret

trace_shift:
    push rbx
    sub rsp, 8
    mov eax, [rel gl_trace_n]
    cmp eax, GL_MAX_TRACES
    jl .n
    mov eax, GL_MAX_TRACES - 1
.n:
    mov ebx, eax
    test ebx, ebx
    jz .bump
.lp:
    mov eax, ebx
    imul eax, TRACE_SIZE
    lea rdi, [rel gl_traces]
    add rdi, rax
    lea rsi, [rdi - TRACE_SIZE]
    mov ecx, TRACE_SIZE
    rep movsb
    dec ebx
    jnz .lp
.bump:
    mov eax, [rel gl_trace_n]
    cmp eax, GL_MAX_TRACES
    jge .out
    inc eax
    mov [rel gl_trace_n], eax
.out:
    add rsp, 8
    pop rbx
    ret

echo_shift:
    push rbx
    sub rsp, 8
    mov eax, [rel gl_echo_n]
    cmp eax, GL_MAX_ECHO
    jl .n
    mov eax, GL_MAX_ECHO - 1
.n:
    mov ebx, eax
    test ebx, ebx
    jz .bump
.lp:
    mov eax, ebx
    imul eax, ECHO_SIZE
    lea rdi, [rel gl_echo]
    add rdi, rax
    lea rsi, [rdi - ECHO_SIZE]
    mov ecx, ECHO_SIZE
    rep movsb
    dec ebx
    jnz .lp
.bump:
    mov eax, [rel gl_echo_n]
    cmp eax, GL_MAX_ECHO
    jge .out
    inc eax
    mov [rel gl_echo_n], eax
.out:
    add rsp, 8
    pop rbx
    ret

global hg_grid_local_record
hg_grid_local_record:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    and rsp, -16
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    mov rbx, r8
    test rbx, rbx
    jnz .at
    call hg_now_ms wrt ..plt
    mov rbx, rax
.at:
    call trace_shift
    lea rdi, [rel gl_traces + TRACE_WORLD]
    mov esi, 48
    mov rdx, r12
    call copy_cap
    lea rdi, [rel gl_traces + TRACE_NODE]
    mov esi, 64
    mov rdx, r13
    call copy_cap
    lea rdi, [rel gl_traces + TRACE_KIND]
    mov esi, 24
    mov rdx, r14
    call copy_cap
    lea rdi, [rel gl_traces + TRACE_TEXT]
    mov esi, 200
    mov rdx, r15
    call copy_cap
    mov [rel gl_traces + TRACE_AT], rbx
    xor eax, eax
    lea rsp, [rbp - 40]
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

global hg_grid_record_local_echo
hg_grid_record_local_echo:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    and rsp, -16
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    call hg_now_ms wrt ..plt
    mov rbx, rax
    call echo_shift
    lea rdi, [rel gl_echo + ECHO_NODE]
    mov esi, 64
    mov rdx, r12
    call copy_cap
    lea rdi, [rel gl_echo + ECHO_KIND]
    mov esi, 24
    mov rdx, r13
    call copy_cap
    lea rdi, [rel gl_echo + ECHO_TEXT]
    mov esi, 200
    mov rdx, r14
    call copy_cap
    mov [rel gl_echo + ECHO_AT], rbx
    xor eax, eax
    lea rsp, [rbp - 32]
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

global hg_grid_local_record_fallen
hg_grid_local_record_fallen:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    and rsp, -16
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    test r15, r15
    jnz .at
    call hg_now_ms wrt ..plt
    mov r15, rax
.at:
    mov eax, [rel gl_fallen_n]
    cmp eax, GL_MAX_FALLEN
    jl .n
    mov eax, GL_MAX_FALLEN - 1
.n:
    mov ebx, eax
    test ebx, ebx
    jz .bump
.lp:
    mov eax, ebx
    imul eax, FALL_SIZE
    lea rdi, [rel gl_fallen]
    add rdi, rax
    lea rsi, [rdi - FALL_SIZE]
    mov ecx, FALL_SIZE
    rep movsb
    dec ebx
    jnz .lp
.bump:
    mov eax, [rel gl_fallen_n]
    cmp eax, GL_MAX_FALLEN
    jge .fill
    inc eax
    mov [rel gl_fallen_n], eax
.fill:
    lea rdi, [rel gl_fallen + FALL_WORLD]
    mov esi, 48
    mov rdx, r12
    call copy_cap
    lea rdi, [rel gl_fallen + FALL_NAME]
    mov esi, 40
    mov rdx, r13
    call copy_cap
    lea rdi, [rel gl_fallen + FALL_ROOM]
    mov esi, 32
    mov rdx, r14
    call copy_cap
    mov [rel gl_fallen + FALL_AT], r15
    xor eax, eax
    lea rsp, [rbp - 40]
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

global hg_grid_local_record_rescued
hg_grid_local_record_rescued:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 320
    and rsp, -16
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    test r15, r15
    jnz .at
    call hg_now_ms wrt ..plt
    mov r15, rax
.at:
    mov eax, [rel gl_rescued_n]
    cmp eax, GL_MAX_RESCUED
    jl .n
    mov eax, GL_MAX_RESCUED - 1
.n:
    mov ebx, eax
    test ebx, ebx
    jz .bump
.lp:
    mov eax, ebx
    imul eax, RESC_SIZE
    lea rdi, [rel gl_rescued]
    add rdi, rax
    lea rsi, [rdi - RESC_SIZE]
    mov ecx, RESC_SIZE
    rep movsb
    dec ebx
    jnz .lp
.bump:
    mov eax, [rel gl_rescued_n]
    cmp eax, GL_MAX_RESCUED
    jge .fill
    inc eax
    mov [rel gl_rescued_n], eax
.fill:
    lea rdi, [rel gl_rescued + RESC_WORLD]
    mov esi, 48
    mov rdx, r12
    call copy_cap
    lea rdi, [rel gl_rescued + RESC_NAME]
    mov esi, 40
    mov rdx, r13
    call copy_cap
    lea rdi, [rel gl_rescued + RESC_BY]
    mov esi, 40
    mov rdx, r14
    call copy_cap
    mov [rel gl_rescued + RESC_AT], r15
    lea rdi, [rbp - 320]
    mov esi, 256
    lea rdx, [rel gl_rescue_fmt]
    mov rcx, r13
    test rcx, rcx
    jnz .nn
    lea rcx, [rel gl_empty]
.nn:
    mov r8, r14
    test r8, r8
    jnz .nb
    lea r8, [rel gl_empty]
.nb:
    xor eax, eax
    call snprintf wrt ..plt
    mov rdi, r12
    lea rsi, [rel gl_rescue_node]
    lea rdx, [rel gl_rescue_kind]
    lea rcx, [rbp - 320]
    mov r8, r15
    call hg_grid_local_record
    xor eax, eax
    lea rsp, [rbp - 40]
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

clamp_tide:
    cmp edi, -100
    jge .lo
    mov eax, -100
    ret
.lo:
    cmp edi, 100
    jle .ok
    mov eax, 100
    ret
.ok:
    mov eax, edi
    ret

global hg_grid_local_tide
hg_grid_local_tide:
    test rdi, rdi
    jz .d
    mov eax, [rel gl_tide]
    mov [rdi], eax
.d:
    xor eax, eax
    ret

global hg_grid_local_shift_tide
hg_grid_local_shift_tide:
    mov eax, [rel gl_tide]
    add eax, edi
    mov edi, eax
    call clamp_tide
    mov [rel gl_tide], eax
    test rsi, rsi
    jz .d
    mov [rsi], eax
.d:
    xor eax, eax
    ret

global hg_grid_local_gridcast
hg_grid_local_gridcast:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    and rsp, -16
    mov r12, rdi
    mov r13, rsi
    mov eax, [rel gl_next_cast]
    inc eax
    mov [rel gl_next_cast], eax
    mov r14d, eax
    mov eax, [rel gl_cast_n]
    xor edx, edx
    mov ecx, GL_MAX_CASTS
    div ecx
    mov eax, edx
    imul eax, CAST_SIZE
    lea rbx, [rel gl_casts]
    add rbx, rax
    mov [rbx + CAST_ID], r14d
    lea rdi, [rbx + CAST_WORLD]
    mov esi, 48
    lea rdx, [rel gl_world_name]
    call copy_cap
    lea rdi, [rbx + CAST_SENDER]
    mov esi, 33
    mov rdx, r12
    call copy_cap
    lea rdi, [rbx + CAST_TEXT]
    mov esi, 240
    mov rdx, r13
    call copy_cap
    mov eax, [rel gl_cast_n]
    cmp eax, GL_MAX_CASTS
    jge .d
    inc eax
    mov [rel gl_cast_n], eax
.d:
    xor eax, eax
    lea rsp, [rbp - 32]
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

global hg_grid_local_register_self
hg_grid_local_register_self:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    and rsp, -16
    xor ebx, ebx
.lp:
    cmp ebx, [rel gl_trace_n]
    jge .pre
    mov eax, ebx
    imul eax, TRACE_SIZE
    lea r12, [rel gl_traces]
    add r12, rax
    mov rdi, r12
    lea rsi, [rel gl_world_name]
    call strcmp wrt ..plt
    test eax, eax
    jnz .nx
    lea rdi, [r12 + TRACE_NODE]
    mov esi, 64
    lea rdx, [rel gl_world_url]
    call copy_cap
    xor eax, eax
    jmp .out
.nx:
    inc ebx
    jmp .lp
.pre:
    call hg_now_ms wrt ..plt
    mov r8, rax
    lea rdi, [rel gl_world_name]
    lea rsi, [rel gl_world_url]
    lea rdx, [rel gl_reg_kind]
    lea rcx, [rel gl_reg_text]
    call hg_grid_local_record
    xor eax, eax
.out:
    lea rsp, [rbp - 16]
    pop r12
    pop rbx
    pop rbp
    ret

global hg_grid_local_prune
hg_grid_local_prune:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    and rsp, -16
    mov r14, rdi
    mov r13d, [rel gl_trace_n]
    xor ebx, ebx
    xor r12d, r12d
.lp:
    cmp ebx, r13d
    jge .done
    mov eax, ebx
    imul eax, TRACE_SIZE
    lea rdi, [rel gl_traces + TRACE_KIND]
    add rdi, rax
    call hg_prune_kind_ambient wrt ..plt
    test eax, eax
    jnz .sk
    cmp r12d, ebx
    je .keep
    mov eax, r12d
    imul eax, TRACE_SIZE
    lea rdi, [rel gl_traces]
    add rdi, rax
    mov eax, ebx
    imul eax, TRACE_SIZE
    lea rsi, [rel gl_traces]
    add rsi, rax
    mov ecx, TRACE_SIZE
    rep movsb
.keep:
    inc r12d
.sk:
    inc ebx
    jmp .lp
.done:
    mov eax, r13d
    sub eax, r12d
    mov [rel gl_trace_n], r12d
    test r14, r14
    jz .ret
    mov [r14], eax
.ret:
    xor eax, eax
    lea rsp, [rbp - 32]
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

global hg_grid_local_recent_rescued
hg_grid_local_recent_rescued:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    and rsp, -16
    mov r12d, edi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    test r15, r15
    jz .z
    mov qword [r15], 0
.z:
    mov eax, [rel gl_rescued_n]
    cmp rax, r14
    jbe .c
    mov eax, r14d
.c:
    test r12d, r12d
    jle .l
    cmp eax, r12d
    jbe .l
    mov eax, r12d
.l:
    mov ebx, eax
    xor r12d, r12d
.lp:
    cmp r12d, ebx
    jge .done
    mov eax, r12d
    imul eax, RESC_SIZE
    lea r8, [rel gl_rescued]
    add r8, rax
    mov eax, r12d
    imul eax, C_RESC_SIZE
    lea r9, [r13]
    add r9, rax
    lea rdi, [r9]
    mov esi, 48
    mov rdx, r8
    push r8
    push r9
    call copy_cap
    pop r9
    pop r8
    lea rdi, [r9 + C_RESC_NAME]
    mov esi, 33
    lea rdx, [r8 + RESC_NAME]
    push r8
    push r9
    call copy_cap
    pop r9
    pop r8
    lea rdi, [r9 + C_RESC_BY]
    mov esi, 33
    lea rdx, [r8 + RESC_BY]
    push r8
    push r9
    call copy_cap
    pop r9
    pop r8
    mov rax, [r8 + RESC_AT]
    mov [r9 + C_RESC_AT], rax
    inc r12d
    jmp .lp
.done:
    test r15, r15
    jz .ret
    mov [r15], r12
.ret:
    xor eax, eax
    lea rsp, [rbp - 40]
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

global hg_grid_local_recent_fallen
hg_grid_local_recent_fallen:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    and rsp, -16
    mov r12d, edi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    test r15, r15
    jz .z
    mov qword [r15], 0
.z:
    mov eax, [rel gl_fallen_n]
    cmp rax, r14
    jbe .c
    mov eax, r14d
.c:
    test r12d, r12d
    jle .l
    cmp eax, r12d
    jbe .l
    mov eax, r12d
.l:
    mov ebx, eax
    xor r12d, r12d
.lp:
    cmp r12d, ebx
    jge .done
    mov eax, r12d
    imul eax, FALL_SIZE
    lea r8, [rel gl_fallen]
    add r8, rax
    mov eax, r12d
    imul eax, C_FALL_SIZE
    lea r9, [r13]
    add r9, rax
    lea rdi, [r9]
    mov esi, 48
    mov rdx, r8
    push r8
    push r9
    call copy_cap
    pop r9
    pop r8
    lea rdi, [r9 + C_FALL_NAME]
    mov esi, 33
    lea rdx, [r8 + FALL_NAME]
    push r8
    push r9
    call copy_cap
    pop r9
    pop r8
    lea rdi, [r9 + C_FALL_ROOM]
    mov esi, 32
    lea rdx, [r8 + FALL_ROOM]
    push r8
    push r9
    call copy_cap
    pop r9
    pop r8
    mov rax, [r8 + FALL_AT]
    mov [r9 + C_FALL_AT], rax
    inc r12d
    jmp .lp
.done:
    test r15, r15
    jz .ret
    mov [r15], r12
.ret:
    xor eax, eax
    lea rsp, [rbp - 40]
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

global hg_grid_local_ledger_stats
hg_grid_local_ledger_stats:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    and rsp, -16
    mov r13, rdi
    mov r14, rsi
    mov r15, rdx
    test r15, r15
    jz .z
    mov qword [r15], 0
.z:
    xor r12d, r12d
    xor ebx, ebx
.lp:
    cmp ebx, [rel gl_trace_n]
    jge .done
    mov eax, ebx
    imul eax, TRACE_SIZE
    lea r8, [rel gl_traces + TRACE_KIND]
    add r8, rax
    xor ecx, ecx
.find:
    cmp ecx, r12d
    jge .new
    mov eax, ecx
    imul eax, C_LEDGER_SIZE
    lea rdi, [r13]
    add rdi, rax
    mov rsi, r8
    push rcx
    push r8
    call strcmp wrt ..plt
    pop r8
    pop rcx
    test eax, eax
    jnz .nk
    mov eax, ecx
    imul eax, C_LEDGER_SIZE
    inc dword [r13 + rax + C_LEDGER_COUNT]
    jmp .adv
.nk:
    inc ecx
    jmp .find
.new:
    cmp r12, r14
    jae .adv
    mov eax, r12d
    imul eax, C_LEDGER_SIZE
    lea rdi, [r13]
    add rdi, rax
    mov esi, 32
    mov rdx, r8
    call copy_cap
    mov eax, r12d
    imul eax, C_LEDGER_SIZE
    mov dword [r13 + rax + C_LEDGER_COUNT], 1
    inc r12d
.adv:
    inc ebx
    jmp .lp
.done:
    test r15, r15
    jz .ret
    mov [r15], r12
.ret:
    xor eax, eax
    lea rsp, [rbp - 40]
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

global hg_grid_local_casts_since
hg_grid_local_casts_since:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32
    and rsp, -16
    mov r12d, edi
    mov r13d, esi
    mov r14, rdx
    mov r15, rcx
    mov [rbp - 48], r8
    test r8, r8
    jz .z
    mov qword [r8], 0
.z:
    mov dword [rbp - 56], 0
    xor ebx, ebx
.lp:
    cmp ebx, [rel gl_cast_n]
    jge .trim
    mov eax, ebx
    imul eax, CAST_SIZE
    lea r8, [rel gl_casts]
    add r8, rax
    mov eax, [r8 + CAST_ID]
    cmp eax, r12d
    jle .nx
    mov eax, [rbp - 56]
    cmp rax, r15
    jae .trim
    imul eax, C_CAST_SIZE
    lea r9, [r14]
    add r9, rax
    mov eax, [r8 + CAST_ID]
    mov [r9], eax
    lea rdi, [r9 + 4]
    mov esi, 48
    lea rdx, [r8 + CAST_WORLD]
    push r8
    push r9
    call copy_cap
    pop r9
    pop r8
    lea rdi, [r9 + 52]
    mov esi, 33
    lea rdx, [r8 + CAST_SENDER]
    push r8
    push r9
    call copy_cap
    pop r9
    pop r8
    lea rdi, [r9 + 85]
    mov esi, 240
    lea rdx, [r8 + CAST_TEXT]
    call copy_cap
    inc dword [rbp - 56]
.nx:
    inc ebx
    jmp .lp
.trim:
    mov eax, [rbp - 56]
    test r13d, r13d
    jle .st
    cmp eax, r13d
    jbe .st
    mov eax, r13d
.st:
    mov rdx, [rbp - 48]
    test rdx, rdx
    jz .ret
    mov [rdx], rax
.ret:
    xor eax, eax
    lea rsp, [rbp - 40]
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

global hg_grid_local_echo_count
hg_grid_local_echo_count:
    mov eax, [rel gl_echo_n]
    ret

global hg_grid_local_trace_count
hg_grid_local_trace_count:
    mov eax, [rel gl_trace_n]
    ret

; Returns pointers into BSS (const). edi=index
; rsi=char**node rdx=char**kind rcx=char**text r8=ll*at
global hg_grid_local_echo_ptrs
hg_grid_local_echo_ptrs:
    cmp edi, [rel gl_echo_n]
    jae .ebad
    mov eax, edi
    imul eax, ECHO_SIZE
    lea r9, [rel gl_echo]
    add r9, rax
    test rsi, rsi
    jz .ek
    mov [rsi], r9
.ek:
    test rdx, rdx
    jz .et
    lea rax, [r9 + ECHO_KIND]
    mov [rdx], rax
.et:
    test rcx, rcx
    jz .ea
    lea rax, [r9 + ECHO_TEXT]
    mov [rcx], rax
.ea:
    test r8, r8
    jz .eok
    mov rax, [r9 + ECHO_AT]
    mov [r8], rax
.eok:
    xor eax, eax
    ret
.ebad:
    mov eax, -1
    ret

global hg_grid_local_trace_ptrs
; edi=idx rsi=world** rdx=node** rcx=kind** r8=text** r9=at*
hg_grid_local_trace_ptrs:
    cmp edi, [rel gl_trace_n]
    jae .bad
    mov eax, edi
    imul eax, TRACE_SIZE
    lea r10, [rel gl_traces]
    add r10, rax
    test rsi, rsi
    jz .n
    mov [rsi], r10
.n:
    test rdx, rdx
    jz .k
    lea rax, [r10 + TRACE_NODE]
    mov [rdx], rax
.k:
    test rcx, rcx
    jz .t
    lea rax, [r10 + TRACE_KIND]
    mov [rcx], rax
.t:
    test r8, r8
    jz .a
    lea rax, [r10 + TRACE_TEXT]
    mov [r8], rax
.a:
    test r9, r9
    jz .ok
    mov rax, [r10 + TRACE_AT]
    mov [r9], rax
.ok:
    xor eax, eax
    ret
.bad:
    mov eax, -1
    ret

global hg_grid_local_list_worlds
; rdi=out rows as: for i in 0..n-1 write id[48] at rdi+i*stride_id etc
; Simpler: rdi = hg_world_row* with id[48] url[160] last_seen i64 -- but C uses local typedef.
; Use: fill three slots into parallel arrays:
; rdi=ids (48 each) rsi=urls (160 each) rdx=seen (8 each) ecx=cap -> eax n
hg_grid_local_list_worlds:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    and rsp, -16
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov ebx, ecx
    xor eax, eax
    test ebx, ebx
    jz .done
    lea rdi, [r12]
    mov esi, 48
    lea rdx, [rel gl_salt]
    call copy_cap
    lea rdi, [r13]
    mov esi, 160
    lea rdx, [rel gl_salt_url]
    call copy_cap
    mov qword [r14], 0
    mov eax, 1
    cmp eax, ebx
    jge .done
    call hg_now_ms wrt ..plt
    mov [r14 + 8], rax
    lea rdi, [r12 + 48]
    mov esi, 48
    lea rdx, [rel gl_dust]
    call copy_cap
    lea rdi, [r13 + 160]
    mov esi, 160
    lea rdx, [rel gl_dust_url]
    call copy_cap
    mov eax, 2
    cmp eax, ebx
    jge .done
    call hg_now_ms wrt ..plt
    mov [r14 + 16], rax
    lea rdi, [r12 + 96]
    mov esi, 48
    lea rdx, [rel gl_world_name]
    call copy_cap
    lea rdi, [r13 + 320]
    mov esi, 160
    lea rdx, [rel gl_world_url]
    call copy_cap
    mov eax, 3
.done:
    lea rsp, [rbp - 32]
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret
