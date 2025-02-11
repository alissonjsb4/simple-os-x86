#!/bin/bash
set -x  # Habilitar modo de debug

# Compilar o bootloader
nasm -f bin -o bootloader.bin bootloader.asm

# Compilar o kernel
nasm -f bin -o kernel.bin kernel.asm

# Compilar o editor (C)
i686-elf-gcc -ffreestanding -c editor.c -o editor.o
ld -Ttext 0x2000 --oformat binary editor.o -o editor.bin

# Criar a imagem de disco
dd if=/dev/zero of=disk.img bs=1M count=5

# Copiar o bootloader para o setor de inicialização
dd if=bootloader.bin of=disk.img bs=512 count=1 conv=notrunc

# Copiar o kernel para o setor 2
dd if=kernel.bin of=disk.img bs=512 seek=2 conv=notrunc

# Copiar o editor para o setor 6
dd if=editor.bin of=disk.img bs=512 seek=6 conv=notrunc

# Executar no QEMU
qemu-system-x86_64 -drive format=raw,file=disk.img
