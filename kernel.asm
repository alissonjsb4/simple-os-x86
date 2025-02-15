[BITS 16]
[ORG 0x1000]

start:
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
    or al, al
    jz .done
    int 0x10
    jmp .print_loop
.done:
    ret

msg_kernel db "Kernel carregado!", 0
prompt db "> ", 0
msg_editor db " Iniciando editor...", 0
