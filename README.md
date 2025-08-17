# Simple OS - A 16-bit x86 Operating System in Assembly

A comprehensive academic project for the Microprocessors course at the Federal University of Ceará (UFC), developed by the student team listed below. This repository contains the source code for Simple OS, a basic 16-bit operating system for the x86 architecture, written entirely in Assembly.

The system features a custom MBR bootloader, a command-line kernel, and a simple text editor application with file-saving capabilities, demonstrating fundamental OS concepts and low-level hardware interaction via BIOS interrupts.

## Key Features

- **MBR Bootloader:** A 512-byte bootloader that initializes the system, loads the kernel and editor from disk, and transfers execution control.
- **Interactive Kernel:** A simple command-line interface (CLI) that allows the user to launch applications, view/delete files, and reboot the system.
- **Text Editor Application:** A basic text editor with features for typing, backspace, newlines, and saving text to the disk in separate sectors.
- **Automated Build System:** Includes a shell script (`build.sh`) that assembles the components, validates their sizes, and creates a bootable disk image.

## System Architecture & Boot Process

The OS follows a traditional boot sequence for x86 systems operating in 16-bit real mode:

1.  **BIOS:** On power-on, the BIOS searches for a bootable device, reads the first 512-byte sector (the Master Boot Record), and loads it into memory at address `0x7C00`.
2.  **Bootloader:** The bootloader code takes control. It sets up segment registers and the stack, then uses BIOS interrupts to load the kernel and editor from subsequent disk sectors into their designated memory locations.
3.  **Kernel:** The bootloader performs a far jump to the kernel's entry point (`0x1000`). The kernel initializes, displays a welcome message and a command prompt, and enters its main loop to await user commands.
4.  **Applications:** Based on user input, the kernel can jump to other programs loaded in memory, such as the text editor at `0x2000`.

## Technical Details

- **Operating Mode:** 16-bit Real Mode.
- **BIOS Interrupts Used:**
  - `int 0x10`: Video Services (printing characters, clearing the screen, setting cursor position).
  - `int 0x13`: Disk Services (reading and writing sectors).
  - `int 0x16`: Keyboard Services (getting keystrokes).
  - `int 0x19`: System Services (rebooting the computer).
- **Disk Layout:** The system uses a simple, fixed layout on the disk image for storing its components and user files.

| Sector(s) | Content        | Size        | Load Address |
|:----------|:---------------|:------------|:-------------|
| 0         | Bootloader     | 512 Bytes   | `0x7C00`     |
| 1-2       | *Reserved* | -           | -            |
| 3-6       | Kernel         | 2 KB        | `0x1000`     |
| 7-9       | Editor         | 1.5 KB      | `0x2000`     |
| 10+       | User Files     | 512 B/file  | `0x3000` (buffer) |

## How to Build and Run

### Prerequisites
You will need the following tools installed on a Linux-based system (or using a compatibility layer like MSYS2 on Windows):
- **NASM (Netwide Assembler)**
- **QEMU (System Emulator)**
- **Coreutils (for `dd` and `stat`)**

### 1. Build the Disk Image
Navigate to the project's root directory in your terminal and execute the build script:
```bash
chmod +x build.sh
./build.sh
```
This script will automatically compile all components, validate their sizes, and generate a `disk.img` file ready for emulation.

### 2. Run the Operating System
Use the following command to launch the OS in the QEMU emulator:
```bash
qemu-system-x86_64 -drive format=raw,file=disk.img
```

## Future Work & Roadmap

This project serves as a solid foundation for a more feature-rich operating system. Potential future enhancements include:

- [ ] **File System:** Implement a simple file system (like FAT12) to manage files with names and directories instead of raw sectors.
- [ ] **Memory Management:** Develop a basic memory manager to allocate and free memory for programs.
- [ ] **Interrupt Handling:** Create an Interrupt Descriptor Table (IDT) and write custom interrupt handlers to move away from relying on BIOS services.
- [ ] **User vs. Kernel Mode:** Implement protected mode to create a separation between kernel space and user space.
- [ ] **Multitasking:** Add a simple scheduler to handle cooperative or preemptive multitasking.

## Authors

This project was developed as a collaborative effort by the following students under the guidance of Professor Nícolas de Araújo Moreira:

- **Alisson Jaime Sales Barros**
- **Danilo Bezerra Vieira**
- **Francisco Vinicius Castro Silveira**
- **José Ferreira Lessa**
- **Matheus Rocha Gomes da Silva**
- **Nataniel Marques Viana Neto**
- **Thiago Siqueira de Sousa**
