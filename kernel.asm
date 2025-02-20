[BITS 16]
[ORG 0x1000]

;---------------------------------------------------------------------------------------------------
; Kernel e seus comandos:
; - Exibe uma mensagem inicial ao iniciar.
; - Aceita comandos do usuário ('e' para editor, 'r' para reiniciar, 'v' para visualizar textos, 'd' para deletar um texto).
; - Lê e escreve em setores do disco.
; - Garante interação básica com o usuário e manipulação de arquivos.
;---------------------------------------------------------------------------------------------------

%define OLD_DATA_ADDR 0x3000

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
    cmp al, 'd'
    je delete_text

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
    mov cl, 9             ; Setor 9
    mov bx, file_count_buffer
    call sector_read

    ; 2) Extrair o contador do primeiro byte do buffer
    mov al, [file_count_buffer]  ; Supõe que o contador está no primeiro byte
    mov [file_count], ax         ; Armazena em file_count (word)

    ; Exibe um cabeçalho
    mov si, view_header
    call print_string

    ; 3) Loop para ler e imprimir cada arquivo
    xor di, di            ; DI = 0 (índice do arquivo, 0-based)
    mov bl, 10            ; Primeiro setor de arquivo é 10

    call read_loop

done_read:
    call clear_buffer               ; Limpa o buffer, higiene, né?
    cmp byte [sector_number], 10    ; Verifica se existem ou não arquivos salvos.
    je main_loop                    ; Se não, volta ao loop.

    mov al, 10                      ; Já vimos que existem arquivos, vamos então
    mov [sector_number], al         ; limpar o contador para a próxima execução

    mov si, view_msg                ; Se sim, vai pedir para você escolher qual quer ver
    call print_string
    call read_two_digits            ; Vai permitir que você digite o valor 

    cmp bl, 0 
    je  retorno_main
    mov ax, di
    cmp al, bl                      ; O valor supera o número de arquivos salvos?
    jl  invalid_sector
    cmp bl, 1                       ; O valor é menor que 01?
    jl  invalid_sector

    call clear_screen
    mov dh, 0
    mov dl, 1
    call set_cursor    
    mov si, reading_msg1
    call print_string
    mov ax, bx
    call print_two_digit
    mov si, reading_msg2
    call print_string
    mov dh, 2
    mov dl, 1
    call set_cursor
    call read_and_print_sector

    jmp main_loop

;-------------------------------------------------------
; Comando 'd' - Deletar arquivo salvo
;-------------------------------------------------------
delete_text:
    call clear_screen
    mov dh, 0
    mov dl, 0
    call set_cursor

    ; 1) Ler o setor 9 (que contém o file_count) para o buffer file_count_buffer
    mov cl, 9             ; Setor 9
    mov bx, file_count_buffer
    call sector_read

    ; 2) Extrair o contador do primeiro byte do buffer
    mov al, [file_count_buffer]  ; Supõe que o contador está no primeiro byte
    mov [file_count], ax         ; Armazena em file_count (word)
    mov al, [file_count]
    add al, '0'
    call print_char

    ; Exibe um cabeçalho
    mov si, view_header
    call print_string

    ; 3) Loop para ler e imprimir cada arquivo
    xor di, di            ; DI = 0 (índice do arquivo, 0-based)
    mov bl, 10            ; Primeiro setor de arquivo é 10
    
    call delete_loop

delete_ready:
    call clear_buffer               ; Limpa o buffer, higiene, né?
    cmp byte [sector_number], 10    ; Verifica se existem ou não arquivos salvos.
    je main_loop                    ; Se não, volta ao loop.

    mov al, 10                      ; Já vimos que existem arquivos, vamos então
    mov [sector_number], al         ; limpar o contador para a próxima execução

    mov si, delete_msg                ; Se sim, vai pedir para você escolher qual quer deletar
    call print_string
    call read_two_digits            ; Vai permitir que você digite o valor 

    cmp bl, 0 
    je  retorno_main
    mov ax, di
    cmp al, bl                      ; O valor supera o número de arquivos salvos?
    jl  invalid_sector
    cmp bl, 1                       ; O valor é menor que 01?
    jl  invalid_sector

    call write_swap_and_clear

    ; Decrementa o contador de arquivos
    dec word [file_count]
    mov cl, 9
    mov bx, OLD_DATA_ADDR
    mov al, [file_count]
    mov [OLD_DATA_ADDR], al
    call sector_write       ; Chama a rotina de escrita do setor (ES:BX = 0000:3000)

    jmp main_loop

