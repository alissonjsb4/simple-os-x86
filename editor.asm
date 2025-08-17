; ======================================================================================
; Simple OS - 16-bit Text Editor
;
; Author: Alisson Jaime Sales Barros
; Course: Microprocessors - Federal University of Ceará (UFC)
;
; Description:
; A simple text editor application for the Simple OS. Features include:
; - Basic text input, backspace, and newline handling.
; - A persistent file saving mechanism (Ctrl+S) that appends new text to a file
;   on disk, using a simple file counter stored in a dedicated sector.
; - An exit function (Esc) to return to the kernel.
;
; ======================================================================================

[BITS 16]
[ORG 0x2000]   ; The editor is loaded by the bootloader to this memory address

; --- Constants Definition ---
%define KERNEL_ADDR             0x1000  ; Kernel's memory address to jump back to
%define FILE_COUNTER_SECTOR     0x09    ; Disk sector used to store the file counter
%define FILE_START_SECTOR       0x0A    ; The first sector reserved for user files (sector 10)
%define TEMP_BUFFER_ADDR        0x3000  ; Temporary memory address for disk read/write operations
%define BUFFER_SIZE             512     ; Size of the text input buffer

; ======================================================================================
; Main Program Execution
; ======================================================================================
start:
    ; Initialize segment registers
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; Load the file counter from its dedicated disk sector
    call load_file_counter_routine

    call clear_screen_routine

    ; Position cursor at (0,0) for the header
    mov dx, 0
    call set_cursor_routine

    ; Print the editor header and instructions
    mov si, header_msg
    call print_string_routine

    ; Position cursor at the start of the editing area (Line 5, Column 0)
    mov dh, 5
    mov dl, 0
    call set_cursor_routine

    ; Initialize the text buffer index to zero
    mov word [buffer_index], 0

; --- Main Event Loop ---
; Waits for a keypress and dispatches to the appropriate handler.
edit_loop:
    call wait_for_key_routine

    ; Dispatch based on key pressed
    cmp al, 0x1B        ; ESC key -> Exit
    je handle_exit
    cmp al, 0x08        ; Backspace key -> Handle backspace
    je handle_backspace
    cmp al, 0x0D        ; Enter key -> Handle newline
    je handle_newline
    cmp al, 0x13        ; Ctrl+S -> Save file
    je handle_save

    ; --- Default Character Handling ---
    ; If it's a printable character, store it in the buffer and display it.
    mov bx, [buffer_index]
    cmp bx, BUFFER_SIZE
    jae .skip_char_store ; If buffer is full, do not store character

    ; Store character in buffer
    mov di, bx
    mov [buffer + di], al
    inc bx
    mov [buffer_index], bx

.skip_char_store:
    ; Print character and update cursor position
    call print_char_routine
    inc dl
    cmp dl, 80          ; Check for end of line
    jne .update_cursor
    xor dl, dl          ; Reset column to 0
    inc dh
    cmp dh, 25          ; Check for end of screen
    jb .update_cursor
    dec dh              ; Prevent cursor from going off-screen
.update_cursor:
    call set_cursor_routine
    jmp edit_loop

; ======================================================================================
; Input Handlers
; ======================================================================================

; --- Backspace Handler ---
handle_backspace:
    mov bx, [buffer_index]
    cmp bx, 0
    je edit_loop        ; If buffer is empty, do nothing

    dec bx
    mov [buffer_index], bx

    cmp dl, 0
    jne .move_cursor_left ; If not at the first column, just move left
    
    ; If at first column, move to the end of the previous line (if not on the first editing line)
    cmp dh, 5
    jle edit_loop       ; Do not go above the editing area
    dec dh
    mov dl, 79

.move_cursor_left:
    dec dl
    call set_cursor_routine
    
    ; Erase character on screen by printing a space
    mov al, ' '
    call print_char_routine
    call set_cursor_routine ; Move cursor back one more time
    jmp edit_loop

; --- Newline (Enter) Handler ---
handle_newline:
    ; Store Carriage Return (13) and Line Feed (10) in the buffer
    mov bx, [buffer_index]
    cmp bx, BUFFER_SIZE - 2 ; Ensure there is space for two characters
    jae .skip_newline_store

    mov di, bx
    mov byte [buffer + di], 13
    inc bx
    mov di, bx
    mov byte [buffer + di], 10
    inc bx
    mov [buffer_index], bx

.skip_newline_store:
    ; Move cursor to the beginning of the next line
    inc dh
    cmp dh, 25
    jb .update_newline_cursor
    dec dh ; Prevent cursor from going off-screen
.update_newline_cursor:
    xor dl, dl
    call set_cursor_routine
    jmp edit_loop

; --- Save File (Ctrl+S) Handler ---
save_file:
    ; This routine appends the new text from the editor buffer to a file on disk.
    ; Each save operation creates a new "file" by writing to the next available sector.

    ; 1. Clear the temporary buffer in memory
    call clear_temp_buffer_routine

    ; 2. Copy the new text from the editor's buffer to the temporary buffer
    mov di, TEMP_BUFFER_ADDR
    mov bx, [buffer_index]  ; Get size of the new text
    mov si, buffer
.copy_loop:
    cmp bx, 0
    je .done_copy
    cmp di, TEMP_BUFFER_ADDR + 510 ; Leave space for potential newline
    jae .done_copy
    lodsb
    mov [di], al
    inc di
    dec bx
    jmp .copy_loop

