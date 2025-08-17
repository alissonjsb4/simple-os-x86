; ======================================================================================
; Simple OS - 16-bit Kernel
;
; Author: Alisson Jaime Sales Barros
; Course: Microprocessors - Federal University of Ceará (UFC)
;
; Description:
; This is the main kernel for the Simple OS. It provides a basic command-line
; interface (CLI) after being loaded by the bootloader. It handles user input
; to launch the text editor, view saved files, delete files, or reboot the system.
;
; ======================================================================================

[BITS 16]
[ORG 0x1000]   ; The kernel is loaded by the bootloader to this memory address

; --- Constants Definition ---
%define EDITOR_ADDR             0x2000  ; Memory address of the editor
%define TEMP_BUFFER_ADDR        0x3000  ; Temporary memory address for disk I/O
%define FILE_COUNTER_SECTOR     9       ; Disk sector where the file counter is stored
%define FILE_START_SECTOR       10      ; The first sector reserved for user files
%define BOOT_DRIVE              0x80    ; Drive number for the primary hard disk

; ======================================================================================
; Main Program Execution
; ======================================================================================
start:
    ; Initialize segment registers and stack
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    call clear_screen_routine
    mov dx, 0 ; Set cursor to (0,0)
    call set_cursor_routine

    mov si, kernel_welcome_msg
    call print_string_routine

; --- Main Command Loop ---
main_loop:
    mov si, prompt_msg
    call print_string_routine

    call wait_for_key_routine ; Wait for user input

    ; Dispatch command based on user input
    cmp al, 'e'
    je launch_editor
    cmp al, 'r'
    je handle_reboot
    cmp al, 'v'
    je handle_view_files
    cmp al, 'd'
    je handle_delete_files

    ; Handle invalid command
    mov si, invalid_cmd_msg
    call print_string_routine
    jmp main_loop

; ======================================================================================
; Command Handlers
; ======================================================================================

; --- Launch Editor ('e') ---
launch_editor:
    mov si, loading_editor_msg
    call print_string_routine
    jmp 0x0000:EDITOR_ADDR   ; Far jump to the editor's code

; --- Reboot System ('r') ---
handle_reboot:
    int 0x19                 ; BIOS interrupt to reboot the system

; --- View Saved Files ('v') ---
handle_view_files:
    call clear_screen_routine
    mov dx, 0
    call set_cursor_routine
    
    call list_files_routine  ; Reusable routine to list all saved files
    
    mov si, view_prompt_msg
    call print_string_routine
    call read_two_digits_routine ; Get file number from user

    cmp bl, 0
    je .return_to_main ; User entered '00' to return

    ; Validate user input
    mov al, [file_count]
    cmp bl, al
    ja .invalid_file
    cmp bl, 1
    jb .invalid_file

    ; Display the selected file content
    call clear_screen_routine
    mov dx, 0
    call set_cursor_routine
    mov si, reading_file_msg
    call print_string_routine
    mov ax, bx
    call print_two_digit_routine
    mov si, reading_file_msg2
    call print_string_routine
    
    mov cl, FILE_START_SECTOR - 1
    add cl, bl ; Calculate sector number to read
    mov bx, TEMP_BUFFER_ADDR
    call read_sector_routine
    
    ; Print the content of the sector
    mov si, TEMP_BUFFER_ADDR
    call print_string_routine ; Assumes text is null-terminated
    
    call wait_for_key_routine
    
.return_to_main:
    call clear_screen_routine
    mov dx, 0
    call set_cursor_routine
    mov si, kernel_welcome_msg
    call print_string_routine
    jmp main_loop

.invalid_file:
    mov si, invalid_file_msg
    call print_string_routine
    call wait_for_key_routine
    jmp handle_view_files

; --- Delete Saved Files ('d') ---
handle_delete_files:
    ; (Implementation for file deletion would go here)
    ; For now, just print a message and return.
    mov si, not_implemented_msg
    call print_string_routine
    jmp main_loop

; ======================================================================================
; Subroutines
; ======================================================================================

