# simple-os-x86

A 16-bit operating system for x86 in real mode, written in Assembly: a 512-byte MBR bootloader, a kernel with a command prompt, and a text editor that saves to disk. Course project for Microprocessors at the Federal University of Ceará (UFC), team of seven.

## Usage

    ./build.sh
    qemu-system-x86_64 -drive format=raw,file=disk.img

Needs NASM, QEMU and coreutils. `build.sh` assembles the three parts, checks that each one fits its sectors and writes the bootable disk image.

## How it works

The BIOS loads sector 0 at `0x7C00`; the bootloader sets up segments and stack and reads the kernel and the editor from disk with `int 0x13`. The kernel, at `0x1000`, offers a prompt to open the editor, list and delete files, and reboot. The editor, at `0x2000`, edits a buffer with backspace and line breaks and writes it to fixed sectors. Video, disk, keyboard and reboot go through `int 0x10`, `0x13`, `0x16` and `0x19`.

| Sectors | Contents | Load address |
|---|---|---|
| 0 | bootloader (512 B) | `0x7C00` |
| 3-6 | kernel (2 KB) | `0x1000` |
| 7-9 | editor (1.5 KB) | `0x2000` |
| 10+ | user files (512 B each) | buffer at `0x3000` |

## Notes

- There is no file system: each file is a raw 512-byte sector at a fixed position. FAT12 would be the natural next step.
- Everything runs in real mode on BIOS services, with no IDT of its own and no protected mode.

## Layout

    bootloader.asm   MBR: loads the kernel and the editor
    kernel.asm       prompt and commands
    editor.asm       text editor with disk writes
    build.sh         assembly, size checks and final image

## Authors

Alisson Jaime Sales Barros, Danilo Bezerra Vieira, Francisco Vinicius Castro Silveira, José Ferreira Lessa, Matheus Rocha Gomes da Silva, Nataniel Marques Viana Neto and Thiago Siqueira de Sousa. Supervised by Prof. Nícolas de Araújo Moreira.
