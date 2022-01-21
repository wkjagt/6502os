.include "strings.inc"
.include "keyboard.inc"
.include "screen.inc"
.include "zeropage.inc"

.import xmodem_receive
.import dump_page
.import __JUMPTABLE_START__

JUMP = $4C

.code

reset:          jsr     init_screen
                jsr     init_keyboard
                lda     #STR_STARTUP
                jsr     print_string

                ldx     #0
clear_zp:       stz     0,x
                inx
                bne     clear_zp

copy_jumptable: ldx     #0
@loop:          lda     jump_table,x
                sta     $0300,x
                inx
                cpx     end_jump_table-jump_table
                bne     @loop

line_input:     jsr     cr
                lda     #STR_PROMPT
                jsr     print_string_no_lf

                stz     inputbuffer_ptr

                ldx     #128            ; inputbuffer size
clear_buffer:   stz     inputbuffer,x
                dex
                bne     clear_buffer
next_key:       jsr     read_key
                cmp     #BS
                beq     @backspace
                cmp     #LF                
                beq     @enter

                jsr     putc
                cmp     #SPACE
                bne     @not_a_space
                lda     #0              ; save 0 instead of space into buffer, so it 
                                        ; matches the end of the command string
@not_a_space:   ldx     inputbuffer_ptr
                sta     inputbuffer,x
                inc     inputbuffer_ptr

                bra     next_key
@enter:         lda     inputbuffer_ptr
                beq     line_input      ; do nothing if empty line

                jsr     find_command
                bra     line_input
@backspace:     lda     inputbuffer_ptr
                beq     next_key        ; already at start of line

                lda     #BS
                jsr     putc
                lda     #' '
                jsr     putc
                lda     #BS
                jsr     putc

                dec     inputbuffer_ptr
                ldx     inputbuffer_ptr
                stz     inputbuffer,x

                bra     next_key

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
@unknown:       lda     #STR_UNKNOWN_CMD
                jsr     print_string
                rts

; This looks at one command entry and matches it agains what's in the
; inputbuffer.
; Y:    index into the string to match
; tmp1: the starting address of the string
match_command:  ldy     #0              ; index into strings
@compare_char:  lda     inputbuffer,y
                cmp     (tmp1),y
                beq     @continue
                sec                     ; to message to the caller that the command didn't match
                rts
@continue:      lda     inputbuffer,y   ; is it the last character?
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
                lda     #inputbuffer
                adc     param_index     ; calculate the start of the param
                
                jsr     hex_to_byte
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
                lda     #<rcv_buffer
                sta     rcv_buffer_pointer
                lda     #>rcv_buffer
                sta     rcv_buffer_pointer+1

                ; prompt the user to press a key to start receiving
                lda     #STR_RCV_WAIT
                jsr     print_string

                ; The sender starts transmitting bytes as soon as
                ; it receives a NAK byte from the receiver. To be
                ; able to synchronize the two, the workflow is:
                ; 1. start sending command on sender
                ; 2. Press any key on the receiver to start the
                ;    transmission
                jsr     read_key

                lda     #STR_RCV_START
                jsr     print_string

                jsr     xmodem_receive

                lda     #STR_RCV_DONE
                jsr     print_string
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

; Very simple command to jump to the start of the receive buffer.
; Notes:
;   - This will crash the computer if whatever data is there
;     doesn't consist of a valid and correct program
;   - If the loaded program returns control with RTS, it gives
;     control back to line_input which is where the original JSR
;     is. After that only indirect jumps are used.
run:            jmp     rcv_buffer

;------------------------------------------------------
;                List of commands                     ;
;------------------------------------------------------
commands:       .word   cmd_dump, cmd_rcv, cmd_cls, cmd_run, cmd_reset, 0

cmd_dump:       .byte   "dump", 0
                .word   __JUMPTABLE_START__ + 0
cmd_rcv:        .byte   "rcv", 0
                .word   __JUMPTABLE_START__ + 3
cmd_cls:        .byte   "cls", 0
                .word   __JUMPTABLE_START__ + 6
cmd_run:        .byte   "run", 0
                .word   __JUMPTABLE_START__ + 9
cmd_reset:      .byte   "reset", 0
                .word   __JUMPTABLE_START__ + 12

jump_table:
jmp_dump:       jmp     dump
jmp_rcv:        jmp     rcv
jmp_cls:        jmp     init_screen
jmp_run:        jmp     run
jmp_reset:      jmp     reset
end_jump_table:
            