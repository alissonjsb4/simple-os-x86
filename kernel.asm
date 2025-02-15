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

; ... (restante do código)

msg_kernel db "Kernel carregado!", 0
prompt db "> ", 0
msg_editor db " Editor iniciado!", 0  ; Corrigi a vírgula faltando
