.include "terminal.inc"
.include "../os/jump_table.inc"
.include "../os/strings.inc"
.include "../os/keyboard.inc"
.include "../os/screen.inc"
.include "../os/zeropage.inc"
.include "edit.inc"
.include "receive.inc"
.include "dump.inc"
.include "storage.inc"
.include "run.inc"

.import dump_page
.import __INPUTBFR_START__

.zeropage
inputbuffer_ptr:        .res 2
; reserve space for 3 16 byte args. store single byte values in position 1, 3, 5 so they can be
; easily used as addresses where the argument represents a page in memory. Example: argument 0A
; in memory looks like 00 0A, where the address can be referenced directly because 6502 is little endian.
terminal_args:          .res 6

.code
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
                beq     terminal        ; do nothing if empty line

                jsr     find_command
                bra     terminal
@backspace:     lda     inputbuffer_ptr
                beq     @next_key       ; already at start of line

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
                sta     tmp2
                iny
                lda     (tmp1), y
                sta     tmp2+1
                jsr     cr
                jmp     (tmp2)
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
                jsr     save_args
                clc                     ; to message to the caller that the command matched
                rts


save_args:      phy
                lda     tmp1            ; tmp1 is used by hex_to_byte
                pha

                ldx     #1
@arg_loop:      tya
                clc
                adc     #<__INPUTBFR_START__
                jsr     hex_to_byte
                sta     terminal_args, x
                cpx     #5
                beq     @done
                inx
                inx
                iny
                iny
                iny
                bra     @arg_loop
@done:          pla
                sta     tmp1
                ply
                rts


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
                .word   receive
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