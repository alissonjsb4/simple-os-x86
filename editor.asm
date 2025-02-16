; editor.asm
[BITS 16]
[ORG 0x2000]

start:
    cli
    cld
    mov ax, cs
    mov ds, ax
    mov es, ax

    ; Inicializa o ponteiro do buffer
    lea di, [buffer]

    ; Limpa a tela e exibe o cabeçalho
    call clear_screen
    call show_header

    ; Carrega o arquivo salvo (se existir)
    call load_file

editor_loop:
    call get_char

    cmp al, 0x13
    je do_save
    cmp al, 0x08
    je do_backspace
    cmp al, 0x0D
    je do_newline

    cmp al, 0x20
    jb editor_loop

    stosb
    call print_char
    jmp editor_loop

do_backspace:
    lea si, [buffer]
    cmp di, si
    je editor_loop
    dec di
    call backspace_cursor
    jmp editor_loop

do_newline:
    mov al, 0x0D
    call print_char
    mov al, 0x0A
    call print_char
    jmp editor_loop

do_save:
    call save_file
    jmp editor_loop

clear_screen:
    mov ah, 0x06
    xor al, al
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10

    mov ah, 0x02
    xor bh, bh
    xor dx, dx
    int 0x10
    ret

show_header:
    mov si, header
.header_loop:
    lodsb
    test al, al
    jz .done_header
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
    mov al, 0x08
    call print_char
    mov al, ' '
    call print_char
    mov al, 0x08
    call print_char
    ret

save_file:
    mov ah, 0x03
    mov al, 1
    mov ch, 0
    mov cl, 8
    mov dh, 0
    mov dl, 0x80
    mov bx, buffer
    push es
    mov ax, 0x0000
    mov es, ax
    int 0x13
    pop es
    jc .error

    mov si, saved_msg
    call print_string
    ret
.error:
    mov si, save_error_msg
    call print_string
    ret

load_file:
    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov cl, 8
    mov dh, 0
    mov dl, 0x80
    mov bx, buffer
    push es
    mov ax, 0x0000
    mov es, ax
    int 0x13
    pop es
    jc .error

    mov si, buffer
.load_print:
    lodsb
    test al, al
    jz .done_load
    call print_char
    jmp .load_print
.done_load:
    mov di, si
    dec di
    ret
.error:
    ret

print_string:
    mov ah, 0x0E
.str_loop:
    lodsb
    test al, al
    jz .done_str
    int 0x10
    jmp .str_loop
.done_str:
    ret

header db " NanoEdit 1.0", 0x0D,0x0A, "Ctrl+S: Save | Backspace: Delete | Enter: New Line", 0x0D,0x0A, "--------------------------------------------------", 0x0D,0x0A, 0
saved_msg db 0x0D,0x0A, "[SAVED] Texto salvo com sucesso!", 0x0D,0x0A, 0
save_error_msg db 0x0D,0x0A, "[ERRO] Falha ao salvar!", 0x0D,0x0A, 0
buffer times 512 db 0

times 1024 - ($ - $$) db 0
