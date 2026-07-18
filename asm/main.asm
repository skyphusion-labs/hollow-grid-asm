default rel

section .rodata

env_listen: db "LISTEN_ADDR", 0
env_world:  db "WORLD_NAME", 0
env_data:   db "DATA_DIR", 0
env_hub_url: db "GRID_HUB_URL", 0
env_hub_token: db "GRID_HUB_TOKEN", 0
env_world_url: db "WORLD_URL", 0
default_addr: db "0.0.0.0:8793", 0
default_host: db "0.0.0.0", 0
default_data: db "data", 0
arg_help: db "--help", 0
arg_h: db "-h", 0
arg_addr: db "--addr", 0
arg_world: db "--world-name", 0
arg_data: db "--data", 0
arg_hub_url: db "--grid-hub-url", 0
arg_world_url: db "--world-url", 0
scan_addr: db "%127[^:]:%d", 0
world_url_fmt: db "ws://127.0.0.1:%d/ws", 0
usage:
    db "hollow-grid-asm -- Basalt Relay world server", 10
    db "Usage: hollow-grid-asm [--addr HOST:PORT] [--world-name NAME] [--data DIR]", 10
    db "                       [--grid-hub-url URL] [--world-url URL]", 10
    db "Environment: LISTEN_ADDR, WORLD_NAME, DATA_DIR, GRID_HUB_URL,", 10
    db "             GRID_HUB_TOKEN, WORLD_URL", 10
    db "Contract: the-hollow-grid/docs/protocol.md", 0
invalid_addr: db "invalid --addr, expected HOST:PORT", 0
store_error: db "failed to initialize character store", 0

extern hg_default_world
extern getenv
extern strcmp
extern sscanf
extern snprintf
extern puts
extern hg_lws_run
extern hg_store_init
extern hg_world_boot
extern hg_grid_boot
extern hg_grid_shutdown

section .bss

host_buffer: resb 128
port_value:  resd 1
data_dir_ptr: resq 1
hub_url_ptr: resq 1
hub_token_ptr: resq 1
world_url_ptr: resq 1
world_url_buffer: resb 160

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
    lea rax, [rel default_data]
    mov [rel data_dir_ptr], rax
    mov qword [rel hub_url_ptr], 0
    mov qword [rel hub_token_ptr], 0
    mov qword [rel world_url_ptr], 0

    lea rdi, [rel env_listen]
    call getenv wrt ..plt
    test rax, rax
    cmovnz r14, rax

    lea rdi, [rel env_world]
    call getenv wrt ..plt
    test rax, rax
    cmovnz r15, rax

    lea rdi, [rel env_data]
    call getenv wrt ..plt
    test rax, rax
    jz .no_env_data
    mov [rel data_dir_ptr], rax
.no_env_data:

    lea rdi, [rel env_hub_url]
    call getenv wrt ..plt
    test rax, rax
    jz .no_env_hub_url
    mov [rel hub_url_ptr], rax
.no_env_hub_url:

    lea rdi, [rel env_hub_token]
    call getenv wrt ..plt
    test rax, rax
    jz .no_env_hub_token
    mov [rel hub_token_ptr], rax
.no_env_hub_token:

    lea rdi, [rel env_world_url]
    call getenv wrt ..plt
    test rax, rax
    jz .args_start
    mov [rel world_url_ptr], rax

.args_start:
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
    mov rdi, [r13 + rbx * 8]
    lea rsi, [rel arg_data]
    call strcmp wrt ..plt
    test eax, eax
    jz .take_data
    mov rdi, [r13 + rbx * 8]
    lea rsi, [rel arg_hub_url]
    call strcmp wrt ..plt
    test eax, eax
    jz .take_hub_url
    mov rdi, [r13 + rbx * 8]
    lea rsi, [rel arg_world_url]
    call strcmp wrt ..plt
    test eax, eax
    jz .take_world_url
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

.take_data:
    inc ebx
    cmp ebx, r12d
    jge .bad
    mov rax, [r13 + rbx * 8]
    mov [rel data_dir_ptr], rax
    inc ebx
    jmp .args

.take_hub_url:
    inc ebx
    cmp ebx, r12d
    jge .bad
    mov rax, [r13 + rbx * 8]
    mov [rel hub_url_ptr], rax
    inc ebx
    jmp .args

.take_world_url:
    inc ebx
    cmp ebx, r12d
    jge .bad
    mov rax, [r13 + rbx * 8]
    mov [rel world_url_ptr], rax
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

    cmp qword [rel world_url_ptr], 0
    jne .have_world_url
    lea rdi, [rel world_url_buffer]
    mov esi, 160
    lea rdx, [rel world_url_fmt]
    mov ecx, [rel port_value]
    xor eax, eax
    call snprintf wrt ..plt
    lea rax, [rel world_url_buffer]
    mov [rel world_url_ptr], rax
.have_world_url:

    mov rdi, [rel data_dir_ptr]
    call hg_store_init
    test eax, eax
    jnz .store_failed

    mov rdi, r15
    mov rsi, [rel world_url_ptr]
    mov rdx, [rel hub_url_ptr]
    mov rcx, [rel hub_token_ptr]
    call hg_grid_boot wrt ..plt

    call hg_world_boot wrt ..plt

    lea rdi, [rel host_buffer]
    mov esi, [rel port_value]
    mov rdx, r15
    call hg_lws_run wrt ..plt
    call hg_grid_shutdown wrt ..plt
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
    jmp .done

.store_failed:
    lea rdi, [rel store_error]
    call puts wrt ..plt
    mov eax, 1

.done:
    add rsp, 8
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret
