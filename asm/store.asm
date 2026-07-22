default rel
%include "state.inc"

section .rodata

characters_suffix: db "%s/characters", 0
character_path_fmt: db "%s/%s.json", 0
temp_path_fmt: db "%s.tmp", 0
read_mode: db "rb", 0
string_fmt: db "%s", 0

key_name: db "name", 0
key_race: db "race", 0
key_room: db "roomIndex", 0
key_faction: db "faction", 0
key_position: db "position", 0
key_title: db "title", 0
key_weapon: db "weapon", 0
key_hp: db "hp", 0
key_max_hp: db "maxHp", 0
key_level: db "level", 0
key_xp: db "xp", 0
key_gold: db "gold", 0
key_morality: db "morality", 0
key_addiction: db "addiction", 0
key_ashsworn: db "ashsworn", 0
key_strayed: db "strayed", 0
key_redeemed: db "redeemed", 0
key_resisted: db "resisted", 0
key_inventory: db "inventory", 0
key_secret_hash: db "secretHash", 0

section .bss

store_root: resb 512

section .text

extern mkdir
extern __errno_location
extern snprintf
extern strlen
extern fopen
extern fclose
extern fseek
extern ftell
extern fread
extern malloc
extern free
extern open
extern write
extern fsync
extern close
extern rename
extern memset
extern cJSON_Parse
extern cJSON_Delete
extern cJSON_CreateObject
extern cJSON_AddStringToObject
extern cJSON_AddNumberToObject
extern cJSON_AddBoolToObject
extern cJSON_AddArrayToObject
extern cJSON_CreateString
extern cJSON_AddItemToArray
extern cJSON_GetObjectItemCaseSensitive
extern cJSON_GetArraySize
extern cJSON_GetArrayItem
extern cJSON_IsString
extern cJSON_GetStringValue
extern cJSON_GetNumberValue
extern cJSON_IsTrue
extern cJSON_PrintUnformatted

global hg_store_init
global hg_store_load
global hg_store_save

; int make_dir(const char *path)
make_dir:
    sub rsp, 8
    mov esi, 0755o
    call mkdir wrt ..plt
    test eax, eax
    jz .ok
    call __errno_location wrt ..plt
    cmp dword [rax], 17
    jne .bad
.ok:
    xor eax, eax
    add rsp, 8
    ret
.bad:
    mov eax, -1
    add rsp, 8
    ret

; int hg_store_init(const char *data_dir)
hg_store_init:
    push r12
    mov r12, rdi
    call make_dir
    test eax, eax
    jnz .done
    lea rdi, [rel store_root]
    mov esi, 512
    lea rdx, [rel characters_suffix]
    mov rcx, r12
    xor eax, eax
    call snprintf wrt ..plt
    test eax, eax
    jle .fail
    cmp eax, 512
    jge .fail
    lea rdi, [rel store_root]
    call make_dir
    jmp .done
.fail:
    mov eax, -1
.done:
    pop r12
    ret

; int character_path(name, out, out_cap)
character_path:
    push r12
    push r13
    push r14
    sub rsp, 48
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    call strlen wrt ..plt
    test rax, rax
    jz .bad
    cmp rax, 32
    ja .bad
    xor ecx, ecx
.lower:
    cmp rcx, rax
    jae .lower_done
    mov dl, [r12 + rcx]
    cmp dl, 'A'
    jb .store
    cmp dl, 'Z'
    ja .store
    add dl, 32
.store:
    mov [rsp + rcx], dl
    inc rcx
    jmp .lower
.lower_done:
    mov byte [rsp + rax], 0
    mov rdi, r13
    mov rsi, r14
    lea rdx, [rel character_path_fmt]
    lea rcx, [rel store_root]
    mov r8, rsp
    xor eax, eax
    call snprintf wrt ..plt
    test eax, eax
    jle .bad
    cmp rax, r14
    jae .bad
    xor eax, eax
    jmp .done
.bad:
    mov eax, -1
.done:
    add rsp, 48
    pop r14
    pop r13
    pop r12
    ret

