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

    ; Mensagem de debug inicial
    mov si, boot_msg
    call print_string

    ; Carregar kernel (setores 2-5)
    mov bx, 0x1000      ; Segmento de destino do kernel
    mov ah, 0x02        ; Função BIOS: ler setor
    mov al, 4           ; Ler 4 setores
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, 0x80        ; Disco principal
    int 0x13
    jc error

    ; Mensagem de debug kernel
    mov si, kernel_msg
    call print_string

    ; Carregar editor (setores 6-7)
    mov bx, 0x2000      ; Segmento de destino do editor
    mov ah, 0x02        ; Função BIOS: ler setor
    mov al, 2           ; Ler 2 setores
    mov cl, 6
    int 0x13
    jc error

    ; Mensagem de debug editor
    mov si, editor_msg
    call print_string

    ; Esperar confirmação do usuário
    mov si, press_key_msg
    call print_string
    call wait_key

    ; Pular para o kernel (início em 0x0000:0x1000)
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

boot_msg       db "[1] Bootloader OK!", 13, 10, 0
kernel_msg     db "[2] Kernel carregado (4 setores)!", 13, 10, 0
editor_msg     db "[3] Editor carregado (2 setores)!", 13, 10, 0
msg_error      db "[ERRO] Falha na leitura do disco!", 0
press_key_msg  db "[!] Pressione qualquer tecla para iniciar...", 13, 10, 0

; Preenche até 512 bytes
times 510-($-$$) db 0
dw 0xAA55
