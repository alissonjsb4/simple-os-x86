#!/bin/bash
set -e

nasm -f bin -o bootloader.bin bootloader.asm
nasm -f bin -o kernel.bin kernel.asm
nasm -f bin -o editor.bin editor.asm

dd if=/dev/zero of=disk.img bs=512 count=1440
dd if=bootloader.bin of=disk.img conv=notrunc
dd if=kernel.bin of=disk.img bs=512 seek=2 conv=notrunc
dd if=editor.bin of=disk.img bs=512 seek=6 conv=notrunc

echo "✅ Build completo! Execute com:"
echo "qemu-system-x86_64 -drive format=raw,file=disk.img"
