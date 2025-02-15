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

    ; Debug: Mensagem inicial
    mov si, boot_msg
    call print_string

    ; Carregar kernel (setores 2-5)
    mov bx, 0x1000      ; ES:BX = 0000:1000
    mov ah, 0x02
    mov al, 4           ; 4 setores = 2KB
    mov ch, 0           ; Cylinder
    mov cl, 2           ; Sector
    mov dh, 0           ; Head
    mov dl, 0x80        ; Drive
    int 0x13
    jc error

    ; Debug: Confirmação de carga
    mov si, load_kernel_msg
    call print_string

    ; Carregar editor (setor 6)
    mov bx, 0x2000
    mov al, 1
    mov cl, 6
    int 0x13
    jc error

    ; Transferir controle para o kernel
    jmp 0x0000:0x1000   ; Far jump crítico!

error:
    mov si, msg_error
    call print_string
    mov ah, 0x00        ; Esperar tecla
    int 0x16
    int 0x19             ; Reiniciar

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

boot_msg        db "[1] Bootloader ativo!", 13, 10, 0
load_kernel_msg db "[2] Kernel carregado!", 13, 10, 0
msg_error       db "[!] Erro de disco!", 0

times 510-($-$$) db 0
dw 0xAA55
