[BITS 16]       ; informa ao assembler que o código é para o modo real
[ORG 0x7C00]    ; código vai ser carregado nesse endereço por padrão (BIOS carrega o primeiro setor aqui)

start:
    cli         ; desativa as interrupções
    cld         ; limpador de flag de direção
    xor ax, ax  ; pro AX ser zero

    ;Definição dos segmentos de memória como zero
    mov ds, ax  
    mov es, ax
    mov ss, ax
  
    mov sp, 0x7C00 ; define a pilha do mesmo local do bootloader

    ;Exibe mensagem inicial
    mov si, boot_msg  
    call print_string

    ; Carregar kernel (LBA 3-6, CHS: C=0,H=0,S=3)
    mov bx, 0x1000 ; destino nesse endereço de memória
    mov ah, 0x02   ; função de leitura
    mov al, 4      ; número de setores a ler, vai ser o 3, 4, 5 e 6
    mov ch, 0      ; cilindro = 0
    mov cl, 3      ; começa no setor = 3
    mov dh, 0      ; cabeça = 0
    mov dl, 0x80   ; indica o disco rígido principal
    int 0x13       ; interrupção pra ler o disco
    jc error       ; se houver erro, pula pra error
    cmp al, 4      ; confirma se os 4 setores foram lidos 
    jne error      ; se não foram lidos corretamente, pula pra error

    ;Exibe mensagem
    mov si, kernel_msg
    call print_string

    ; Carregar editor (LBA 7-9, CHS: C=0,H=0,S=7)
    mov bx, 0x2000 ; o destino
    mov ah, 0x02   ; ler do disco
    mov al, 3      ; ler 3 setores
    mov cl, 7      ; começa no 7º setor
    int 0x13       ; leitura do disco
    jc error       ; verifica erro
    cmp al, 3      ; confirma se foram lidos corretamente
    jne error      ; se não foram, pula pra error

    ; Exibe mensagem
    mov si, editor_msg
    call print_string

    ; Aguarda tecla antes de executar kernel e mostra a mensagem pra pressionar qualquer tecla
    mov si, press_key_msg
    call print_string 
    call wait_key

    jmp 0x0000:0x1000 ; salto para onde o kernel foi carregado, dando controle ao kernel

error:
    mov si, msg_error ; este bloco todo vai ser uma rotina de erro
    call print_string
    mov ah, 0x00      ; função da bios que espera uma recla ser pressionada, 
    int 0x16          ; espera uma tecla ser pressionada e guarda o código da tecla (scan e ascii, em AH e AL)
    int 0x19          ; interrupção pra reiniciar o sistema

; Rotina pra imprimir as strings
print_string:
    mov ah, 0x0E      ; modo de saída de texto da BIOS
.print_loop:
    lodsb             ; lê um byte da string apontada por SI
    test al, al       ; se AL for zero, chegou no fim da string e sai do loop
    jz .done
    int 0x10          ; imprime o caractere armazenado
    jmp .print_loop
.done:
    ret

; Rotina que espera a tecla, retorna quando é pressionada
wait_key:
    mov ah, 0x00
    int 0x16
    ret               ; retorna ao endereço de quem chamou a rotina

; Mensagens de texto que são utilizadas 
boot_msg    db "[1] Bootloader OK!", 13, 10, 0
kernel_msg  db "[2] Kernel carregado!", 13, 10, 0
editor_msg  db "[3] Editor carregado!", 13, 10, 0
msg_error   db "Erro de disco!", 0
press_key_msg db "[!] Pressione qualquer tecla...", 13, 10, 0

; Finalização (preenche os espaços restantes com 0, deixando os últimos 2 bytes com AA55, indicador de que este é o bootloader)
times 510-($-$$) db 0
dw 0xAA55
