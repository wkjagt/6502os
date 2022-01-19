.include "strings.inc"
.include "keyboard.inc"
.include "screen.inc"
.include "zeropage.inc"

.import xmodem_receive
.import dump_page

.code

reset:
                jsr     init_screen
                jsr     init_keyboard

                lda     #STR_STARTUP
                jsr     print_string

                ldx     #0
clear_zp:
                stz     0,x
                inx
                bne     clear_zp

next_command:
                jsr     cr
                stz     keybuffer_ptr

                ldx     #128
clear_buffer:                
                stz     keybuffer,x
                dex
                bne     clear_buffer
next_key:
                jsr     read_key

                cmp     #DEL
                beq     @backspace
                cmp     #LF                
                beq     @enter

                jsr     putc
                cmp     #SPACE
                bne     @not_a_space
                lda     #0              ; save 0 instead of space into buffer, so it 
                                        ; matches the end of the command string
@not_a_space:
                ldx     keybuffer_ptr
                sta     keybuffer,x
                inc     keybuffer_ptr

                bra     next_key
@enter:
                lda     keybuffer_ptr
                beq     next_command    ; do nothing if empty line

                jsr     find_command
                bra     next_command
@backspace:
                lda     #BS
                jsr     putc
                lda     #' '
                jsr     putc
                lda     #BS
                jsr     putc

                lda     keybuffer_ptr
                beq     next_key        ; already at start of line
                dec     keybuffer_ptr
                ldx     keybuffer_ptr
                stz     keybuffer,x

                bra     next_key

; this loops over all the commands under the commands label
; each of those points to an entry in the list that contains the
; command string to match and the address of the routine to execute
find_command:
                ldx     #0              ; index into list of commands
@loop:
                lda     commands,x      ; load the address of the entry
                sta     tmp1            ; into tmp1 (16 bits)
                inx
                lda     commands,x
                sta     tmp1+1

                lda     (tmp1)          ; see if this is the last entry
                ora     (tmp1+1)        ; check two bytes for 0.
                beq     @end_of_list

                jsr     match_command
                inx
                bra     @loop
@end_of_list:
                bcc     @done
                lda     #STR_UNKNOWN_CMD
                jsr     print_string
@done:
                rts

; This looks at one command entry and matches it agains what's in the
; keybuffer.
; Y:    index into the string to match
; tmp1: the starting address of the string
match_command:
                ldy     #0              ; index into strings
@compare_char:
                lda     keybuffer,y
                cmp     (tmp1),y
                beq     @continue
                sec                     ; to message to the caller that the command didn't match
                rts
@continue:
                lda     keybuffer,y     ; is it the last character?
                beq     @string_matched
                iny
                jmp     @compare_char
@string_matched:         
                iny                     ; skip past the 0 at the end of the string
                sty     param_index

                ; tmp1 now points to the command that holds the address
                ; to jump to. Store that address in command_vector so we
                ; can jump to it.
                lda     (tmp1), y
                sta     command_vector      
                iny
                lda     (tmp1), y
                sta     command_vector+1
                jsr     cr
                jmp     (command_vector)
                clc                     ; to message to the caller that the command matched
                rts

; The dump command. It dumps one page of memory. It takes a hex page number as parameter.
; Example: `dump a0` to dump page $a0.
dump:
                clc
                lda     #keybuffer
                adc     param_index         ; calculate the start of the param
                
                jsr     hex_to_byte
                jsr     dump_page
                rts

; The rcv command. It waits for a keypress to give the user the opportunity to start
; the transmission on the transmitting computer. A key press sends the initial NAK
; and starts receiving. It uses xmodem_byte_sink_vector as a vector to a routine that
; receives each data byte in the A register.
rcv:
                ; set the vector for what to do with each byte coming in through xmodem
                lda     #<print_formatted_byte_as_hex
                sta     xmodem_byte_sink_vector
                lda     #>print_formatted_byte_as_hex
                sta     xmodem_byte_sink_vector+1

                ; prompt the user to press a key to start receiving
                lda     #STR_XMODEM_START
                jsr     print_string

                ; The sender starts transmitting bytes as soon as
                ; it receives a NAK byte from the receiver. To be
                ; able to synchronize the two, the workflow is:
                ; 1. start sending command on sender
                ; 2. Press any key on the receiver to start the
                ;    transmission
                jsr     read_key
                jsr     xmodem_receive
                rts

commands:
                .word   c_dump, c_rcv, 0

c_dump:         .byte   "dump", 0
                .word   dump
c_rcv:          .byte   "rcv", 0
                .word   rcv


