 [BITS 16]
[ORG 0x2000]

;-----------------------------------------------------------
; Editor de texto com:
; - Cabeçalho no topo (linha 0)
; - Área de edição a partir da linha 5
; - Salvar real (Ctrl+S) que anexa o novo texto com separação
;   e garante que o texto salvo termine com nova linha.
; - Sair (Esc) voltando ao kernel
;-----------------------------------------------------------

%define FILE_COUNTER_SECTOR 0x09  ; Setor onde o contador de arquivos será armazenado (setor 9)
%define OLD_DATA_ADDR 0x3000     ; Endereço temporário para ler/escrever o setor salvo

start:
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; Inicializa o contador de arquivos
    call load_file_counter

    call clear_screen

    ; Posiciona o cursor em 0,0 para imprimir o cabeçalho
    mov dx, 0
    call set_cursor

    ; Imprime o cabeçalho (linha 0 a 3)
    mov si, header
    call print_string

    ; Posiciona o cursor na linha 5, coluna 0 para iniciar a edição
    mov dh, 5
    mov dl, 0
    call set_cursor

    ; Inicializa o índice do buffer do editor
    mov word [buffer_index], 0

edit_loop:
    call wait_key

    ; Se pressionar ESC, sai para o kernel
    cmp al, 0x1B       ; ESC
    je exit_editor

    cmp al, 0x08       ; Backspace
    je handle_backspace
    cmp al, 0x0D       ; Enter
    je handle_newline
    cmp al, 0x13       ; Ctrl+S
    je save_file

    ; Caractere normal: armazena no buffer e imprime
    mov bx, [buffer_index]
    cmp bx, BUFFER_SIZE
    jae skip_store        ; se excedeu o limite, ignora
    mov di, bx
    mov [buffer + di], al
    inc bx
    mov [buffer_index], bx

skip_store:
    call print_char
    inc dl
    cmp dl, 80       ; Verifica fim da linha
    jne .update
    xor dl, dl
    inc dh
    cmp dh, 25       ; Verifica fim da tela
    jb .update
    dec dh
.update:
    call set_cursor
    jmp edit_loop

;-----------------------------------------------------------
; BACKSPACE
;-----------------------------------------------------------
handle_backspace:
    mov bx, [buffer_index]
    cmp bx, 0
    je edit_loop          ; nada para apagar

    dec bx
    mov [buffer_index], bx

    cmp dl, 0
    jne .backspace_normal
    ; Se coluna = 0, volta para a linha anterior, mas nunca acima da linha 5
    cmp dh, 5
    jle edit_loop
    dec dh
    mov dl, 79
    jmp .backspace_normal

.backspace_normal:
    dec dl
    call set_cursor
    mov al, ' '
    call print_char
    call set_cursor
    jmp edit_loop

;-----------------------------------------------------------
; ENTER (nova linha)
;-----------------------------------------------------------
handle_newline:
    ; Armazena CR e LF no buffer (se couber)
    mov bx, [buffer_index]
    cmp bx, BUFFER_SIZE - 2
    jae .skip_store_enter
    mov di, bx
    mov byte [buffer + di], 13
    inc bx
    mov di, bx
    mov byte [buffer + di], 10
    inc bx
    mov [buffer_index], bx

.skip_store_enter:
    inc dh
    cmp dh, 25
    jb .ok_enter
    dec dh
.ok_enter:
    xor dl, dl
    call set_cursor
    jmp edit_loop

;-----------------------------------------------------------
; SALVAR (Ctrl+S)
;-----------------------------------------------------------
save_file: 
    ; 0) Limpa o buffer da memória RAM que será usado para carregar o texto
    call clear_buffer
    mov di, OLD_DATA_ADDR

no_newline:
    ; 4) Copiar o novo texto (do buffer) para o final do conteúdo lido
    mov bx, [buffer_index]  ; Tamanho do novo texto digitado
    mov si, buffer
copy_loop:
    cmp bx, 0
    je done_copy
    cmp di, OLD_DATA_ADDR + 509
    jae done_copy
    lodsb
    mov [di], al
    inc di
    dec bx
    jmp copy_loop

