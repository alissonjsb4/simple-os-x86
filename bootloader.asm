[BITS 16]
[ORG 0x7C00]

start:
    cli
    cld
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    mov si, boot_msg
    call print_string

    ; Carregar kernel (LBA 2-5, CHS: C=0,H=0,S=3)
    mov bx, 0x1000
    mov ah, 0x02
    mov al, 4
    mov ch, 0
    mov cl, 3
    mov dh, 0
    mov dl, 0x80
    int 0x13
    jc error
    cmp al, 4
    jne error

    mov si, kernel_msg
    call print_string

    ; Carregar editor (LBA 6-7, CHS: C=0,H=0,S=7)
    mov bx, 0x2000
    mov ah, 0x02
    mov al, 2
    mov cl, 7
    int 0x13
    jc error
    cmp al, 2
    jne error

    mov si, editor_msg
    call print_string

    mov si, press_key_msg
    call print_string
    call wait_key

    jmp 0x0000:0x1000

error:
    mov si, msg_error
    call print_string
    mov ah, 0x00
    int 0x16
    int 0x19

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

boot_msg    db "[1] Bootloader OK!", 13, 10, 0
kernel_msg  db "[2] Kernel carregado!", 13, 10, 0
editor_msg  db "[3] Editor carregado!", 13, 10, 0
msg_error   db "Erro de disco!", 0
press_key_msg db "[!] Pressione qualquer tecla...", 13, 10, 0

times 510-($-$$) db 0
dw 0xAA55
