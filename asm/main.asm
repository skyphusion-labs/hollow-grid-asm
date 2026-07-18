default rel

section .rodata

env_listen: db "LISTEN_ADDR", 0
env_world:  db "WORLD_NAME", 0
default_addr: db "0.0.0.0:8793", 0
default_host: db "0.0.0.0", 0
arg_help: db "--help", 0
arg_h: db "-h", 0
arg_addr: db "--addr", 0
arg_world: db "--world-name", 0
scan_addr: db "%127[^:]:%d", 0
usage:
    db "hollow-grid-asm -- Basalt Relay world server", 10
    db "Usage: hollow-grid-asm [--addr HOST:PORT] [--world-name NAME]", 10
    db "Environment: LISTEN_ADDR, WORLD_NAME", 10
    db "Contract: the-hollow-grid/docs/protocol.md", 0
invalid_addr: db "invalid --addr, expected HOST:PORT", 0

extern hg_default_world
extern getenv
extern strcmp
extern sscanf
extern puts
extern hg_lws_run

section .bss

host_buffer: resb 128
port_value:  resd 1

section .text

global main

main:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15
    push rbx
    sub rsp, 8

    mov r12d, edi
    mov r13, rsi
    lea r14, [rel default_addr]
    lea r15, [rel hg_default_world]

    lea rdi, [rel env_listen]
    call getenv wrt ..plt
    test rax, rax
    cmovnz r14, rax

    lea rdi, [rel env_world]
    call getenv wrt ..plt
    test rax, rax
    cmovnz r15, rax

    mov ebx, 1
.args:
    cmp ebx, r12d
    jge .parse
    mov rdi, [r13 + rbx * 8]
    lea rsi, [rel arg_help]
    call strcmp wrt ..plt
    test eax, eax
    jz .show_help
    mov rdi, [r13 + rbx * 8]
    lea rsi, [rel arg_h]
    call strcmp wrt ..plt
    test eax, eax
    jz .show_help
    mov rdi, [r13 + rbx * 8]
    lea rsi, [rel arg_addr]
    call strcmp wrt ..plt
    test eax, eax
    jz .take_addr
    mov rdi, [r13 + rbx * 8]
    lea rsi, [rel arg_world]
    call strcmp wrt ..plt
    test eax, eax
    jz .take_world
    jmp .bad

.take_addr:
    inc ebx
    cmp ebx, r12d
    jge .bad
    mov r14, [r13 + rbx * 8]
    inc ebx
    jmp .args

.take_world:
    inc ebx
    cmp ebx, r12d
    jge .bad
    mov r15, [r13 + rbx * 8]
    inc ebx
    jmp .args

.parse:
    mov dword [rel port_value], 0
    mov rdi, r14
    lea rsi, [rel scan_addr]
    lea rdx, [rel host_buffer]
    lea rcx, [rel port_value]
    xor eax, eax
    call sscanf wrt ..plt
    cmp eax, 2
    jne .bad
    mov eax, [rel port_value]
    cmp eax, 1
    jl .bad
    cmp eax, 65535
    jg .bad

    lea rdi, [rel host_buffer]
    mov esi, eax
    mov rdx, r15
    call hg_lws_run wrt ..plt
    jmp .done

.show_help:
    lea rdi, [rel usage]
    call puts wrt ..plt
    xor eax, eax
    jmp .done

.bad:
    lea rdi, [rel invalid_addr]
    call puts wrt ..plt
    mov eax, 2

.done:
    add rsp, 8
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

