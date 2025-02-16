#!/bin/bash
set -e

# Compilar
nasm -f bin -o bootloader.bin bootloader.asm
nasm -f bin -o kernel.bin kernel.asm
nasm -f bin -o editor.bin editor.asm

# Verificar tamanhos
check_size() {
    file=$1
    max=$2
    size=$(stat -c%s "$file")
    if [ $size -gt $max ]; then
        echo "ERRO: $file excede $max bytes!"
        exit 1
    fi
}

check_size bootloader.bin 512
check_size kernel.bin 2048    # 4 setores
check_size editor.bin 1024    # 2 setores

# Criar disco
dd if=/dev/zero of=disk.img bs=512 count=1000
dd if=bootloader.bin of=disk.img conv=notrunc
dd if=kernel.bin of=disk.img seek=2 conv=notrunc
dd if=editor.bin of=disk.img seek=6 conv=notrunc

echo "✅ Build completo! Execute com:"
echo "qemu-system-x86_64 -drive format=raw,file=disk.img"
