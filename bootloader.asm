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
    mov al, 4
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, 0x80
    int 0x13
    jc error

    ; Debug kernel
    mov si, kernel_msg
    call print_string

    ; Carregar editor (setores 6-7)
    mov bx, 0x2000
    mov ah, 0x02
    mov al, 2
    mov cl, 6
    int 0x13
    jc error

    ; Debug editor
    mov si, editor_msg
    call print_string

    ; ####################################
    ; ALTERAÇÃO: Esperar confirmação do usuário
    mov si, press_key_msg
    call print_string
    call wait_key    ; Nova função adicionada
    ; ####################################

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

; ####################################
; NOVA FUNÇÃO: Esperar tecla
wait_key:
    mov ah, 0x00
    int 0x16
    ret
; ####################################

boot_msg    db "[1] Bootloader OK!", 13, 10, 0
kernel_msg  db "[2] Kernel carregado (4 setores)!", 13, 10, 0
editor_msg  db "[3] Editor carregado (2 setores)!", 13, 10, 0
msg_error   db "[ERRO] Disco/Setor invalido!", 0
press_key_msg db "[!] Pressione qualquer tecla para iniciar...", 13, 10, 0 ; Nova mensagem

times 510-($-$$) db 0  ; Preenche com zeros até o byte 510, é necessário para que o "0xAA55" esteja presente no fim do setor (bytes 511 e 512), identificando o setor como bootloader
dw 0xAA55
