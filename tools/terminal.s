.include "terminal.inc"
.include "../os/shallow_thought.inc"
.include "../os/jump_table.inc"
.include "../os/strings.inc"
.include "../os/keyboard.inc"
.include "../os/screen.inc"
.include "../os/acia.inc"
.include "../os/zeropage.inc"
.include "../os/storage.inc"
.include "edit.inc"

.import xmodem_receive
.import dump_page
.import __PROGRAM_START__
.import __INPUTBFR_START__

terminal:       jsr     cr
                lda     current_drive
                adc     #48              ; to ascii
                jsr     JMP_PUTC
                putc    '#'
                putc    ' '
                stz     inputbuffer_ptr

                ldx     #80            ; inputbuffer size
@clear_buffer:  stz     <__INPUTBFR_START__,x
                dex
                bne     @clear_buffer
@next_key:      jsr     JMP_GETC
                cmp     #BS
                beq     @backspace
                cmp     #LF                
                beq     @enter

                jsr     JMP_PUTC
                cmp     #SPACE
                bne     @not_a_space
                lda     #0              ; save 0 instead of space into buffer, so it 
                                        ; matches the end of the command string
@not_a_space:   ldx     inputbuffer_ptr
                sta     <__INPUTBFR_START__,x
                inc     inputbuffer_ptr

                bra     @next_key
@enter:         lda     inputbuffer_ptr
                beq     terminal      ; do nothing if empty line

                jsr     find_command
                bra     terminal
@backspace:     lda     inputbuffer_ptr
                beq     @next_key        ; already at start of line

                putc    BS
                putc    ' '
                putc    BS

                dec     inputbuffer_ptr
                ldx     inputbuffer_ptr
                stz     <__INPUTBFR_START__,x

                bra     @next_key

; this loops over all the commands under the commands label
; each of those points to an entry in the list that contains the
; command string to match and the address of the routine to execute
find_command:   ldx     #0              ; index into list of commands
@loop:          lda     commands,x      ; load the address of the entry
                sta     tmp1            ; into tmp1 (16 bits)
                inx
                lda     commands,x
                sta     tmp1+1

                lda     (tmp1)          ; see if this is the last entry
                ora     (tmp1+1)        ; check two bytes for 0.
                beq     @unknown

                jsr     match_command
                bcc     @execute
                inx
                bra     @loop
@execute:       ; tmp1 now points to the command that holds the address
                ; to jump to. Store that address in command_vector so we
                ; can jump to it.
                lda     (tmp1), y
                sta     command_vector      
                iny
                lda     (tmp1), y
                sta     command_vector+1
                jsr     cr
                jmp     (command_vector)
                rts
@unknown:       println STR_UNKNOWN_CMD
                rts

; This looks at one command entry and matches it agains what's in the
; inputbuffer.
; Y:    index into the string to match
; tmp1: the starting address of the string
match_command:  ldy     #0              ; index into strings
@compare_char:  lda     <__INPUTBFR_START__,y
                cmp     (tmp1),y
                beq     @continue
                sec                     ; to message to the caller that the command didn't match
                rts
@continue:      lda     <__INPUTBFR_START__,y   ; is it the last character?
                beq     @matched
                iny
                jmp     @compare_char
@matched:       iny                     ; skip past the 0 at the end of the string
                sty     param_index
                clc                     ; to message to the caller that the command matched
                rts

;------------------------------------------------------
;               Command routines                      ;
;------------------------------------------------------
; The dump command. It dumps one page of memory. It takes a hex page number as parameter.
; Example: `dump a0` to dump page $a0.
dump:           clc
                lda     #<__INPUTBFR_START__
                adc     param_index     ; calculate the start of the param
                
                jsr     hex_to_byte     ; this puts the page number in A
                jsr     dump_page
                rts

; The rcv command. It waits for a keypress to give the user the opportunity to start
; the transmission on the transmitting computer. A key press sends the initial NAK
; and starts receiving. It uses xmodem_byte_sink_vector as a vector to a routine that
; receives each data byte in the A register.

