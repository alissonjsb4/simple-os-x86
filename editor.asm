[BITS 16]
[ORG 0x2000]

; ================ DECLARAÇÕES INICIAIS ================
section .text
start:
    jmp main

; ==================== FUNÇÕES ====================
print_string:
    mov ah, 0x0E
.print_loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .print_loop
.done:
    ret

get_char:
    mov ah, 0x00
    int 0x16
    ret

clear_screen:
    mov ah, 0x06
    xor al, al
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10
    ret

print_char:
    mov ah, 0x0E
    int 0x10
    ret

; ================= PROGRAMA PRINCIPAL =================
main:
    mov ax, 0x0000
    mov ds, ax
    mov es, ax
    mov di, buffer
    
    call clear_screen
    mov si, editor_msg
    call print_string

editor_loop:
    call get_char
    cmp al, 0x08        ; Backspace
    je .backspace
    cmp al, 0x0D        ; Enter
    je .newline
    cmp al, 0x13        ; Ctrl+S
    je .save
    cmp di, buffer+256
    jae editor_loop
    
    stosb
    call print_char
    jmp editor_loop

.backspace:
    cmp di, buffer
    jbe editor_loop
    dec di
    mov byte [di], 0
    call update_screen
    jmp editor_loop

.newline:
    mov al, 0x0D
    call print_char
    mov al, 0x0A
    call print_char
    jmp editor_loop

.save:
    ; ... (código de salvamento anterior)
    ; Mantido igual para focar nas correções

update_screen:
    ; ... (código de update_screen anterior)
    ; Mantido igual para focar nas correções

; =================== DADOS ===================
section .data
editor_msg  db 0x0D, 0x0A, "[EDITOR] Digite seu texto (Ctrl+S salva)", 0x0D, 0x0A
            db "Backspace: Apagar | Enter: Nova linha", 0x0D, 0x0A, 0

saved_msg   db 0x0D, 0x0A, "Texto salvo no setor 10! Voltando ao kernel...", 0x0D, 0x0A, 0
error_msg   db 0x0D, 0x0A, "[ERRO] Falha ao salvar! Reiniciando...", 0x0D, 0x0A, 0

buffer times 256 db 0
