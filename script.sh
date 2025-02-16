#!/bin/bash
set -e

# Compilar cada ASM
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

check_size bootloader.bin 512     # 1 setor
check_size kernel.bin 2048        # 4 setores
check_size editor.bin 1024        # 2 setores

# Criar disco de 1000 setores (512 bytes cada)
dd if=/dev/zero of=disk.img bs=512 count=1000

# Gravar o bootloader no setor 0
dd if=bootloader.bin of=disk.img conv=notrunc

# Gravar o kernel a partir do setor 2 (setores 2,3,4,5)
dd if=kernel.bin of=disk.img seek=2 conv=notrunc

# Gravar o editor a partir do setor 6 (setores 6,7)
dd if=editor.bin of=disk.img seek=6 conv=notrunc

echo "✅ Build completo! Execute com:"
echo "qemu-system-x86_64 -drive format=raw,file=disk.img"
