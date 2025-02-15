[BITS 16]
[ORG 0x2000]

start:
    mov di, buffer      ; Inicializa ponteiro do buffer
    mov si, editor_msg
    call print_string

editor_loop:
    call get_char
    cmp al, 0x08        ; Backspace
    je .backspace
    cmp al, 0x13        ; Ctrl+S
    je .save
    cmp di, buffer+255  ; Verifica limite do buffer
    je editor_loop
    stosb               ; Armazena caractere
    call print_char
    jmp editor_loop

.backspace:
    cmp di, buffer
    je editor_loop
    dec di
    mov byte [di], 0
    call clear_screen
    mov si, editor_msg  ; Reimprime cabeçalho
    call print_string
    mov si, buffer
    call print_string
    jmp editor_loop

.save:
    ; Salvar no setor 10 (LBA)
    mov ah, 0x03        ; Função de escrita
    mov al, 1           ; 1 setor
    mov ch, 0           ; Cilindro
    mov cl, 10          ; Setor
    mov dh, 0           ; Cabeça
    mov dl, 0x80        ; Drive (HD)
    mov bx, buffer      ; ES:BX = buffer
    int 0x13
    jc .error
    mov si, saved_msg
    jmp .exit

.error:
    mov si, error_msg

.exit:
    call print_string
    jmp 0x1000          ; Retorna ao kernel

get_char:
    mov ah, 0x00
    int 0x16
    ret

print_char:
    mov ah, 0x0E
    int 0x10
    ret

clear_screen:
    mov ah, 0x06
    xor al, al
    mov bh, 0x07        ; Atributo branco/preto
    mov cx, 0x0000      ; Canto superior esquerdo
    mov dx, 0x184F      ; Canto inferior direito (80x25)
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

editor_msg  db "[EDITOR] Digite seu texto:", 13, 10
            db "Backspace: Apagar | Ctrl+S: Salvar", 13, 10, 0
saved_msg   db 13, 10, "Texto salvo no setor 10! Voltando ao kernel...", 13, 10, 0
error_msg   db 13, 10, "[ERRO] Falha ao salvar! Reiniciando...", 13, 10, 0
buffer times 256 db 0