done_copy:
    ; 4.5) Verifica se o novo texto já termina com LF; se não, acrescenta CR+LF.
    cmp di, OLD_DATA_ADDR
    je append_done        ; se nada foi copiado, pula
    mov al, [di-1]
    cmp al, 10
    je append_done
    mov byte [di], 13
    inc di
    mov byte [di], 10
    inc di
append_done:
    mov byte [di], 0

    ; 5) Escrever o setor de volta no disco (setor atual)
    mov ah, 0x03      ; Função: Escrever setores
    mov al, 1         ; 1 setor
    mov ch, 0
    mov cl, 10        ; Setor inicial (10)
    add cl, [file_counter]  ; Adiciona o contador ao setor (10 + file_counter)
    mov dh, 0
    mov dl, 0x80
    mov bx, OLD_DATA_ADDR
    int 0x13
    jc save_error

    ; 6) Incrementar o contador de arquivos
    inc byte [file_counter]

    ; 7) Salvar o file_counter de volta no setor 9
    mov ah, 0x03      ; Função: Escrever setores
    mov ch, 0
    mov cl, FILE_COUNTER_SECTOR   ; Setor 9 onde o file_counter será armazenado
    mov dh, 0
    mov dl, 0x80
    mov bx, OLD_DATA_ADDR
    mov al, [file_counter]       ; Carrega o valor de file_counter em AL
    mov [OLD_DATA_ADDR], al      ; Salva o valor de AL em OLD_DATA_ADDR
    mov al, 1         ; 1 setor
    int 0x13
    jc save_error

    ; Exibe mensagem de sucesso com o número do arquivo
    mov si, saved_msg
    call print_string
    mov ax, [file_counter]
    and ax, 0x00FF  ; Garante que o valor esteja em 8 bits
    call print_two_digit
    mov si, newline_msg
    call print_string
    call wait_key
    jmp exit_editor

save_error:
    mov si, error_msg
    call print_string
    jmp edit_loop

;-----------------------------------------------------------
; ESC (sair para o kernel)
;-----------------------------------------------------------

exit_editor:
    jmp 0x0000:0x1000

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

;-----------------------------------------------------------
; Rotinas Auxiliares
;-----------------------------------------------------------

clear_screen:
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10
    ret

print_string:
    mov ah, 0x0E
.str_loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .str_loop
.done:
    ret

set_cursor:
    mov ah, 0x02
    xor bh, bh
    int 0x10
    ret

wait_key:
    mov ah, 0x00
    int 0x16
    ret

print_char:
    mov ah, 0x0E
    int 0x10
    ret

load_file_counter:
    mov ah, 0x02          ; Função: Ler setores
    mov al, 1             ; Ler 1 setor
    mov ch, 0
    mov cl, FILE_COUNTER_SECTOR  ; Setor 9
    mov dh, 0
    mov dl, 0x80         ; Drive primário
    mov bx, OLD_DATA_ADDR ; Endereço temporário
    int 0x13
    jc init_file_counter  ; Se falhar, inicializa com 0

    ; Supondo que o contador esteja armazenado no primeiro byte do setor
    mov al, [OLD_DATA_ADDR]
    mov [file_counter], al
    ret

init_file_counter:
    mov byte [file_counter], 0
    ret

clear_buffer:
    mov si, 0x3000          ; Endereço do buffer na memória RAM (0x3000)
    mov cx, BUFFER_SIZE     ; Tamanho do buffer (512 bytes, ou ajuste conforme necessário)
clear_loop:
    mov byte [si], 0        ; Zera o byte atual
    inc si                  ; Avança para o próximo byte
    loop clear_loop         ; Repete até limpar todos os bytes
    ret

;-----------------------------------------------------------
; Dados
;-----------------------------------------------------------

header:
    db "======== EDITOR DE TEXTO ========",13,10
    db " Ctrl+S: Salvar  Backspace: Apagar ",13,10
    db " Enter: Nova linha  Esc: Voltar ao Kernel ",13,10
    db "---------------------------------",0

saved_msg:
    db 13,10,"[Texto salvo com sucesso! Arquivo ",0

error_msg:
    db 13,10,"[Erro ao salvar o arquivo!]",0

newline_msg:
    db 13,10,0

BUFFER_SIZE equ 512

buffer:
    times BUFFER_SIZE db 0

buffer_index:
    dw 0

file_counter:
    db 0
