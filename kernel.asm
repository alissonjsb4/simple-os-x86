[BITS 16]
[ORG 0x1000]

start:
    cli
    mov ax, 0x1000
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFFFF
    sti

    mov si, msg_kernel
    call print_string

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
    mov si, msg_editor
    call print_string
    jmp 0x2000

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

msg_kernel db "Kernel Ativo!", 13, 10, 0
prompt db "Comandos: e=editor, r=reiniciar > ", 0
msg_editor db 13, 10, "Iniciando editor...", 13, 10, 0