;-------------------------------------------------------
; Rotina para substituir um setor do disco pelo último
;-------------------------------------------------------
write_swap_and_clear:
    
    mov [sector_number], bl

    ; Passo 1: Escreve zeros no setor (NúmeroDigitado + 9)
    mov cl, 9             
    add cl, [sector_number]; CL = setor (NúmeroDigitado + 9)
    mov bx, 0x3000         ; Buffer temporário
    call fill_with_zero    ; Preenche 0x3000 com 512 zeros
    call sector_write      ; Escreve o setor com zeros

    ; Passo 2: Lê o último setor para o buffer 0x3000
    mov cl, [file_count]  
    add cl, 9
    mov bx, 0x3000
    call sector_read       ; Lê o setor para 0x3000

    ; Passo 3: Escreve o conteúdo lido no setor (NúmeroDigitado + 9)
    mov cl, 9
    add cl, [sector_number]; CL = setor (NúmeroDigitado + 9)
    call sector_write      ; Escreve o conteúdo do buffer

    ; Passo 4: Escreve zeros no setor (DI + 10)
    call fill_with_zero    ; Preenche 0x3000 com zeros novamente
    mov cl, 9
    mov al, [file_count]
    mov [OLD_DATA_ADDR], al
    mov bx, OLD_DATA_ADDR
    call sector_write      ; Sobrescreve com zeros

    ret                    

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
; Rotina para ler um setor do disco e imprimir todo o seu conteúdo.
;-------------------------------------------------------
read_and_print_sector:
    push ax
    push bx
    push cx
    push dx
    push es

    ; Lê o setor
    mov cl, 9            ; "Inicializa" a busca pelo setor certo no setor 9
    add cl, bl           ; Busca o setor selecionado pelo usuário (9 + bl)
    mov bx, 0x3000       ; Buffer temporário para o arquivo
    call sector_read

    ; Imprimir o conteúdo do setor
    mov cx, 512          ; O setor tem 512 bytes
    mov si, 0x3000       ; Endereço do buffer de dados lidos

print_loop:
    lodsb                ; Carrega o byte em AL
    mov ah, 0x0E         ; Função de impressão no modo texto
    int 0x10             ; Chama a interrupção de vídeo para imprimir
    loop print_loop      ; Repete até imprimir todos os 512 bytes

    call wait_key
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    call clear_screen
    mov dh, 0
    mov dl, 0
    call set_cursor
    mov si, kernel_msg
    call print_string
    jmp main_loop

;-------------------------------------------------------
; Reiniciar
;-------------------------------------------------------
reboot:
    call clear_screen
    mov dh, 0
    mov dl, 0
    call set_cursor
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

print_char:
    mov ah, 0x0E        ; Função de teletipo (imprimir caractere na tela)
    int 0x10            ; Chama a interrupção BIOS para imprimir o caractere em AL
    ret

read_two_digits:
    call wait_key          ; Chama wait_key para pegar o primeiro dígito
    call print_char
    mov bl, al             ; Armazena o primeiro dígito em BL (pode ser qualquer registrador)

    call wait_key          ; Chama wait_key para pegar o segundo dígito
    call print_char
    mov bh, al             ; Armazena o segundo dígito em BH

    call convert_to_hex
    ret

convert_to_hex:
    mov al, bl            ; Move a dezena decimal para AL
    mov ah, 10            ; Define o multiplicador para converter decimal em hexadecimal
    mul ah                ; AL = AL * 10 (multiplica a dezena por 10)
    add al, bh            ; Soma a unidade decimal
    sub al, 10h           
    mov bl, al            ; Armazena o resultado em BL

    ret


disk_error:
    mov si, disk_error_msg
    call print_string
    jmp main_loop

clear_buffer:
    mov si, 0x3000          ; Endereço do buffer na memória RAM (0x3000)
    mov cx, 512             ; Tamanho do buffer (512 bytes)
