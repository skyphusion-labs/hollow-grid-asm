default rel
%include "state.inc"

section .rodata

race_human:    db "human", 0
race_elf:      db "elf", 0
race_revenant: db "revenant", 0
race_ghoul:    db "ghoul", 0
race_chromed:  db "chromed", 0
race_dustkin:  db "dustkin", 0
race_vatborn:  db "vatborn", 0

race_table:
    dq race_human, race_elf, race_revenant, race_ghoul
    dq race_chromed, race_dustkin, race_vatborn

welcome:
    db "Your name enters the custody ledger. Type help if the route is unclear.", 13, 10
welcome_end:
welcome_len: equ welcome_end - welcome

resumed:
    db "The custody ledger returns your prior record.", 13, 10
resumed_end:
resumed_len: equ resumed_end - resumed

store_failed:
    db "The custody ledger could not be read. Try again.", 13, 10
store_failed_end:
store_failed_len: equ store_failed_end - store_failed

faction_none: db "none", 0
position_standing: db "standing", 0
item_shiv: db "shiv", 0

extern hg_banner
extern hg_banner_len
extern hg_race_menu
extern hg_race_menu_len
extern hg_invalid_name
extern hg_invalid_name_len
extern hg_invalid_race
extern hg_invalid_race_len
extern hg_ws_request_write
extern hg_ws_write
extern memcpy
extern memset
extern strcpy
extern strcasecmp
extern hg_emit_scene
extern hg_world_command
extern hg_store_load
extern hg_store_save
extern hg_session_register
extern hg_session_unregister

section .text

global hg_app_session_size
global hg_app_callback
global hg_session_queue

hg_app_session_size:
    mov eax, SESSION_SIZE
    ret

; rdi=session, rsi=wsi, rdx=data, rcx=len
hg_session_queue:
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx

    mov rax, [r12 + SESSION_OUT_LEN]
    mov rdx, SESSION_OUT_CAP
    sub rdx, rax
    cmp r15, rdx
    jbe .copy
    mov r15, rdx
.copy:
    test r15, r15
    jz .request
    lea rdi, [r12 + SESSION_OUT]
    add rdi, rax
    mov rsi, r14
    mov rdx, r15
    call memcpy wrt ..plt
    add [r12 + SESSION_OUT_LEN], r15
.request:
    mov rdi, r13
    call hg_ws_request_write wrt ..plt
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    ret

; bool valid_name(ptr,len)
valid_name:
    cmp rsi, 2
    jb .bad
    cmp rsi, 32
    ja .bad
    xor ecx, ecx
.loop:
    cmp rcx, rsi
    jae .good
    movzx eax, byte [rdi + rcx]
    cmp al, '0'
    jb .special
    cmp al, '9'
    jbe .next
    cmp al, 'A'
    jb .special
    cmp al, 'Z'
    jbe .next
    cmp al, 'a'
    jb .special
    cmp al, 'z'
    jbe .next
.special:
    cmp al, '-'
    je .next
    cmp al, '_'
    jne .bad
.next:
    inc rcx
    jmp .loop
.good:
    mov eax, 1
    ret
.bad:
    xor eax, eax
    ret

; int hg_app_callback(wsi,event,session,input,len)
hg_app_callback:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15
    push rbx
    sub rsp, 264
    mov r12, rdi
    mov r13, rdx
    mov r14, rcx
    mov r15, r8

    cmp esi, HG_EVT_CONNECTED
    je .connected
    cmp esi, HG_EVT_RECEIVE
    je .receive
    cmp esi, HG_EVT_WRITABLE
    je .writable
    cmp esi, HG_EVT_CLOSED
    je .closed
    jmp .ok

.connected:
    mov rdi, r13
    xor esi, esi
    mov edx, SESSION_SIZE
    call memset wrt ..plt
    mov qword [r13 + SESSION_STATE], HG_LOGIN_NAME
    mov qword [r13 + SESSION_ROOM], ROOM_NEXUS
    mov qword [r13 + SESSION_HP], 30
    mov qword [r13 + SESSION_MAX_HP], 30
    mov qword [r13 + SESSION_LEVEL], 1
    mov qword [r13 + SESSION_GOLD], 20
    lea rdi, [r13 + SESSION_FACTION]
    lea rsi, [rel faction_none]
    call strcpy wrt ..plt
    lea rdi, [r13 + SESSION_POSITION]
    lea rsi, [rel position_standing]
    call strcpy wrt ..plt
    mov qword [r13 + SESSION_INVENTORY_COUNT], 1
    lea rdi, [r13 + SESSION_INVENTORY]
    lea rsi, [rel item_shiv]
    call strcpy wrt ..plt
    mov rdi, r13
    mov rsi, r12
    lea rdx, [rel hg_banner]
    mov rcx, [rel hg_banner_len]
    call hg_session_queue
    jmp .ok

.receive:
    cmp r15, 255
    jbe .copy_input
    mov r15, 255
.copy_input:
    mov rdi, rsp
    mov rsi, r14
    mov rdx, r15
    call memcpy wrt ..plt
    mov byte [rsp + r15], 0

    ; Trim trailing spaces and line endings.
.trim_tail:
    test r15, r15
    jz .trim_head
    mov al, [rsp + r15 - 1]
    cmp al, ' '
    je .drop_tail
    cmp al, 9
    je .drop_tail
    cmp al, 10
    je .drop_tail
    cmp al, 13
    jne .trim_head
.drop_tail:
    dec r15
    mov byte [rsp + r15], 0
    jmp .trim_tail

.trim_head:
    mov r14, rsp
.head_loop:
    test r15, r15
    jz .dispatch
    mov al, [r14]
    cmp al, ' '
    je .drop_head
    cmp al, 9
    jne .dispatch
.drop_head:
    inc r14
    dec r15
    jmp .head_loop

.dispatch:
    cmp qword [r13 + SESSION_STATE], HG_LOGIN_NAME
    je .name
    cmp qword [r13 + SESSION_STATE], HG_LOGIN_RACE
    je .race
    mov rdi, r13
    mov rsi, r12
    mov rdx, r14
    call hg_world_command
    jmp .ok

.name:
    mov rdi, r14
    mov rsi, r15
    call valid_name
    test eax, eax
    jnz .save_name
    mov rdi, r13
    mov rsi, r12
    lea rdx, [rel hg_invalid_name]
    mov rcx, [rel hg_invalid_name_len]
    call hg_session_queue
    jmp .ok
.save_name:
    lea rdi, [r13 + SESSION_NAME]
    mov rsi, r14
    mov rdx, r15
    call memcpy wrt ..plt
    mov byte [r13 + SESSION_NAME + r15], 0
    mov rdi, r13
    call hg_store_load
    cmp eax, 1
    je .resume
    test eax, eax
    js .load_failed
    mov qword [r13 + SESSION_STATE], HG_LOGIN_RACE
    mov rdi, r13
    mov rsi, r12
    lea rdx, [rel hg_race_menu]
    mov rcx, [rel hg_race_menu_len]
    call hg_session_queue
    jmp .ok

.resume:
    mov qword [r13 + SESSION_STATE], HG_LOGIN_PLAY
    mov rdi, r13
    mov rsi, r12
    lea rdx, [rel resumed]
    mov ecx, resumed_len
    call hg_session_queue
    mov rdi, r13
    mov rsi, r12
    call hg_emit_scene
    mov rdi, r13
    mov rsi, r12
    call hg_session_register
    jmp .ok

.load_failed:
    mov rdi, r13
    mov rsi, r12
    lea rdx, [rel store_failed]
    mov ecx, store_failed_len
    call hg_session_queue
    jmp .ok

.race:
    cmp r15, 1
    jne .race_name
    movzx eax, byte [r14]
    sub eax, '1'
    cmp eax, 6
    jbe .race_chosen
.race_name:
    xor ebx, ebx
.race_name_loop:
    cmp ebx, 7
    jae .bad_race
    lea rdx, [rel race_table]
    mov rdi, r14
    mov rsi, [rdx + rbx * 8]
    call strcasecmp wrt ..plt
    test eax, eax
    jz .race_name_found
    inc ebx
    jmp .race_name_loop
.race_name_found:
    mov eax, ebx
.race_chosen:
    lea rdx, [rel race_table]
    mov rsi, [rdx + rax * 8]
    lea rdi, [r13 + SESSION_RACE]
    call strcpy wrt ..plt
    mov rdi, r13
    call hg_store_save
    mov qword [r13 + SESSION_STATE], HG_LOGIN_PLAY
    mov rdi, r13
    mov rsi, r12
    lea rdx, [rel welcome]
    mov ecx, welcome_len
    call hg_session_queue
    mov rdi, r13
    mov rsi, r12
    call hg_emit_scene
    mov rdi, r13
    mov rsi, r12
    call hg_session_register
    jmp .ok
.bad_race:
    mov rdi, r13
    mov rsi, r12
    lea rdx, [rel hg_invalid_race]
    mov rcx, [rel hg_invalid_race_len]
    call hg_session_queue
    mov rdi, r13
    mov rsi, r12
    lea rdx, [rel hg_race_menu]
    mov rcx, [rel hg_race_menu_len]
    call hg_session_queue
    jmp .ok

.writable:
    mov rdx, [r13 + SESSION_OUT_LEN]
    test rdx, rdx
    jz .maybe_close
    mov rdi, r12
    lea rsi, [r13 + SESSION_OUT]
    call hg_ws_write wrt ..plt
    mov qword [r13 + SESSION_OUT_LEN], 0
.maybe_close:
    cmp qword [r13 + SESSION_CLOSE], 0
    je .ok
    mov eax, -1
    jmp .return

.closed:
    cmp qword [r13 + SESSION_STATE], HG_LOGIN_PLAY
    jne .clear_closed
    mov rdi, r13
    call hg_store_save
    mov rdi, r13
    call hg_session_unregister
.clear_closed:
    mov qword [r13 + SESSION_OUT_LEN], 0

.ok:
    xor eax, eax
.return:
    add rsp, 264
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