rcv:            ; set the vector for what to do with each byte coming in through xmodem
                lda     #<save_to_ram
                sta     xmodem_byte_sink_vector
                lda     #>save_to_ram
                sta     xmodem_byte_sink_vector+1

                ; reset the pointer to start of the receive buffer
                lda     #<__PROGRAM_START__
                sta     rcv_buffer_pointer
                lda     #>__PROGRAM_START__
                sta     rcv_buffer_pointer+1

                ; prompt the user to press a key to start receiving
                println STR_RCV_WAIT

                ; The sender starts transmitting bytes as soon as
                ; it receives a NAK byte from the receiver. To be
                ; able to synchronize the two, the workflow is:
                ; 1. start sending command on sender
                ; 2. Press any key on the receiver to start the
                ;    transmission
                jsr     JMP_GETC

                print   STR_RCV_START
                lda     #>__PROGRAM_START__
                jsr     JMP_PRINT_HEX
                lda     #<__PROGRAM_START__
                jsr     JMP_PRINT_HEX
                jsr     cr

                jsr     JMP_XMODEM_RCV
                txa
                ina
                lsr                     ; packet count to page count
                jsr     JMP_PRINT_HEX
                println STR_RCV_DONE
                rts

; The routine vectored to by rcv. This gets each received
; data byte in the A register. It saves it in RAM to it can
; be jumped to by the jmp command.
save_to_ram:    sta     (rcv_buffer_pointer)
                inc     rcv_buffer_pointer
                bne     @done
                inc     rcv_buffer_pointer+1
@done:          rts     

; ex: `load 00 04` means load 4 pages from eeprom, starting at page 0
                ; page arg
load:           jsr     load_save_args
                jmp     JMP_STOR_READ
save:           jsr     load_save_args
                jmp     JMP_STOR_WRITE

load_save_args: clc
                lda     #<__INPUTBFR_START__
                adc     param_index
                jsr     hex_to_byte
                sta     stor_eeprom_addr_h

                ; page count
                clc
                lda     #<__INPUTBFR_START__
                adc     param_index
                adc     #3
                jsr     hex_to_byte
                tax
                rts

set_drive0:     lda     #0
                bra     set_drive
set_drive1:     lda     #1
                bra     set_drive
set_drive2:     lda     #2
                bra     set_drive
set_drive3:     lda     #3
set_drive:      sta     current_drive
                rts

edit:           clc
                lda     #<__INPUTBFR_START__
                adc     param_index     ; calculate the start of the param
                
                jsr     hex_to_byte     ; this puts the page number in A
                jsr     edit_page
                rts

; Very simple command to jump to the start of the receive buffer.
; Notes:
;   - This will crash the computer if whatever data is there
;     doesn't consist of a valid and correct program
;   - If the loaded program returns control with RTS, it gives
;     control back to line_input which is where the original JSR
;     is. After that only indirect jumps are used.
run:            jmp     __PROGRAM_START__

;------------------------------------------------------
;                List of commands                     ;
;------------------------------------------------------
; This is a list of addresses of where each of the commands start
; We index into this (using the constants in strings.inc) to find
; where each next command definition starts in memory
commands:       .word   cmd_dump, cmd_rcv, cmd_cls, cmd_run, cmd_reset
                .word   cmd_d0, cmd_d1, cmd_d2, cmd_d3, cmd_load, cmd_save
                .word   cmd_edit, 0

cmd_dump:       .byte   "dump", 0
                .word   dump
cmd_rcv:        .byte   "rcv", 0
                .word   rcv
cmd_cls:        .byte   "cls", 0
                .word   init_screen
cmd_run:        .byte   "run", 0
                .word   run
cmd_reset:      .byte   "reset", 0
                .word   reset
cmd_d0:         .byte   "d0", 0
                .word   set_drive0
cmd_d1:         .byte   "d1", 0
                .word   set_drive1
cmd_d2:         .byte   "d2", 0
                .word   set_drive2
cmd_d3:         .byte   "d3", 0
                .word   set_drive3
cmd_load:       .byte   "load", 0
                .word   load
cmd_save:       .byte   "save", 0
                .word   save
cmd_edit:       .byte   "edit", 0
                .word   edit