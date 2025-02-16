[BITS 16]
[ORG 0x2000]

start:
    xor ax, ax
    mov ds, ax
    mov es, ax

    call clear_screen
    mov si, header
    call print_string

edit_loop:
    call wait_key

    cmp al, 0x08
    je .backspace
    cmp al, 0x0D
    je .newline
    cmp al, 0x13
    je .save

    mov ah, 0x0E
    int 0x10
    jmp edit_loop

.backspace:
    call backspace
    jmp edit_loop

.newline:
    mov al, 0x0D
    int 0x10
    mov al, 0x0A
    int 0x10
    jmp edit_loop

.save:
    mov si, saved_msg
    call print_string
    jmp edit_loop

clear_screen:
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10
    ret

backspace:
    mov ah, 0x03
    int 0x10
    dec dl
    mov ah, 0x02
    int 0x10
    mov al, ' '
    mov ah, 0x0A
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

wait_key:
    mov ah, 0x00
    int 0x16
    ret

header db 13,10,"Editor Simples (Ctrl+S: Salvar)",13,10,"------------------------------",13,10,0
saved_msg db 13,10,"[Salvo!]",13,10,0

times 1024-($-$$) db 0
