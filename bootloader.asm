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

    ; Carregar kernel (setor 2)
    mov bx, 0x1000      ; Endereço de memória
    mov ah, 0x02        ; Função de leitura
    mov al, 1           ; 1 setor
    mov ch, 0           ; Trilha 0
    mov cl, 2           ; Setor 2
    mov dh, 0           ; Cabeça 0
    int 0x13
    jc error

    ; Carregar editor (setor 6)
    mov bx, 0x2000      ; Endereço de memória
    mov cl, 6           ; Setor 6
    int 0x13
    jc error

    ; Pular para o kernel
    jmp 0x1000

error:
    mov si, msg_error
    call print_string
    hlt

print_string:
    mov ah, 0x0E
.print_char:
    lodsb
    or al, al
    jz .done
    int 0x10
    jmp .print_char
.done:
    ret

msg_error db "Erro ao carregar!", 0

times 510-($-$$) db 0
dw 0xAA55
