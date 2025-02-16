[BITS 16]
[ORG 0x2000]

start:
    cli
    cld
    ; Ajusta segmentos para DS/ES
    mov ax, cs
    mov ds, ax
    mov es, ax

    ; Inicializa o ponteiro do buffer
    lea di, [buffer]

    ; Limpa a tela e exibe cabeçalho
    call clear_screen
    call show_header
    call set_cursor  ; Cursor logo abaixo do cabeçalho

editor_loop:
    ; Ler uma tecla em AL
    call get_char

    ; Verifica combinações especiais:
    ; Ctrl+S (0x13) -> Salvar
    cmp al, 0x13
    je do_save

    ; Ctrl+L (0x0C) -> Carregar
    cmp al, 0x0C
    je do_load

    ; Backspace (0x08)
    cmp al, 0x08
    je do_backspace

    ; Enter (0x0D)
    cmp al, 0x0D
    je do_newline

    ; Se o caractere for < 0x20, ignora (controle)
    cmp al, 0x20
    jb editor_loop

    ; Armazena o caractere no buffer e exibe na tela
    stosb
    call print_char
    jmp editor_loop

do_backspace:
    ; Se di == buffer, não há o que apagar
    lea si, [buffer]
    cmp di, si
    je editor_loop
    dec di
    call backspace_cursor
    jmp editor_loop

do_newline:
    ; Imprime CR+LF
    mov al, 0x0D
    call print_char
    mov al, 0x0A
    call print_char
    jmp editor_loop

do_save:
    call save_file
    jmp editor_loop

do_load:
    call load_file
    jmp editor_loop

; ========================= FUNÇÕES DE TELA =========================

clear_screen:
    ; Limpar a tela (rolagem total)
    mov ah, 0x06
    xor al, al
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10

    ; Cursor para (0,0)
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

set_cursor:
    ; Move cursor para linha 5, coluna 0
    mov ah, 0x02
    mov bh, 0
    mov dh, 5   ; linha 5
    mov dl, 0   ; coluna 0
    int 0x10
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
    ; Move cursor p/ trás, imprime espaço e volta novamente
    mov al, 0x08
    call print_char
    mov al, ' '
    call print_char
    mov al, 0x08
    call print_char
    ret

; ========================= SALVAR/CARREGAR =========================

save_file:
    mov si, saved_msg
    call print_string

    ; Grava o buffer (512 bytes) no setor 8
    mov bx, buffer
    mov ah, 0x03    ; Função BIOS: escrever setor
    mov al, 1       ; 1 setor
    mov ch, 0
    mov cl, 8       ; Setor 8
    mov dh, 0
    mov dl, 0x80
    int 0x13
    ret

load_file:
    ; Lê o setor 8 de volta para o buffer
    mov bx, buffer
    mov ah, 0x02    ; Função BIOS: ler setor
    mov al, 1
    mov ch, 0
    mov cl, 8
    mov dh, 0
    mov dl, 0x80
    int 0x13

    mov si, loaded_msg
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

header db 0x0D,0x0A, " NanoEdit 1.0", 0x0D,0x0A, \
       "Ctrl+S: Save | Ctrl+L: Load | Backspace: Delete | Enter: New Line", 0x0D,0x0A, \
       "--------------------------------------------------", 0x0D,0x0A, 0

saved_msg  db 0x0D,0x0A, "[SAVED] Texto salvo no setor 8!", 0x0D,0x0A, 0
loaded_msg db 0x0D,0x0A, "[LOADED] Texto carregado do setor 8!", 0x0D,0x0A, 0

buffer times 512 db 0

; Preenche até 1024 bytes (2 setores)
times 1024 - ($ - $$) db 0
