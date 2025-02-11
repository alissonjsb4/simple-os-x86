# Simple_OS

A basic operating system with a bootloader, microkernel, and a simple text editor. Developed in Assembly and C for educational purposes.

## Overview

This is a basic operating system project developed for educational purposes. It includes:
- **Bootloader**: Loads the kernel into memory and transfers control to it.
- **Microkernel**: Provides a basic command-line interface (CLI) with simple commands.
- **Text Editor**: A simple application that can be loaded by the kernel.
- **File System**: Uses contiguous allocation to load programs from disk.

## Features

- Basic boot process implementation
- Kernel with CLI for executing commands
- Simple text editor functionality
- Support for loading programs from disk

## Requirements

To build and run this OS, you will need:
- **NASM** (to compile Assembly code)
- **QEMU** (to emulate the system)
- **GCC** (to compile C code)
- **Bash** (to run the build script)

## Languages Used

- **Assembly**: Used for the bootloader and kernel.
- **C**: Used for the text editor.

## How to Run

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/my-os.git
   ```

2. Navigate to the project directory:
   ```bash
   cd my-os
   ```

3. Run the build and execution script:
   ```bash
   ./script.sh
   ```

4. The system will run in QEMU.

## Building the Project

### Compile the Bootloader
```bash
nasm -f bin -o bootloader.bin bootloader.asm
```

### Compile the Kernel
```bash
nasm -f bin -o kernel.bin kernel.asm
```

### Compile the Text Editor
```bash
i686-elf-gcc -ffreestanding -c editor.c -o editor.o
ld -Ttext 0x2000 --oformat binary editor.o -o editor.bin
```

### Create the Disk Image and Run the System
```bash
./script.sh
```

## How It Works

1. **Bootloader Execution:**
   - Loads the kernel into memory at address `0x1000`.
   - Loads the text editor at address `0x2000`.

2. **Kernel Functionality:**
   - Provides a basic CLI with commands.
   - Supports rebooting the system.
   - Allows loading and executing programs.

3. **Text Editor Execution:**
   - Can be launched by typing `e` in the CLI.
   - Allows users to type and edit text.
   - Simulated save functionality with `Ctrl+S`.

## License

This project is licensed under the MIT License. See `LICENSE` for details.

