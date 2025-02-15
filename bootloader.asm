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

    ; Debug inicial
    mov si, boot_msg
    call print_string

    ; Carregar kernel (setores 2-5)
    mov bx, 0x1000
    mov ah, 0x02
    mov al, 4           ; 4 setores
    mov ch, 0           ; Cylinder
    mov cl, 2           ; Sector
    mov dh, 0           ; Head
    mov dl, 0x80        ; Drive
    int 0x13
    jc error

    ; Debug kernel
    mov si, kernel_msg
    call print_string

    ; Carregar editor (setores 6-7)
    mov bx, 0x2000
    mov ah, 0x02        ; Resetar AH
    mov al, 2           ; 2 setores
    mov cl, 6           ; Sector inicial
    ; CH e DH já estão corretos (0)
    int 0x13
    jc error

    ; Debug editor
    mov si, editor_msg
    call print_string

    ; Pular para o kernel
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

boot_msg    db "[1] Bootloader OK!", 13, 10, 0
kernel_msg  db "[2] Kernel carregado (4 setores)!", 13, 10, 0
editor_msg  db "[3] Editor carregado (2 setores)!", 13, 10, 0
msg_error   db "[ERRO] Disco/Setor invalido!", 0

times 510-($-$$) db 0
dw 0xAA55