; void json_string(root,key,dest,cap)
json_string:
    push r12
    push r13
    push r14
    mov r12, rdx
    mov r13, rcx
    call cJSON_GetObjectItemCaseSensitive wrt ..plt
    test rax, rax
    jz .done
    mov rdi, rax
    call cJSON_GetStringValue wrt ..plt
    test rax, rax
    jz .done
    mov r14, rax
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rel string_fmt]
    mov rcx, r14
    xor eax, eax
    call snprintf wrt ..plt
.done:
    pop r14
    pop r13
    pop r12
    ret

; int64 json_number(root,key,fallback)
json_number:
    push r12
    mov r12, rdx
    call cJSON_GetObjectItemCaseSensitive wrt ..plt
    test rax, rax
    jz .fallback
    mov rdi, rax
    call cJSON_GetNumberValue wrt ..plt
    cvttsd2si rax, xmm0
    jmp .done
.fallback:
    mov rax, r12
.done:
    pop r12
    ret

; int64 json_bool(root,key,fallback)
json_bool:
    push r12
    mov r12, rdx
    call cJSON_GetObjectItemCaseSensitive wrt ..plt
    test rax, rax
    jz .fallback
    mov rdi, rax
    call cJSON_IsTrue wrt ..plt
    test eax, eax
    setne al
    movzx eax, al
    jmp .done
.fallback:
    mov rax, r12
.done:
    pop r12
    ret

; int hg_store_load(session)
hg_store_load:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15
    push rbx
    sub rsp, 664
    mov r12, rdi

    lea rdi, [r12 + SESSION_NAME]
    mov rsi, rsp
    mov edx, 640
    call character_path
    test eax, eax
    jnz .error
    mov rdi, rsp
    lea rsi, [rel read_mode]
    call fopen wrt ..plt
    test rax, rax
    jz .missing
    mov r13, rax
    mov rdi, r13
    xor esi, esi
    mov edx, 2
    call fseek wrt ..plt
    test eax, eax
    jnz .file_error
    mov rdi, r13
    call ftell wrt ..plt
    cmp rax, 2
    jl .file_error
    cmp rax, 65536
    jg .file_error
    mov r14, rax
    mov rdi, r13
    xor esi, esi
    xor edx, edx
    call fseek wrt ..plt
    test eax, eax
    jnz .file_error
    lea rdi, [r14 + 1]
    call malloc wrt ..plt
    test rax, rax
    jz .file_error
    mov r15, rax
    mov rdi, r15
    mov esi, 1
    mov rdx, r14
    mov rcx, r13
    call fread wrt ..plt
    mov byte [r15 + rax], 0
    mov rdi, r13
    call fclose wrt ..plt
    xor r13d, r13d
    mov rdi, r15
    call cJSON_Parse wrt ..plt
    mov r14, rax
    mov rdi, r15
    call free wrt ..plt
    test r14, r14
    jz .error

    mov rdi, r14
    lea rsi, [rel key_race]
    lea rdx, [r12 + SESSION_RACE]
    mov ecx, 16
    call json_string
    mov rdi, r14
    lea rsi, [rel key_faction]
    lea rdx, [r12 + SESSION_FACTION]
    mov ecx, 16
    call json_string
    mov rdi, r14
    lea rsi, [rel key_position]
    lea rdx, [r12 + SESSION_POSITION]
    mov ecx, 16
    call json_string
    mov rdi, r14
    lea rsi, [rel key_title]
    lea rdx, [r12 + SESSION_TITLE]
    mov ecx, 48
    call json_string
    mov rdi, r14
    lea rsi, [rel key_weapon]
    lea rdx, [r12 + SESSION_WEAPON]
    mov ecx, 16
    call json_string

%macro LOAD_NUM 2
    mov rdi, r14
    lea rsi, [rel %1]
    mov rdx, [r12 + %2]
    call json_number
    mov [r12 + %2], rax
%endmacro
    LOAD_NUM key_room, SESSION_ROOM
    LOAD_NUM key_hp, SESSION_HP
    LOAD_NUM key_max_hp, SESSION_MAX_HP
    LOAD_NUM key_level, SESSION_LEVEL
    LOAD_NUM key_xp, SESSION_XP
    LOAD_NUM key_gold, SESSION_GOLD
    LOAD_NUM key_morality, SESSION_MORALITY
    LOAD_NUM key_addiction, SESSION_ADDICTION

