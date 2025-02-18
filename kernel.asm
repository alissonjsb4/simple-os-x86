[BITS 16]
[ORG 0x1000]

start:
    ; Configura segmentos e pilha
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Limpa a tela
    call clear_screen
    mov dh, 0
    mov dl, 0
    call set_cursor

    ; Mensagem inicial
    mov si, kernel_msg
    call print_string

main_loop:
    ; Exibe prompt
    mov si, prompt
    call print_string

    ; Espera tecla
    call wait_key

    ; Processa comando
    cmp al, 'e'
    je load_editor
    cmp al, 'r'
    je reboot
    cmp al, 'v'
    je view_text

    ; Comando inválido
    mov si, invalid_msg
    call print_string
    jmp main_loop

;-------------------------------------------------------
; Carregar editor (setor 7)
;-------------------------------------------------------
load_editor:
    mov si, editor_msg
    call print_string
    jmp 0x0000:0x2000  ; Salta para o editor

;-------------------------------------------------------
; Comando 'v' - Ver textos salvos
;-------------------------------------------------------
view_text:
    call clear_screen
    mov dh, 0
    mov dl, 0
    call set_cursor

    ; 1) Ler o setor 9 (que contém o file_count) para o buffer file_count_buffer
    mov ah, 0x02          ; Função: Ler setores
    mov al, 1             ; Ler 1 setor
    mov ch, 0
    mov cl, 9             ; Setor 9
    mov dh, 0
    mov dl, 0x80          ; Drive primário
    mov bx, file_count_buffer
    int 0x13
    jc disk_error

    ; 2) Extrair o contador do primeiro byte do buffer
    mov al, [file_count_buffer]  ; Supõe que o contador está no primeiro byte
    mov [file_count], ax         ; Armazena em file_count (word)

    ; Exibe um cabeçalho
    mov si, view_header
    call print_string

    ; 3) Loop para ler e imprimir cada arquivo
    xor di, di            ; DI = 0 (índice do arquivo, 0-based)
    mov bl, 10            ; Primeiro setor de arquivo é 10

read_loop:
    cmp di, [file_count]
    jae done_read         ; Se DI >= file_count, encerra

    ; Imprime a linha no formato: "[NN] "
    mov si, open_bracket
    call print_string

    mov ax, di
    inc ax               ; N = DI+1
    and ax, 0x00FF       ; Garante que o Valor esteja em 8 bits
    call print_two_digit

    mov si, close_bracket_space
    call print_string

    ; 0) Limpa o buffer da memória RAM que será usado para carregar o texto
    call clear_buffer

    ; 4) Ler o setor (número em BL) para o buffer temporário em 0x5000
    mov ah, 0x02         ; Função: Ler setores
    mov al, 1            ; Ler 1 setor
    mov ch, 0
    mov cl, bl         ; Setor a ser lido (assume BL < 256)
    mov dh, 0
    mov dl, 0x80
    mov bx, 0x3000       ; Buffer temporário para o arquivo
    int 0x13
    jc disk_error

    ; 5) Imprimir os 6 primeiros bytes do arquivo
    mov cx, 6            ; Quantidade de bytes a imprimir
    mov si, 0x3000       ; Início do buffer
print_six:
    lodsb
    mov ah, 0x0E
    int 0x10
    loop print_six

    ; Imprime nova linha
    mov si, newline_msg
    call print_string

    inc bl               ; Próximo setor (arquivo seguinte)
    inc di               ; Incrementa índice do arquivo
    jmp read_loop

done_read:
    jmp main_loop

;-------------------------------------------------------
; Rotina para printar um número de 2 dígitos decimais (menores que 10 são printados com um '0' na frente)
;-------------------------------------------------------
print_two_digit:
    push ax
    push cx
    push dx
    mov cl, 10       ; divisor = 10
    xor dx, dx       ; zera DX para divisão de 16 bits (dividend: DX:AX)
    div cl           ; AX = número; divide por 10:
                     ;   - quociente (dígito das dezenas) fica em AL
                     ;   - resto (dígito das unidades) fica em AH
    ; Imprime dígito das dezenas
    add al, '0'
    mov bh, ah
    mov ah, 0x0E
    int 0x10
    ; Agora, o dígito das unidades está em AH
    mov al, bh
    add al, '0'
    mov ah, 0x0E
    int 0x10
    pop dx
    pop cx
    pop ax
    ret

;-------------------------------------------------------
; Reiniciar
;-------------------------------------------------------
reboot:
    int 0x19        ; Reinicia o sistema

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

disk_error:
    mov si, disk_error_msg
    call print_string
    jmp main_loop

clear_buffer:
    mov si, 0x3000          ; Endereço do buffer na memória RAM (0x3000)
    mov cx, 512             ; Tamanho do buffer (512 bytes, ou ajuste conforme necessário)
clear_loop:
    mov byte [si], 0        ; Zera o byte atual
    inc si                  ; Avança para o próximo byte
    loop clear_loop         ; Repete até limpar todos os bytes
    ret

;-------------------------------------------------------
; Dados do Kernel
;-------------------------------------------------------
kernel_msg     db "Kernel iniciado!", 13,10,0
prompt         db "CMD> ", 0
editor_msg     db "Iniciando editor...", 13,10,0
invalid_msg    db "Comando invalido!", 13,10,0
disk_error_msg db "Erro de leitura do disco!", 13,10,0

view_header    db "Arquivos salvos:", 13,10,0
open_bracket   db "[",0
close_bracket_space db "] ",0
newline_msg    db 13,10,0

file_count     dw 0              ; Variável para armazenar o contador de arquivos
; Buffer para ler o setor que contém o file_count (setor 9)
file_count_buffer  times 512 db 0

; Preenche até 2048 bytes (4 setores)
times 2048-($-$$) db 0
