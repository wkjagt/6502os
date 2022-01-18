.include "strings.inc"
.include "keyboard.inc"
.include "screen.inc"

.import xmodem_receive
.import dump_page


tmp1                    = $02
tmp2                    = $04
tmp3                    = $06

xmodem_byte_sink_vector = $08
command_vector          = $0c
param_index             = $0e
keybuffer_ptr           = $10
keybuffer               = $80


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
                pha
                jsr     putc
                pla
                cmp     #SPACE
                bne     @not_a_space
                lda     #0              ; save 0 instead of space into buffer
@not_a_space:
                cmp     #LF                
                beq     @enter

                ldx     keybuffer_ptr
                sta     keybuffer,x
                inc     keybuffer_ptr

                bra     next_key
@enter:
                jsr     cr
                jsr     execute_command
                bra     next_command
@backspace:
                lda     #BS
                jsr     putc
                lda     #' '
                jsr     putc
                lda     #BS
                jsr     putc

                lda     keybuffer_ptr
                beq     next_key            ; already at start of line
                dec     keybuffer_ptr
                ldx     keybuffer_ptr
                stz     keybuffer,x

                bra     next_key

; this loops over all the commands under the commands label
; each of those points to an entry in the list that contains the
; command string to match and the address of the routine to execute
execute_command:
                ldx     #0                  ; index into list of commands
find_command_loop:
                lda     commands,x          ; load the address of the entry
                sta     tmp1                ; into tmp1 (16 bits)
                inx
                lda     commands,x
                sta     tmp1+1

                lda     (tmp1)              ; see if this is the last entry
                ora     (tmp1+1)            ; check two bytes for 0.
                beq     @done

                jsr     match_command
                inx
                bra     find_command_loop
@done:
                rts

; This looks at one command entry and matches it agains what's in the
; keybuffer.
; Y:    index into the string to match
; tmp1: the starting address of the string
match_command:
                ldy     #0                  ; index into strings
@compare_char:
                lda     keybuffer,y
                cmp     (tmp1),y
                bne     @done
                lda     keybuffer,y         ; is it the last character?
                beq     @string_matched
                iny
                jmp     @compare_char
@string_matched:         
                iny     ; skip past the 0 at the end of the string
                sty     param_index

                ; tmp1 now points to the command that holds the address
                ; to jump to. Store that address in command_vector so we
                ; can jump to it.
                lda     (tmp1), y
                sta     command_vector      
                iny
                lda     (tmp1), y
                sta     command_vector+1

                jmp     (command_vector)
@done:
                rts

dump:
                clc
                lda     #keybuffer
                adc     param_index         ; calculate the start of the param
                
                jsr     hex_to_byte
                jsr     dump_page
                rts

rcv:
                lda     #STR_XMODEM_START
                jsr     print_string

                ; set the vector for what to do with each byte coming in through xmodem
                lda     #<print_formatted_byte_as_hex
                sta     xmodem_byte_sink_vector
                lda     #>print_formatted_byte_as_hex
                sta     xmodem_byte_sink_vector+1

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
                .word c_dump, c_rcv, 0

c_dump:         .byte "dump", 0
                .word dump
c_rcv:          .byte "rcv", 0
                .word rcv


