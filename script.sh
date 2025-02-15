#!/bin/bash
set -e

nasm -f bin -o bootloader.bin bootloader.asm
nasm -f bin -o kernel.bin kernel.asm
nasm -f bin -o editor.bin editor.asm

check_size() {
    size=$(stat -c%s "$1")
    if [ $size -gt 512 ]; then
        echo "ERRO: $1 excede 512 bytes!"
        exit 1
    fi
}

check_size bootloader.bin
check_size kernel.bin  # Permite até 2KB (4 setores)
check_size editor.bin

dd if=/dev/zero of=disk.img bs=512 count=1000
dd if=bootloader.bin of=disk.img conv=notrunc
dd if=kernel.bin of=disk.img seek=2 conv=notrunc
dd if=editor.bin of=disk.img seek=6 conv=notrunc

echo "Build completo! Execute com:"
echo "qemu-system-x86_64 -drive format=raw,file=disk.img"
