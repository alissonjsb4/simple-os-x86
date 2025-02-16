[BITS 16]
[ORG 0x1000]

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    call clear_screen

    mov si, kernel_msg
    call print_string

main_loop:
    mov si, prompt
    call print_string
    call wait_key

    cmp al, 'e'
    je load_editor
    cmp al, 'r'
    je reboot

    mov si, invalid_msg
    call print_string
    jmp main_loop

load_editor:
    mov si, editor_msg
    call print_string
    jmp 0x0000:0x2000

reboot:
    int 0x19

clear_screen:
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10
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

wait_key:
    mov ah, 0x00
    int 0x16
    ret

kernel_msg db "Kernel iniciado!", 13, 10, 0
prompt     db "CMD> ", 0
editor_msg db "Iniciando editor...", 13, 10, 0
invalid_msg db "Comando invalido!", 13, 10, 0

times 2048-($-$$) db 0
