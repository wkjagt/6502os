.include "jump_table.inc"
.include "strings.inc"
.include "keyboard.inc"
.include "screen.inc"
.include "acia.inc"
.include "zeropage.inc"
.include "storage.inc"

.import xmodem_receive
.import dump_page
.import __PROGRAM_START__
.import __INPUTBFR_START__
; .import __RAM_SIZE__

.code

reset:          sei                     ; no interrupts, but user programs can enable them
                ldx     #$ff
                txs
clear_ram:      stz     tmp1            ; low byte, always 0, index into it using y
                stz     tmp1+1          ; high byte, start at last page of RAM
                ldy     #0
                lda     #0
@loop:          sta     (tmp1), y
                iny
                bne     @loop
                inc     tmp1+1
                bne     @loop
copy_jumptable: ldx     #(end_jump_table-jump_table)
@loop:          lda     jump_table,x
                sta     __JUMPTABLE_START__,x
                dex
                cpx     #$ff            ; ugly. is there a better way?
                bne     @loop

                jsr     JMP_INIT_SCREEN
                jsr     JMP_INIT_KB
                jsr     JMP_INIT_SERIAL
                jsr     JMP_INIT_STORAGE

                print   STR_STARTUP

                jsr     JMP_LINE_INPUT

; Get the input for one line until enter is pressed. Then try to execute a command
line_input:     jsr     cr

                lda     current_drive
                adc     #48              ; to ascii
                jsr     JMP_PUTC
                lda     #'#'
                jsr     JMP_PUTC
                lda     #' '
                jsr     JMP_PUTC
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
                beq     line_input      ; do nothing if empty line

                jsr     find_command
                bra     line_input
@backspace:     lda     inputbuffer_ptr
                beq     @next_key        ; already at start of line

                lda     #BS
                jsr     JMP_PUTC
                lda     #' '
                jsr     JMP_PUTC
                lda     #BS
                jsr     JMP_PUTC

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
@unknown:       print   STR_UNKNOWN_CMD
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
                print   STR_RCV_WAIT

                ; The sender starts transmitting bytes as soon as
                ; it receives a NAK byte from the receiver. To be
                ; able to synchronize the two, the workflow is:
                ; 1. start sending command on sender
                ; 2. Press any key on the receiver to start the
                ;    transmission
                jsr     JMP_GETC

                print   STR_RCV_START

                jsr     JMP_XMODEM_RCV

                print   STR_RCV_DONE
                rts

; The routine vectored to by rcv. This gets each received
; data byte in the A register. It saves it in RAM to it can
; be jumped to by the jmp command.
save_to_ram:
                sta     (rcv_buffer_pointer)
                inc     rcv_buffer_pointer
                bne     @done
                inc     rcv_buffer_pointer+1
@done:          rts     

set_drive0:     lda     #0
                bra     set_drive
set_drive1:     lda     #1
                bra     set_drive
set_drive2:     lda     #2
                bra     set_drive
set_drive3:     lda     #3
set_drive:      sta     current_drive
                rts

; Very simple command to jump to the start of the receive buffer.
; Notes:
;   - This will crash the computer if whatever data is there
;     doesn't consist of a valid and correct program
;   - If the loaded program returns control with RTS, it gives
;     control back to line_input which is where the original JSR
;     is. After that only indirect jumps are used.
run:            jmp     __PROGRAM_START__

; Interrupt handlers don't do anything for now, but they jump 
; through the jump table so they can be overriden in software
irq:            jmp     JMP_IRQ_HANDLER
nmi:            jmp     JMP_NMI_HANDLER
irqnmi:         rti
;------------------------------------------------------
;                List of commands                     ;
;------------------------------------------------------
; This is a list of addresses of where each of the commands start
; We index into this (using the constants in strings.inc) to find
; where each next command definition starts in memory
commands:       .word   cmd_dump, cmd_rcv, cmd_cls, cmd_run, cmd_reset
                .word   cmd_d0, cmd_d1, cmd_d2, cmd_d3, 0

cmd_dump:       .byte   "dump", 0
                .word   JMP_DUMP
cmd_rcv:        .byte   "rcv", 0
                .word   JMP_RCV
cmd_cls:        .byte   "cls", 0
                .word   JMP_INIT_SCREEN
cmd_run:        .byte   "run", 0
                .word   JMP_RUN
cmd_reset:      .byte   "reset", 0
                .word   JMP_RESET
cmd_d0:         .byte   "d0", 0
                .word   set_drive0
cmd_d1:         .byte   "d1", 0
                .word   set_drive1
cmd_d2:         .byte   "d2", 0
                .word   set_drive2
cmd_d3:         .byte   "d3", 0
                .word   set_drive3

; This jump table isn't used at this location. These are default values
; That are copied to the JUMPTABLE segment in RAM on reset, and can be overriden
; from user software.
jump_table:
                jmp     dump
                jmp     rcv
                jmp     init_screen
                jmp     run
                jmp     reset
                jmp     putc
                jmp     print_byte_as_hex
                jmp     xmodem_receive
                jmp     read_key
                jmp     init_keyboard
                jmp     line_input
                jmp     irqnmi
                jmp     irqnmi
                jmp     init_serial
                jmp     cursor_on
                jmp     cursor_off
                jmp     draw_pixel
                jmp     rmv_pixel
                jmp     init_storage
                jmp     read_pages
                jmp     write_pages
end_jump_table:

.segment "VECTORS"

                .word   nmi
                .word   reset
                .word   irq