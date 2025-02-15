[BITS 16]
[ORG 0x2000]

start:
    mov di, buffer      ; Inicializa ponteiro
    mov si, msg_editor
    call print_string

editor_loop:
    call get_char
    cmp al, 0x08
    je .backspace
    cmp al, 0x13
    je .save
    cmp di, buffer + 255
    je editor_loop
    stosb
    call print_char
    jmp editor_loop

.backspace:
    cmp di, buffer
    je editor_loop
    dec di
    mov byte [di], 0
    call clear_screen
    mov si, buffer
    call print_string
    jmp editor_loop

.save:
    ; Escrever buffer no setor 10
    mov ah, 0x03
    mov al, 1
    mov ch, 0
    mov cl, 10
    mov dh, 0
    mov dl, 0x80
    mov bx, buffer
    int 0x13
    jc .save_error
    mov si, msg_saved
    jmp .exit

.save_error:
    mov si, msg_save_error

.exit:
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
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10
    ret

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

msg_editor db "Editor (Backspace=apagar, Ctrl+S=salvar):", 13, 10, 0
msg_saved db 13, 10, "Salvo no setor 10!", 13, 10, 0
msg_save_error db 13, 10, "Erro ao salvar!", 13, 10, 0
buffer times 256 db 0
