[BITS 16]
[ORG 0x2000]

start:
    mov ax, 0x0000
    mov ds, ax
    mov es, ax          ; <-- Adicionado ES
    mov di, buffer
    call clear_screen    ; <-- Limpar tela antes de mostrar header
    mov si, editor_msg
    call print_string

editor_loop:
    call get_char
    cmp al, 0x08        ; Backspace
    je .backspace
    cmp al, 0x0D        ; Enter <-- Nova verificação
    je .newline
    cmp al, 0x13        ; Ctrl+S
    je .save
    cmp di, buffer+256
    jae editor_loop     ; <-- Corrigido para JAE
    
    ; Tratar espaço e caracteres normais
    stosb
    call print_char
    jmp editor_loop

.backspace:
    cmp di, buffer
    jbe editor_loop     ; <-- Impede underflow
    dec di
    mov byte [di], 0
    call update_screen  ; <-- Substituído clear_screen
    jmp editor_loop

.newline:               ; <-- Nova rotina para Enter
    mov al, 0x0D
    call print_char
    mov al, 0x0A
    call print_char
    jmp editor_loop

.save:
    ; ... (restante igual) 

; --- Funções Atualizadas ---
update_screen:          ; <-- Nova função para refresh parcial
    pusha
    mov ah, 0x03        ; Get cursor position
    xor bh, bh
    int 0x10
    
    mov ah, 0x02        ; Set cursor to start of input area
    mov dl, 0
    mov dh, 2           ; Abaixo do header
    int 0x10
    
    ; Apagar linha atual
    mov ah, 0x09
    mov al, ' '
    mov bh, 0
    mov bl, 0x07
    mov cx, 80
    int 0x10
    
    ; Reimprimir buffer
    mov si, buffer
    call print_string
    
    popa
    ret

print_char:
    mov ah, 0x0E
    cmp al, 0x0D        ; Tratar Enter
    jne .normal
    mov al, 0x0D
    int 0x10
    mov al, 0x0A
.normal:
    int 0x10
    ret

; ... (restante das funções igual)

editor_msg  db 0x0D, 0x0A, "[EDITOR] Digite seu texto (Ctrl+S salva)", 0x0D, 0x0A
            db "Backspace: Apagar | Enter: Nova linha", 0x0D, 0x0A, 0
