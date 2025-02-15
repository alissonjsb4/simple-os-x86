[BITS 16]
[ORG 0x1000]

start:
    ; Configurar segmentos corretamente
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00      ; Stack abaixo do bootloader

    ; Habilitar interrupções
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
    jmp 0x2000          ; Pular para o editor

reboot:
    int 0x19

wait_key:
    mov ah, 0x00        ; Função de leitura de tecla
    int 0x16            ; INT 16h AH=00h
    ret

print_string:
    mov ah, 0x0E        ; Função de imprimir caractere
.print_loop:
    lodsb               ; Carrega próximo caractere
    test al, al
    jz .done
    int 0x10
    jmp .print_loop
.done:
    ret

kernel_msg db "[KERNEL] Sistema operacional carregado!", 13, 10, 0
prompt     db 13, 10, "CMD> ", 0
editor_msg db 13, 10, "Iniciando editor de texto...", 13, 10, 0
