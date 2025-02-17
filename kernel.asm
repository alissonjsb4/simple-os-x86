[BITS 16]
[ORG 0x1000]

start:
    ; Configura segmentos e pilha
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Limpa a tela, posiciona cursor em (0,0)
    call clear_screen
    mov dh, 0
    mov dl, 0
    call set_cursor

    ; Exibe mensagem inicial do Kernel
    mov si, kernel_msg
    call print_string

main_loop:
    ; Exibe prompt
    mov si, prompt
    call print_string

    ; Espera uma tecla
    call wait_key

    ; Verifica qual comando foi digitado
    cmp al, 'e'
    je load_editor
    cmp al, 'r'
    je reboot
    cmp al, 'v'
    je view_text

    ; Se não for nenhum desses, comando inválido
    mov si, invalid_msg
    call print_string
    jmp main_loop

;-------------------------------------------------------
; Carregar e saltar para o editor (em 0x2000)
;-------------------------------------------------------
load_editor:
    mov si, editor_msg
    call print_string
    jmp 0x0000:0x2000

;-------------------------------------------------------
; Comando 'v' - Ler o texto salvo no setor 8 e exibir
;-------------------------------------------------------
view_text:
    ; 1) Limpa a tela
    call clear_screen

    ; 2) Posiciona cursor em (0,0)
    mov dh, 0
    mov dl, 0
    call set_cursor

    ; 3) Ler 1 setor (setor 8) do disco
    mov ah, 0x02    ; Função: ler setores
    mov al, 1       ; Lê 1 setor
    mov ch, 0
    mov cl, 8       ; Setor 8 (exemplo)
    mov dh, 0
    mov dl, 0x80    ; Drive HDD primário
    mov bx, 0x3000  ; Área de memória onde vamos carregar
    int 0x13
    jc disk_error   ; Se houve erro, trate aqui

    ; 4) Imprime o que foi lido em 0x3000, respeitando CR/LF
    mov si, 0x3000

.print_loop:
    lodsb           ; Carrega próximo byte em AL
    cmp al, 0
    je .done_print  ; Se achar 0, fim
    cmp al, 13      ; CR
    je .new_line
    cmp al, 10      ; LF
    je .new_line

    ; Caractere comum
    mov ah, 0x0E
    int 0x10
    jmp .print_loop

.new_line:
    ; Para CR/LF, vamos para a próxima linha, coluna 0
    inc dh
    mov dl, 0
    call set_cursor
    jmp .print_loop

.done_print:
    jmp main_loop

; Caso a leitura falhe, imprime mensagem e volta
disk_error:
    mov si, disk_error_msg
    call print_string
    jmp main_loop

;-------------------------------------------------------
; Reiniciar (retornar à BIOS)
;-------------------------------------------------------
reboot:
    int 0x19

;-------------------------------------------------------
; Rotinas auxiliares
;-------------------------------------------------------
clear_screen:
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10
    ret

set_cursor:
    mov ah, 0x02
    xor bh, bh
    int 0x10
    ret

print_string:
    mov ah, 0x0E
.print_loop_str:
    lodsb
    test al, al
    jz .done_str
    int 0x10
    jmp .print_loop_str
.done_str:
    ret

wait_key:
    mov ah, 0x00
    int 0x16
    ret

;-------------------------------------------------------
; Dados
;-------------------------------------------------------
kernel_msg     db "Kernel iniciado!", 13, 10, 0
prompt         db "CMD> ", 0
editor_msg     db "Iniciando editor...", 13, 10, 0
invalid_msg    db "Comando invalido!", 13, 10, 0
disk_error_msg db "Erro de leitura do disco!", 13, 10, 0

; Preenche até 2048 bytes (2 setores) para o kernel
times 2048-($-$$) db 0
