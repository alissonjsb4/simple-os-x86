# simple-os-x86

Sistema operacional de 16 bits para x86 em modo real, escrito em Assembly:
bootloader MBR de 512 bytes, kernel com prompt de comandos e editor de texto que
grava em disco. Projeto da disciplina de Microprocessadores (UFC), em equipe de
sete.

## Uso

    ./build.sh
    qemu-system-x86_64 -drive format=raw,file=disk.img

Requer NASM, QEMU e coreutils. O `build.sh` monta os três componentes, valida o
tamanho de cada um e gera a imagem de disco bootável.

## Funcionamento

A BIOS carrega o setor 0 em `0x7C00`; o bootloader configura segmentos e pilha e
lê kernel e editor do disco (`int 0x13`). O kernel, em `0x1000`, oferece prompt
para abrir o editor, listar e apagar arquivos e reiniciar. O editor, em `0x2000`,
edita um buffer com suporte a backspace e quebra de linha e o grava em setores
fixos. Vídeo, disco, teclado e reboot via `int 0x10/0x13/0x16/0x19`.

| Setores | Conteúdo | Endereço de carga |
|---|---|---|
| 0 | bootloader (512 B) | `0x7C00` |
| 3–6 | kernel (2 KB) | `0x1000` |
| 7–9 | editor (1,5 KB) | `0x2000` |
| 10+ | arquivos do usuário (512 B cada) | buffer em `0x3000` |

## Notas

- Não há sistema de arquivos: cada arquivo é um setor cru de 512 B em posição
  fixa — FAT12 seria o próximo passo natural.
- Tudo roda em modo real sobre serviços de BIOS; não há IDT própria nem modo
  protegido.

## Estrutura

    bootloader.asm   MBR: carga do kernel e do editor
    kernel.asm       prompt e comandos
    editor.asm       editor de texto com gravação em disco
    build.sh         montagem, validação de tamanhos e imagem final

## Autores

Alisson Jaime Sales Barros, Danilo Bezerra Vieira, Francisco Vinicius Castro
Silveira, José Ferreira Lessa, Matheus Rocha Gomes da Silva, Nataniel Marques
Viana Neto e Thiago Siqueira de Sousa. Orientação: Prof. Nícolas de Araújo
Moreira.
