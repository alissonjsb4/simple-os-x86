[BITS 16]
[ORG 0x2000]

; ============== PONTO DE ENTRADA ==============
start:
    mov ax, 0x0000
    mov ds, ax
    mov es, ax
    mov di, buffer
    
    call clear_screen
    call show_header
    jmp editor_loop

; ============== FUNÇÕES PRINCIPAIS ==============
show_header:
    mov si, editor_msg
    call print_string
    ret

editor_loop:
    call get_char
    
    ; Processar teclas especiais
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
    mov byte [di], ' '  ; Substitui por espaço ao invés de null
    call update_display
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

; ============== FUNÇÕES DE TELA ==============
clear_screen:
    mov ah, 0x06
    xor al, al
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10
    mov ah, 0x02        ; Reposicionar cursor
    xor bh, bh
    xor dx, dx
    int 0x10
    ret

update_display:
    pusha
    mov ah, 0x03        ; Salvar posição do cursor
    xor bh, bh
    int 0x10
    push dx
    
    call clear_screen
    call show_header
    
    ; Imprimir buffer
    mov cx, di
    sub cx, buffer
    mov si, buffer
.print_buffer:
    lodsb
    call print_char
    loop .print_buffer
    
    pop dx              ; Restaurar posição do cursor
    mov ah, 0x02
    int 0x10
    popa
    ret

; ============== FUNÇÕES DE DISCO ==============
save_file:
    mov ah, 0x03        ; Função de escrita
    mov al, 1           ; 1 setor
    mov ch, 0           ; Cilindro
    mov cl, 10          ; Setor
    mov dh, 0           ; Cabeça
    mov dl, 0x80        ; Drive
    mov bx, buffer
    int 0x13
    jc .error
    
    mov si, saved_msg
    call print_string
    ret
.error:
    mov si, error_msg
    call print_string
    ret

; ============== FUNÇÕES BÁSICAS ==============
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

; ============== DADOS ==============
editor_msg  db 0x0D, 0x0A, " NanoEdit 1.0 | Ctrl+S: Salvar | Backspace: Apagar", 0x0D, 0x0A
            db "----------------------------------------------------------", 0x0D, 0x0A, 0

saved_msg   db 0x0D, 0x0A, "[SUCESSO] Texto salvo no setor 10!", 0x0D, 0x0A, 0
error_msg   db 0x0D, 0x0A, "[ERRO] Falha ao salvar no disco!", 0x0D, 0x0A, 0

buffer times 254 db ' '
buffer_end db 0  ; Marcador de fim

times 1024-($-$$) db 0  ; Preencher para 2 setores