clear_loop:
    mov byte [si], 0        ; Zera o byte atual
    inc si                  ; Avança para o próximo byte
    loop clear_loop         ; Repete até limpar todos os bytes
    ret

invalid_sector:
    mov si, invalid_sector_msg
    call print_string
    jmp done_read

retorno_main:
    call clear_screen
    mov dh, 0
    mov dl, 0
    call set_cursor
    mov si, kernel_msg
    call print_string
    jmp main_loop

sector_read:
    mov ah, 0x02         ; Função: Ler setores do disco
    mov al, 1            ; Número de setores a ler (1 setor)
    mov ch, 0
    mov dh, 0
    mov dl, 0x80
    int 0x13
    jc disk_error
    ret

sector_write:
    mov ah, 0x03       ; Função de escrita de setor
    mov al, 1          ; Número de setores a escrever (1)
    mov ch, 0          
    mov dh, 0          
    mov dl, 0x80          
    int 0x13              ; Chama a interrupção de disco
    jc disk_error
    ret

fill_with_zero:
    push ax
    push cx
    push di
    push es
    mov ax, 0x0000         ; Segmento 0x0000
    mov es, ax
    mov di, 0x3000         ; Offset 0x3000 (ES:DI = 0000:3000)
    mov cx, 512            ; 512 bytes
    xor al, al             ; AL = 0
    rep stosb              ; Preenche com zeros
    pop es
    pop di
    pop cx
    pop ax
    ret

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

    ; 4) Ler o setor (número em BL) para o buffer temporário em 0x3000
    mov cl, [sector_number]
    mov bx, 0x3000
    call sector_read

    ; 5) Imprimir os 10 primeiros bytes do arquivo
    mov cx, 10            ; Quantidade de bytes a imprimir
    mov si, 0x3000       ; Início do buffer

    call print_ten
    jmp read_loop

delete_loop:
    cmp di, [file_count]
    jae delete_ready         ; Se DI >= file_count, encerra

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

    ; 4) Ler o setor (número em BL) para o buffer temporário em 0x3000
    mov cl, [sector_number]
    mov bx, 0x3000
    call sector_read

    ; 5) Imprimir os 10 primeiros bytes do arquivo
    mov cx, 10            ; Quantidade de bytes a imprimir
    mov si, 0x3000       ; Início do buffer

    call print_ten
    jmp delete_loop

print_ten:
    lodsb
    mov ah, 0x0E
    int 0x10
    loop print_ten

    ; Imprime nova linha
    mov si, newline_msg
    call print_string

    inc byte [sector_number]               ; Próximo setor (arquivo seguinte)
    inc di                                 ; Incrementa índice do arquivo
    ret
;-------------------------------------------------------
; Dados do Kernel
;-------------------------------------------------------
kernel_msg:
    db "========= KERNEL =========",13,10
    db " Comandos disponiveis:",13,10
    db " e - Editor de texto",13,10
    db " v - Visualizar textos",13,10
    db " d - Deletar texto", 13, 10
    db " r - Reiniciar sistema",13,10
    db "--------------------------", 13, 10,0

prompt:
    db  13, 10, "CMD> ", 0

editor_msg:
    db "Iniciando editor...", 13,10,0

invalid_msg:
    db "Comando invalido!", 13,10,0

disk_error_msg:
    db "Erro de leitura do disco!", 13,10,0

view_header:
    db "Arquivos salvos:", 13,10,0

view_msg:
    db "Valor do arq. que queres abrir ('00' para retornar):", 0

reading_msg1:
    db "Conteudo do arquivo ", 0
reading_msg2:
    db " (clique qualquer tecla para sair):", 13, 10, 0 

delete_msg:
    db "Valor do arq. que queres deletar ('00' para retornar):", 0

invalid_sector_msg:
    db "Arquivo nao existente!", 13, 10, 0

open_bracket:
    db "[",0

close_bracket_space:
    db "] ",0

newline_msg:
    db 13,10,0

file_count:
    dw 0              ; Variável para armazenar o contador de arquivos

sector_number:
    db 10             ; Variável para armazenar o setor analisado atualmente

; Buffer para ler o setor que contém o file_count (setor 9)
file_count_buffer:
    times 512 db 0

; Preenche até 2048 bytes (4 setores)
times 2048-($-$$) db 0
