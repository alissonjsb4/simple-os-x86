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

    ; Carregar kernel (setores 2-5)
    mov bx, 0x1000      ; Endereço de memória
    mov ah, 0x02        ; Função de leitura
    mov al, 4           ; 4 setores (2KB)
    mov ch, 0           ; Trilha 0
    mov cl, 2           ; Setor inicial
    mov dh, 0           ; Cabeça 0
    mov dl, 0x80        ; Drive (HD)
    int 0x13
    jc error

    ; Carregar editor (setor 6)
    mov bx, 0x2000
    mov al, 1
    mov cl, 6
    int 0x13
    jc error

    ; Far jump para o kernel
    jmp 0x0000:0x1000

error:
    mov si, msg_error
    call print_string
    mov ah, 0x00
    int 0x16
    int 0x19

print_string:
    mov ah, 0x0E
.print_char:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .print_char
.done:
    ret

msg_error db "Erro de disco! Reiniciando...", 0

times 510-($-$$) db 0
dw 0xAA55
