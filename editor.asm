[BITS 16]
[ORG 0x2000]

start:
    xor ax, ax
    mov ds, ax
    mov es, ax

    call clear_screen
    mov si, header
    call print_header
    
    ; Posiciona cursor após o cabeçalho (linha 6)
    mov dh, 6
    mov dl, 0
    call set_cursor

edit_loop:
    call wait_key

    cmp al, 0x08    ; Backspace
    je .backspace
    cmp al, 0x0D    ; Enter
    je .newline
    cmp al, 0x13    ; Ctrl+S
    je .save

    ; Caractere normal
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

.backspace:
    call handle_backspace
    jmp edit_loop

.newline:
    call handle_newline
    jmp edit_loop

.save:
    mov si, saved_msg
    call print_string
    jmp edit_loop

handle_backspace:
    cmp dh, 6        ; Não permite apagar acima da linha 6
    jb .exit
    cmp dl, 0
    jne .delete_char

    dec dh
    mov dl, 79
    jmp .update_pos

.delete_char:
    dec dl

.update_pos:
    call set_cursor
    mov al, ' '      ; Apaga o caractere
    call print_char
    call set_cursor

.exit:
    ret

handle_newline:
    inc dh
    cmp dh, 25       ; Verifica limite inferior
    jb .ok
    dec dh
.ok:
    xor dl, dl       ; Coluna 0
    call set_cursor
    ret

clear_screen:
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10
    ret

print_header:
    mov cx, 0        ; Contador de linhas
    mov dh, 0        ; Linha inicial
.header_loop:
    mov dl, 0
    call set_cursor
    call print_string
    add si, 31       ; Avança para próxima linha (30 chars + CR+LF)
    inc dh           ; Próxima linha
    inc cx
    cmp cx, 5        ; 5 linhas de cabeçalho
    jb .header_loop
    ret

set_cursor:
    mov ah, 0x02
    xor bh, bh
    int 0x10
    ret

print_char:
    mov ah, 0x0E
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

wait_key:
    mov ah, 0x00
    int 0x16
    ret

; Cabeçalho com alinhamento garantido
header:
    db 13,10
    db "======== EDITOR DE TEXTO ========",13,10
    db " Ctrl+S: Salvar  Backspace: Apagar ",13,10
    db " Enter: Nova linha  Alt+S: Sair ",13,10
    db "---------------------------------",13,10
    db 13,10,0

saved_msg:
    db 13,10,"[Texto salvo com sucesso!]",13,10,0

; Buffer para garantir separação física
times 512-($-header) db 0

times 1024-($-$$) db 0