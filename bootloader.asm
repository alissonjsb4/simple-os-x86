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

    ; Mensagem de depuração
    mov si, msg_bootloader
    call print_string

    ; Carregar o kernel (setor 2)
    mov bx, 0x1000      ; Endereço de memória para carregar o kernel
    mov dh, 0           ; Cabeça 0
    mov dl, 0x80        ; Drive (0x80 para HD)
    mov cx, 2           ; Setor inicial (setor 2)
    call read_sectors

    ; Carregar o editor (setor 6)
    mov bx, 0x2000      ; Endereço de memória para carregar o editor
    mov cx, 6           ; Setor inicial (setor 6)
    call read_sectors

    ; Pular para o kernel
    jmp 0x1000

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

read_sectors:
    pusha
    mov ah, 0x02        ; Função de leitura de disco
    mov al, 1           ; Ler 1 setor por vez
    mov ch, 0           ; Trilha 0
    mov cl, 2           ; Setor inicial (setor 2 para kernel, 6 para editor)
    mov dh, 0           ; Cabeça 0
    mov dl, 0x80        ; Drive (0x80 para HD)
    int 0x13            ; Interrupção de disco
    jc .error           ; Se houver erro, pule para .error
    popa
    ret
.error:
    mov si, msg_error
    call print_string
    hlt
    jmp .error

msg_bootloader db "Bootloader started.", 0
msg_error db "Error loading sector.", 0

times 510-($-$$) db 0
dw 0xAA55
