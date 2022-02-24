.include "input.inc"
.include "../os/pager_os.inc"

.import __INPUTBFR_START__
.import __INPUTBFR_SIZE__

.zeropage
inputbuffer_ptr:        .res 2

.code

get_input:      stz     inputbuffer_ptr
                ldx     #<__INPUTBFR_SIZE__-1   ; -1 bcause otherwise it wraps to addr 00
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
@backspace:     lda     inputbuffer_ptr
                beq     @next_key       ; already at start of line

                putc    BS
                putc    ' '
                putc    BS

                dec     inputbuffer_ptr
                ldx     inputbuffer_ptr
                stz     <__INPUTBFR_START__,x

                bra     @next_key
@enter:         rts