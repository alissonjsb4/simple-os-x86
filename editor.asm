[BITS 16]
[ORG 0x2000]

start:
    mov si, msg_editor
    call print_string

editor_loop:
    call get_char
    cmp al, 0x08        ; Backspace
    je .backspace
    cmp al, 0x13        ; Ctrl+S
    je .save
    call print_char
    jmp editor_loop

.backspace:
    cmp di, buffer
    je editor_loop
    dec di
    mov byte [di], 0
    call clear_screen
    jmp editor_loop

.save:
    mov si, msg_saved
    call print_string
    ret

get_char:
    mov ah, 0x00
    int 0x16
    ret

print_char:
    mov ah, 0x0E
    int 0x10
    ret

clear_screen:
    mov ah, 0x06
    xor al, al
    int 0x10
    ret

print_string:
    mov ah, 0x0E
.print_loop:
    lodsb
    or al, al
    jz .done
    int 0x10
    jmp .print_loop
.done:
    ret

msg_editor db "Editor de texto (Ctrl+S para salvar):", 0
msg_saved db 13, 10, "Texto salvo!", 13, 10, 0
buffer times 256 db 0
