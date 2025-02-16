[BITS 16]
[ORG 0x2000]

start:
    mov ax, 0x0000
    mov ds, ax
    mov es, ax
    mov di, buffer
    
    call clear_screen
    call show_header
    jmp editor_loop

; ========== FUNÇÕES PRINCIPAIS ==========
show_header:
    mov si, header_top
    call print_string
    mov si, header_help
    call print_string
    mov si, header_line
    call print_string
    ret

editor_loop:
    call show_cursor
    call get_char
    
    cmp al, 0x08        ; Backspace
    je .backspace
    cmp al, 0x0D        ; Enter
    je .newline
    cmp al, 0x13        ; Ctrl+S
    je .save
    
    ; Caracteres normais
    cmp di, buffer_end
    jae editor_loop
    stosb
    call print_char
    jmp editor_loop

.backspace:
    cmp di, buffer
    je editor_loop
    dec di
    call erase_char
    jmp editor_loop

.newline:
    mov al, 0x0D
    call print_char
    mov al, 0x0A
    call print_char
    jmp editor_loop

.save:
    call save_file
    jmp editor_loop

; ========== FUNÇÕES DE TELA ==========
clear_screen:
    mov ah, 0x06
    xor al, al
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10
    
    ; Reposicionar cursor no início
    mov ah, 0x02
    xor bh, bh
    xor dx, dx
    int 0x10
    ret

erase_char:
    ; Mover cursor para trás
    mov ah, 0x03
    xor bh, bh
    int 0x10
    dec dl
    mov ah, 0x02
    int 0x10
    
    ; Escrever espaço
    mov ah, 0x0A
    mov al, ' '
    mov bh, 0
    mov cx, 1
    int 0x10
    ret

show_cursor:
    mov ah, 0x02
    xor bh, bh
    int 0x10
    ret

; ========== FUNÇÕES DE DISCO ==========
save_file:
    ; ... (mesmo código anterior de salvamento)
    ret

; ========== FUNÇÕES BÁSICAS ==========
print_char:
    mov ah, 0x0E
    int 0x10
    ret

print_string:
    mov ah, 0x0E
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    ret

get_char:
    mov ah, 0x00
    int 0x16
    ret

; ========== DADOS ==========
header_top   db 0x0D, 0x0A, " NanoEdit 1.0", 0x0D, 0x0A, 0
header_help  db " Ctrl+S:Salvar | Backspace:Apagar | Enter:Nova linha", 0x0D, 0x0A, 0
header_line  db "--------------------------------------------------", 0x0D, 0x0A, 0

saved_msg    db 0x0D, 0x0A, "[SUCESSO] Texto salvo no setor 10!", 0x0D, 0x0A, 0
error_msg    db 0x0D, 0x0A, "[ERRO] Falha ao salvar!", 0x0D, 0x0A, 0

buffer times 254 db 0
buffer_end db 0

times 1024-($-$$) db 0
