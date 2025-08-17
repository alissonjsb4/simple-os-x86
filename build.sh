#!/bin/bash

# ======================================================================================
# Simple OS - Build Script
#
# Author: Alisson Jaime Sales Barros
# Course: Microprocessors - Federal University of Ceará (UFC)
#
# Description:
# This script automates the entire build process for the Simple OS. It:
# 1. Compiles the bootloader, kernel, and editor from Assembly (.asm) to binary (.bin).
# 2. Validates that the compiled binaries do not exceed their allocated sector sizes.
# 3. Creates a raw disk image file.
# 4. Writes the binaries to their correct positions on the disk image.
# 5. Prints the command to run the OS in the QEMU emulator.
#
# ======================================================================================

# Exit immediately if any command fails
set -e

# --- 1. Compilation ---
# Use NASM (Netwide Assembler) to compile the 16-bit real mode code.
echo "Compiler..."
nasm -f bin -o bootloader.bin bootloader.asm
nasm -f bin -o kernel.bin kernel.asm
nasm -f bin -o editor.bin editor.asm
echo "Compilation complete."
echo ""

# --- 2. Size Validation ---
# Ensure that the compiled binaries will fit into their allocated disk sectors.
echo "Validating binary sizes..."

# Helper function to check file size
check_size() {
    local file="$1"
    local max_size="$2"
    local actual_size=$(stat -c%s "$file")

    echo "Size of $file: $actual_size bytes (Max: $max_size bytes)"

    if [ $actual_size -gt $max_size ]; then
        echo "ERROR: $file exceeds the maximum allowed size of $max_size bytes!"
        exit 1
    fi
}

# The bootloader must fit into a single 512-byte sector.
check_size bootloader.bin 512

# The kernel is allocated 4 sectors (4 * 512 = 2048 bytes).
check_size kernel.bin 2048

# The editor is allocated 3 sectors (3 * 512 = 1536 bytes).
check_size editor.bin 1536
echo "Size validation passed."
echo ""

# --- 3. Disk Image Creation ---
# Create a 100-sector (51200 bytes) raw disk image file filled with zeros.
echo "Creating disk image 'disk.img'..."
dd if=/dev/zero of=disk.img bs=512 count=100

# Write the binaries to the disk image at their correct sector locations.
# `conv=notrunc` prevents `dd` from truncating the output file.

# The bootloader goes into the first sector (Sector 0).
echo "Writing bootloader to Sector 0..."
dd if=bootloader.bin of=disk.img conv=notrunc

# The kernel is written starting at Sector 2 (the 3rd sector).
# `seek=2` skips the first two sectors (0 and 1).
echo "Writing kernel to Sector 2..."
dd if=kernel.bin of=disk.img seek=2 conv=notrunc

# The editor is written starting at Sector 6 (the 7th sector).
# `seek=6` skips the first six sectors.
echo "Writing editor to Sector 6..."
dd if=editor.bin of=disk.img seek=6 conv=notrunc
echo ""

# --- 4. Final Instructions ---
echo "✅ Build complete! You can now run the OS with the following command:"
echo "qemu-system-x86_64 -drive format=raw,file=disk.img"

