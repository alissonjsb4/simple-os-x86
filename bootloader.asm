; ======================================================================================
; Simple OS - 16-bit MBR Bootloader
;
; Author: Alisson Jaime Sales Barros
; Course: Microprocessors - Federal University of Ceará (UFC)
;
; Description:
; This is a 512-byte Master Boot Record (MBR) bootloader. Its primary jobs are:
; 1. Set up the CPU's segment registers and stack in 16-bit real mode.
; 2. Use BIOS interrupts to load the Kernel and Editor from the disk into memory.
; 3. Transfer execution control to the Kernel.
;
; ======================================================================================

[BITS 16]      ; Tell the assembler we are in 16-bit real mode
[ORG 0x7C00]   ; The BIOS loads the MBR to this memory address

; --- Constants Definition ---
KERNEL_LOAD_ADDR    EQU 0x1000  ; Memory address to load the kernel
EDITOR_LOAD_ADDR    EQU 0x2000  ; Memory address to load the editor
BOOT_DRIVE          EQU 0x80    ; Drive number for the primary hard disk

; --- Start of Execution ---
start:
    ; 1. Initial CPU Setup
    cli             ; Disable interrupts during setup
    cld             ; Clear direction flag (for string operations)
    xor ax, ax      ; Clear AX register (AX=0)

    ; Set up segment registers to a known state (0x0000)
    mov ds, ax
    mov es, ax
    mov ss, ax
    
    ; Set up the stack pointer to grow downwards from our code's origin
    mov sp, 0x7C00
    sti             ; Re-enable interrupts now that setup is complete

    ; 2. Print Bootloader Welcome Message
    mov si, msg_boot_ok
    call print_string_routine

    ; 3. Load Kernel from Disk
    ;    Loads 4 sectors starting from sector 3 into memory at KERNEL_LOAD_ADDR
load_kernel:
    mov bx, KERNEL_LOAD_ADDR    ; Set destination memory address
    mov ah, 0x02                ; BIOS Function: Read Sectors
    mov al, 4                   ; Number of sectors to read
    mov ch, 0                   ; Cylinder index
    mov cl, 3                   ; Starting sector number
    mov dh, 0                   ; Head index
    mov dl, BOOT_DRIVE          ; Drive to read from
    int 0x13                    ; Call BIOS disk services interrupt

    jc disk_error               ; If Carry Flag is set, a disk error occurred
    cmp al, 4                   ; Compare sectors read with sectors requested
    jne disk_error              ; If not equal, an error occurred

    mov si, msg_kernel_ok
    call print_string_routine

    ; 4. Load Editor from Disk
    ;    Loads 3 sectors starting from sector 7 into memory at EDITOR_LOAD_ADDR
load_editor:
    mov bx, EDITOR_LOAD_ADDR    ; Set destination memory address
    mov ah, 0x02                ; BIOS Function: Read Sectors
    mov al, 3                   ; Number of sectors to read
    mov cl, 7                   ; Starting sector number
    int 0x13                    ; Call BIOS disk services interrupt
    
    jc disk_error
    cmp al, 3
    jne disk_error

    mov si, msg_editor_ok
    call print_string_routine

    ; 5. Wait for user input before jumping to the kernel
    mov si, msg_press_key
    call print_string_routine
    call wait_for_key_routine

    ; 6. Transfer control to the Kernel
    jmp 0x0000:KERNEL_LOAD_ADDR ; Far jump to the kernel's code segment and address

; --- Error Handling Routine ---
disk_error:
    mov si, msg_disk_error
    call print_string_routine
    
    ; Wait for a keypress before rebooting
    mov ah, 0x00
    int 0x16
    
    ; Reboot the system
    int 0x19

; ======================================================================================
; Subroutines
; ======================================================================================

; Prints a null-terminated string to the screen.
; Input: SI = Address of the string
print_string_routine:
    mov ah, 0x0E        ; BIOS Function: Teletype Output
.loop:
    lodsb               ; Load byte from [DS:SI] into AL, and increment SI
    test al, al         ; Check if the byte is zero (null terminator)
    jz .done            ; If zero, we are done
    int 0x10            ; Call BIOS video services interrupt to print character
    jmp .loop
.done:
    ret

; Waits for a single keypress.
wait_for_key_routine:
    mov ah, 0x00        ; BIOS Function: Get Keystroke
    int 0x16            ; Call BIOS keyboard services interrupt
    ret

; ======================================================================================
; Data Section
; ======================================================================================
msg_boot_ok     db "[OK] Bootloader initialized successfully.", 13, 10, 0
msg_kernel_ok   db "[OK] Kernel loaded into memory.", 13, 10, 0
msg_editor_ok   db "[OK] Editor loaded into memory.", 13, 10, 0
msg_disk_error  db "[ERROR] Disk read failure. Rebooting...", 0
msg_press_key   db "Press any key to boot the kernel...", 13, 10, 0

; ======================================================================================
; MBR Signature
; ======================================================================================
times 510-($-$$) db 0   ; Pad the rest of the 512-byte sector with zeros
dw 0xAA55               ; The mandatory MBR boot signature