%macro LOAD_BOOL 2
    mov rdi, r14
    lea rsi, [rel %1]
    mov rdx, [r12 + %2]
    call json_bool
    mov [r12 + %2], rax
%endmacro
    LOAD_BOOL key_ashsworn, SESSION_ASHSWORN
    LOAD_BOOL key_strayed, SESSION_STRAYED
    LOAD_BOOL key_redeemed, SESSION_REDEEMED
    LOAD_BOOL key_resisted, SESSION_RESISTED

    lea rdi, [r12 + SESSION_SECRET_HASH]
    xor esi, esi
    mov edx, 72
    call memset wrt ..plt
    mov rdi, r14
    lea rsi, [rel key_secret_hash]
    lea rdx, [r12 + SESSION_SECRET_HASH]
    mov ecx, 72
    call json_string

    ; Clear inventory, then load from JSON array when present (#13).
    lea rdi, [r12 + SESSION_INVENTORY]
    xor esi, esi
    mov edx, SESSION_INV_SLOTS * SESSION_INV_SLOT_SIZE
    call memset wrt ..plt
    mov qword [r12 + SESSION_INV_COUNT], 0
    mov rdi, r14
    lea rsi, [rel key_inventory]
    call cJSON_GetObjectItemCaseSensitive wrt ..plt
    test rax, rax
    jz .inv_done
    mov r13, rax
    mov rdi, r13
    call cJSON_GetArraySize wrt ..plt
    mov dword [rsp + 640], eax
    xor ebx, ebx
    xor r15d, r15d
.inv_loop:
    cmp r15d, dword [rsp + 640]
    jae .inv_store_count
    cmp ebx, SESSION_INV_SLOTS
    jae .inv_store_count
    mov rdi, r13
    mov esi, r15d
    call cJSON_GetArrayItem wrt ..plt
    test rax, rax
    jz .inv_next
    mov qword [rsp + 648], rax
    mov rdi, rax
    call cJSON_IsString wrt ..plt
    test eax, eax
    jz .inv_next
    mov rdi, [rsp + 648]
    call cJSON_GetStringValue wrt ..plt
    test rax, rax
    jz .inv_next
    mov rcx, rax
    mov eax, ebx
    imul eax, SESSION_INV_SLOT_SIZE
    lea rdi, [r12 + SESSION_INVENTORY]
    add rdi, rax
    mov esi, SESSION_INV_SLOT_SIZE
    lea rdx, [rel string_fmt]
    xor eax, eax
    call snprintf wrt ..plt
    inc ebx
.inv_next:
    inc r15d
    jmp .inv_loop
.inv_store_count:
    mov eax, ebx
    mov [r12 + SESSION_INV_COUNT], rax
.inv_done:

    mov rdi, r14
    call cJSON_Delete wrt ..plt
    mov eax, 1
    jmp .done

.file_error:
    mov rdi, r13
    call fclose wrt ..plt
.error:
    mov eax, -1
    jmp .done
.missing:
    xor eax, eax
.done:
    add rsp, 664
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

; cJSON_AddNumberToObject(root,key,int64)
add_number:
    cvtsi2sd xmm0, rdx
    jmp cJSON_AddNumberToObject wrt ..plt

; int hg_store_save(session)
hg_store_save:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15
    push rbx
    sub rsp, 1320
    mov r12, rdi

    lea rdi, [r12 + SESSION_NAME]
    mov rsi, rsp
    mov edx, 640
    call character_path
    test eax, eax
    jnz .save_error
    lea rdi, [rsp + 640]
    mov esi, 656
    lea rdx, [rel temp_path_fmt]
    mov rcx, rsp
    xor eax, eax
    call snprintf wrt ..plt
    test eax, eax
    jle .save_error
    cmp eax, 656
    jge .save_error

    call cJSON_CreateObject wrt ..plt
    test rax, rax
    jz .save_error
    mov r13, rax

%macro ADD_STRING 2
    mov rdi, r13
    lea rsi, [rel %1]
    lea rdx, [r12 + %2]
    call cJSON_AddStringToObject wrt ..plt
%endmacro
    ADD_STRING key_name, SESSION_NAME
    ADD_STRING key_race, SESSION_RACE
    ADD_STRING key_faction, SESSION_FACTION
    ADD_STRING key_position, SESSION_POSITION
    ADD_STRING key_title, SESSION_TITLE
    ADD_STRING key_weapon, SESSION_WEAPON

%macro ADD_NUM 2
    mov rdi, r13
    lea rsi, [rel %1]
    mov rdx, [r12 + %2]
    call add_number
%endmacro
    ADD_NUM key_room, SESSION_ROOM
    ADD_NUM key_hp, SESSION_HP
    ADD_NUM key_max_hp, SESSION_MAX_HP
    ADD_NUM key_level, SESSION_LEVEL
    ADD_NUM key_xp, SESSION_XP
    ADD_NUM key_gold, SESSION_GOLD
    ADD_NUM key_morality, SESSION_MORALITY
    ADD_NUM key_addiction, SESSION_ADDICTION

%macro ADD_BOOL 2
    mov rdi, r13
    lea rsi, [rel %1]
    mov rdx, [r12 + %2]
    call cJSON_AddBoolToObject wrt ..plt
%endmacro
    ADD_BOOL key_ashsworn, SESSION_ASHSWORN
    ADD_BOOL key_strayed, SESSION_STRAYED
    ADD_BOOL key_redeemed, SESSION_REDEEMED
    ADD_BOOL key_resisted, SESSION_RESISTED
    ADD_STRING key_secret_hash, SESSION_SECRET_HASH

    mov rdi, r13
    lea rsi, [rel key_inventory]
    call cJSON_AddArrayToObject wrt ..plt
    test rax, rax
    jz .json_fail
    mov r14, rax
    xor ebx, ebx
.inv_save_loop:
    cmp rbx, [r12 + SESSION_INV_COUNT]
    jae .inv_save_done
    cmp rbx, SESSION_INV_SLOTS
    jae .inv_save_done
    mov rax, rbx
    imul rax, SESSION_INV_SLOT_SIZE
    lea rdi, [r12 + SESSION_INVENTORY]
    add rdi, rax
    cmp byte [rdi], 0
    je .inv_save_next
    call cJSON_CreateString wrt ..plt
    test rax, rax
    jz .json_fail
    mov rdi, r14
    mov rsi, rax
    call cJSON_AddItemToArray wrt ..plt
.inv_save_next:
    inc rbx
    jmp .inv_save_loop
.inv_save_done:

    mov rdi, r13
    call cJSON_PrintUnformatted wrt ..plt
    mov r14, rax
    mov rdi, r13
    call cJSON_Delete wrt ..plt
    xor r13d, r13d
    test r14, r14
    jz .save_error

    lea rdi, [rsp + 640]
    mov esi, 577
    mov edx, 0600o
    xor eax, eax
    call open wrt ..plt
    test eax, eax
    js .free_error
    mov r15d, eax
    mov rdi, r14
    call strlen wrt ..plt
    mov rbx, rax
    mov rsi, r14
.write_loop:
    test rbx, rbx
    jz .write_ok
    mov edi, r15d
    mov rdx, rbx
    call write wrt ..plt
    test rax, rax
    jle .close_error
    add rsi, rax
    sub rbx, rax
    jmp .write_loop
.write_ok:
    mov edi, r15d
    call fsync wrt ..plt
    test eax, eax
    jnz .close_error
    mov edi, r15d
    call close wrt ..plt
    test eax, eax
    jnz .free_error
    lea rdi, [rsp + 640]
    mov rsi, rsp
    call rename wrt ..plt
    test eax, eax
    jnz .free_error
    ; Durability of the rename itself: fsync the characters directory (#14).
    lea rdi, [rel store_root]
    xor esi, esi
    xor edx, edx
    call open wrt ..plt
    test eax, eax
    js .rename_ok
    mov ebx, eax
    mov edi, eax
    call fsync wrt ..plt
    mov edi, ebx
    call close wrt ..plt
.rename_ok:
    mov rdi, r14
    call free wrt ..plt
    xor eax, eax
    jmp .save_done

.json_fail:
    mov rdi, r13
    call cJSON_Delete wrt ..plt
    jmp .save_error
.close_error:
    mov edi, r15d
    call close wrt ..plt
.free_error:
    mov rdi, r14
    call free wrt ..plt
.save_error:
    mov eax, -1
.save_done:
    add rsp, 1320
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

