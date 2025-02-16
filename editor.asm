; editor.asm
[BITS 16]
[ORG 0x2000]

start:
    cli
    cld
    ; Assumindo que CS já contém o segmento correto, fazemos:
    mov ax, cs
    mov ds, ax
    mov es, ax

    ; Inicializa o ponteiro do buffer para edição
    lea di, [buffer]

    ; Limpa a tela e exibe o cabeçalho
    call clear_screen
    call show_header

editor_loop:
    ; Espera pela entrada de um caractere (resultado em AL)
    call get_char

    ; Verifica se foi pressionado Ctrl+S (0x13)
    cmp al, 0x13
    je do_save
    ; Verifica Backspace (0x08)
    cmp al, 0x08
    je do_backspace
    ; Verifica Enter (0x0D)
    cmp al, 0x0D
    je do_newline

    ; Se o caractere for imprimível (>= 0x20), o processa
    cmp al, 0x20
    jb editor_loop  ; ignora outros controles

    ; Armazena o caractere no buffer e exibe-o na tela
    stosb         ; armazena AL em [DI] e incrementa DI
    call print_char
    jmp editor_loop

do_backspace:
    ; Se DI estiver no início do buffer, não faz nada
    lea si, [buffer]
    cmp di, si
    je editor_loop
    dec di        ; retrocede o ponteiro do buffer
    call backspace_cursor
    jmp editor_loop

do_newline:
    ; Imprime CR+LF na tela (sem armazenar no buffer)
    mov al, 0x0D
    call print_char
    mov al, 0x0A
    call print_char
    jmp editor_loop

do_save:
    call save_file
    jmp editor_loop

; ========================= FUNÇÕES DE TELA =========================

clear_screen:
    ; Função BIOS 0x06 para rolagem (limpa a tela)
    mov ah, 0x06
    xor al, al      ; número de linhas a rolar (0 = limpar toda a tela)
    mov bh, 0x07    ; atributo padrão (branco em preto)
    mov cx, 0x0000  ; canto superior esquerdo
    mov dx, 0x184F  ; canto inferior direito (80 colunas x 25 linhas)
    int 0x10

    ; Reposiciona o cursor no canto superior esquerdo
    mov ah, 0x02
    xor bh, bh
    xor dx, dx
    int 0x10
    ret

show_header:
    mov si, header
.header_loop:
    lodsb
    cmp al, 0
    je .done_header
    call print_char
    jmp .header_loop
.done_header:
    ret

print_char:
    mov ah, 0x0E
    int 0x10
    ret

get_char:
    mov ah, 0x00
    int 0x16
    ret

backspace_cursor:
    ; Para simular o backspace: move o cursor para trás, escreve espaço e move novamente para trás
    mov al, 0x08
    call print_char   ; imprime o caractere de backspace
    mov al, ' '
    call print_char   ; sobrescreve com espaço
    mov al, 0x08
    call print_char   ; volta o cursor para a posição anterior
    ret

save_file:
    ; Simulação de salvamento: apenas exibe uma mensagem
    mov si, saved_msg
    call print_string
    ret

print_string:
    mov ah, 0x0E
.str_loop:
    lodsb
    cmp al, 0
    je .done_str
    int 0x10
    jmp .str_loop
.done_str:
    ret

; ========================= DADOS =========================

header db 0x0D,0x0A, " NanoEdit 1.0", 0x0D,0x0A, "Ctrl+S: Save | Backspace: Delete | Enter: New Line", 0x0D,0x0A, "--------------------------------------------------", 0x0D,0x0A, 0
saved_msg db 0x0D,0x0A, "[SAVED] Text saved!", 0x0D,0x0A, 0
buffer times 512 db 0