.done_copy:
    ; 3. Ensure the text ends with a newline (CR+LF)
    cmp di, TEMP_BUFFER_ADDR
    je .append_done     ; If nothing was copied, skip
    mov al, [di-1]
    cmp al, 10          ; Check if last character is Line Feed
    je .append_done
    mov byte [di], 13   ; Add Carriage Return
    inc di
    mov byte [di], 10   ; Add Line Feed
    inc di
.append_done:
    mov byte [di], 0    ; Null-terminate the string in the buffer

    ; 4. Write the temporary buffer to the next available disk sector
    mov ah, 0x03        ; BIOS Function: Write Sectors
    mov al, 1           ; Number of sectors to write
    mov ch, 0           ; Cylinder
    mov cl, FILE_START_SECTOR
    add cl, [file_counter] ; Target sector = 10 + file_counter
    mov dh, 0           ; Head
    mov dl, BOOT_DRIVE
    mov bx, TEMP_BUFFER_ADDR
    int 0x13
    jc .save_error

    ; 5. Increment the file counter
    inc byte [file_counter]

    ; 6. Save the updated file counter back to its dedicated sector (sector 9)
    mov ah, 0x03        ; BIOS Function: Write Sectors
    mov al, 1           ; Number of sectors to write
    mov ch, 0
    mov cl, FILE_COUNTER_SECTOR
    mov dh, 0
    mov dl, BOOT_DRIVE
    mov bx, TEMP_BUFFER_ADDR
    mov al, [file_counter]
    mov [TEMP_BUFFER_ADDR], al ; Place the counter value at the start of the buffer
    int 0x13
    jc .save_error

    ; 7. Display success message and wait for keypress
    mov si, saved_msg
    call print_string_routine
    mov ax, [file_counter]
    and ax, 0x00FF
    call print_two_digit_routine
    mov si, newline_msg
    call print_string_routine
    call wait_for_key_routine
    jmp handle_exit

.save_error:
    mov si, error_msg
    call print_string_routine
    jmp edit_loop

; --- Exit Handler (ESC) ---
handle_exit:
    jmp 0x0000:KERNEL_ADDR ; Return control to the kernel

; ======================================================================================
; Subroutines
; ======================================================================================

; Prints a two-digit number (00-99).
; Input: AX = number to print
print_two_digit_routine:
    pusha
    mov cl, 10
    xor dx, dx
    div cl              ; AX / 10 -> Quotient in AL, Remainder in AH
    
    ; Print tens digit
    add al, '0'
    mov bh, ah          ; Save remainder
    mov ah, 0x0E
    int 0x10
    
    ; Print units digit
    mov al, bh
    add al, '0'
    mov ah, 0x0E
    int 0x10
    
    popa
    ret

; Clears the entire screen.
clear_screen_routine:
    mov ax, 0x0600      ; BIOS Function: Scroll Up, clear entire window
    mov bh, 0x07        ; Attribute: White on Black
    mov cx, 0x0000      ; Start at row 0, col 0
    mov dx, 0x184F      ; End at row 24, col 79
    int 0x10
    ret

; Prints a null-terminated string.
; Input: SI = Address of the string
print_string_routine:
    mov ah, 0x0E        ; BIOS Function: Teletype Output
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    ret

; Sets the cursor position.
; Input: DH = row, DL = column
set_cursor_routine:
    mov ah, 0x02        ; BIOS Function: Set Cursor Position
    xor bh, bh          ; Page number 0
    int 0x10
    ret

; Waits for a single keypress.
; Output: AL = ASCII code, AH = Scan code
wait_for_key_routine:
    mov ah, 0x00        ; BIOS Function: Get Keystroke
    int 0x16
    ret

; Prints a single character.
; Input: AL = character to print
print_char_routine:
    mov ah, 0x0E        ; BIOS Function: Teletype Output
    int 0x10
    ret

; Loads the file counter from its dedicated sector on disk.
load_file_counter_routine:
    mov ah, 0x02        ; BIOS Function: Read Sectors
    mov al, 1
    mov ch, 0
    mov cl, FILE_COUNTER_SECTOR
    mov dh, 0
    mov dl, BOOT_DRIVE
    mov bx, TEMP_BUFFER_ADDR
    int 0x13
    jc .init_counter    ; If read fails, initialize counter to 0

    mov al, [TEMP_BUFFER_ADDR] ; Counter is the first byte of the sector
    mov [file_counter], al
    ret
.init_counter:
    mov byte [file_counter], 0
    ret

; Clears the temporary buffer used for disk I/O.
clear_temp_buffer_routine:
    mov di, TEMP_BUFFER_ADDR
    mov cx, BUFFER_SIZE
    xor al, al
    rep stosb           ; Fast way to zero out a block of memory
    ret

; ======================================================================================
; Data and BSS (Uninitialized Data) Section
; ======================================================================================

; --- Initialized Data ---
header_msg:
    db "======== Simple OS Text Editor ========", 13, 10
    db " Ctrl+S: Save | Backspace: Erase ", 13, 10
    db " Enter: Newline | Esc: Exit to Kernel ", 13, 10
    db "--------------------------------------", 0

saved_msg:      db 13, 10, "[OK] Text saved successfully as file #", 0
error_msg:      db 13, 10, "[ERROR] Failed to save file!", 0
newline_msg:    db 13, 10, 0

; --- BSS Section ---
buffer:
    times BUFFER_SIZE db 0

buffer_index:
    dw 0

file_counter:
    db 0
