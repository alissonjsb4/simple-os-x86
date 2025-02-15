[BITS 16]
[ORG 0x1000]

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    sti

    ; Limpar tela
    mov ah, 0x06
    xor al, al
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10

    ; Mensagem inicial
    mov si, kernel_msg
    call print_string

cli_loop:
    ; Mostrar prompt
    mov si, prompt
    call print_string

    ; Esperar entrada
    call wait_key

    ; Processar comando
    cmp al, 'e'
    je load_editor
    cmp al, 'r'
    je reboot
    jmp cli_loop

load_editor:
    mov si, editor_msg
    call print_string
    jmp 0x0000:0x2000      ; Far jump para editor

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

kernel_msg db "[KERNEL] Sistema operacional carregado!", 13, 10, 0
prompt     db 13, 10, "CMD> ", 0
editor_msg db 13, 10, "Iniciando editor de texto...", 13, 10, 0
