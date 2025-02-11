[BITS 16]
[ORG 0x1000]

start:
    ; Mensagem de inicialização do kernel
    mov si, msg_kernel
    call print_string

    ; CLI básica
cli_loop:
    mov si, prompt
    call print_string
.wait_input:
    mov ah, 0x00
    int 0x16            ; Aguardar entrada do teclado
    cmp al, 'e'         ; Comando 'e' para carregar o editor
    je load_editor
    cmp al, 'r'         ; Comando 'r' para reiniciar
    je reboot
    jmp .wait_input

load_editor:
    ; Mensagem de carregamento do editor
    mov si, msg_loading_editor
    call print_string

    ; Pular para o editor (carregado em 0x2000)
    jmp 0x2000

reboot:
    ; Reiniciar o sistema
    int 0x19

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

msg_kernel db "Kernel loaded.", 0
prompt db "> ", 0
msg_loading_editor db "Loading editor...", 0