; Lists all saved files with a preview of their content.
list_files_routine:
    ; 1. Read the file counter from its dedicated sector
    mov cl, FILE_COUNTER_SECTOR
    mov bx, TEMP_BUFFER_ADDR
    call read_sector_routine
    mov al, [TEMP_BUFFER_ADDR]
    mov [file_count], al

    ; 2. Print header
    mov si, file_list_header_msg
    call print_string_routine
    
    ; 3. Loop through each file sector and print a preview
    movzx cx, byte [file_count] ; CX = number of files
    cmp cx, 0
    je .no_files
    
    mov di, 1 ; File index for display (1-based)
.list_loop:
    ; Print file number, e.g., "[01] "
    push cx
    mov si, open_bracket_msg
    call print_string_routine
    mov ax, di
    call print_two_digit_routine
    mov si, close_bracket_msg
    call print_string_routine
    
    ; Read the file sector
    mov cl, FILE_START_SECTOR - 1
    add cl, di
    mov bx, TEMP_BUFFER_ADDR
    call read_sector_routine
    
    ; Print the first few characters as a preview
    mov si, TEMP_BUFFER_ADDR
    mov cx, 40 ; Print up to 40 characters
.preview_loop:
    lodsb
    test al, al
    jz .end_of_string
    cmp al, 13 ; Don't print newline characters
    je .next_char
    call print_char_routine
.next_char:
    loop .preview_loop
.end_of_string:
    
    mov si, newline_msg
    call print_string_routine
    
    inc di
    pop cx
    loop .list_loop

.no_files:
    ret

; Reads a two-digit number from the keyboard.
; Output: BL = converted number
read_two_digits_routine:
    ; Read tens digit
    call wait_for_key_routine
    call print_char_routine
    sub al, '0'
    mov bl, 10
    mul bl
    mov bl, al

    ; Read units digit
    call wait_for_key_routine
    call print_char_routine
    sub al, '0'
    add bl, al
    ret

; Prints a two-digit number (00-99).
; Input: AX = number to print
print_two_digit_routine:
    pusha
    mov cl, 10
    xor dx, dx
    div cl
    add ax, '00'
    mov bh, ah
    mov al, ah
    mov ah, 0x0E
    int 0x10
    mov al, bh
    int 0x10
    popa
    ret

; Reads one sector from disk.
; Input: CL = sector number, BX = buffer address
read_sector_routine:
    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov dh, 0
    mov dl, BOOT_DRIVE
    int 0x13
    jc disk_error_handler
    ret

; General purpose subroutines (clear_screen, set_cursor, etc.)
clear_screen_routine:
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10
    ret

set_cursor_routine:
    mov ah, 0x02
    xor bh, bh
    int 0x10
    ret

print_string_routine:
    mov ah, 0x0E
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    ret

wait_for_key_routine:
    mov ah, 0x00
    int 0x16
    ret
    
print_char_routine:
    mov ah, 0x0E
    int 0x10
    ret

disk_error_handler:
    mov si, disk_error_msg
    call print_string_routine
    jmp main_loop

; ======================================================================================
; Data and BSS (Uninitialized Data) Section
; ======================================================================================
kernel_welcome_msg:
    db "======== Simple OS Kernel ========", 13, 10
    db "Available Commands:", 13, 10
    db " e - Text Editor", 13, 10
    db " v - View Saved Files", 13, 10
    db " d - Delete a File", 13, 10
    db " r - Reboot System", 13, 10
    db "-------------------------------", 13, 10, 0

prompt_msg:             db 13, 10, "CMD> ", 0
loading_editor_msg:     db "Loading editor...", 13, 10, 0
invalid_cmd_msg:        db " Invalid command!", 13, 10, 0
disk_error_msg:         db " Disk read error!", 13, 10, 0
file_list_header_msg:   db "Saved Files:", 13, 10, 0
view_prompt_msg:        db 13, 10, "Enter file number to view (00 to cancel): ", 0
reading_file_msg:       db "--- Content of File #", 0
reading_file_msg2:      db " --- (Press any key to return)", 13, 10, 0
invalid_file_msg:       db " Invalid file number.", 13, 10, 0
not_implemented_msg:    db " This feature is not yet implemented.", 13, 10, 0
open_bracket_msg:       db "[", 0
close_bracket_msg:      db "] ", 0
newline_msg:            db 13, 10, 0

file_count:             db 0
