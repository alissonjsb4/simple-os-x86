[BITS 16]
[ORG 0x1000]  ; Endereço físico 0x1000

start:
    ; Configurar segmentos
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFFFE

    ; Debug: Mensagem do kernel
    mov si, kernel_msg
    call print_string

    ; CLI simples
cli_loop:
    mov si, prompt
    call print_string
    call wait_key
    cmp al, 'e'
    je load_editor
    cmp al, 'r'
    je reboot
    jmp cli_loop

load_editor:
    mov si, editor_msg
    call print_string
    jmp 0x2000          ; Pular para o editor

reboot:
    int 0x19

wait_key:
    mov ah, 0x00
    int 0x16
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

kernel_msg db "[3] Kernel executando!", 13, 10, 0
prompt     db "Comandos: e=editor, r=reboot > ", 0
editor_msg db 13, 10, "Iniciando editor...", 13, 10, 0
