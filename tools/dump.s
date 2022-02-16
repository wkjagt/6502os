.include "dump.inc"
.include "terminal.inc"
.include "../os/jump_table.inc"
.include "../os/strings.inc"
.include "../os/screen.inc"
.include "../os/zeropage.inc"           ; todo: remove once no longer needed

.export dump_page                       ; todo: remove
.import __INPUTBFR_START__              ; todo: move arg parsing to terminal

.code

; The dump command. It dumps one page of memory. It takes a hex page number as parameter.
; Example: `dump a0` to dump page $a0.
dump:           clc
                lda     #<__INPUTBFR_START__
                adc     param_index     ; calculate the start of the param
                
                jsr     hex_to_byte     ; this puts the page number in A
                jsr     dump_page
                rts


dump_page:      stz     dump_start
                sta     dump_start+1    ; page
                ldx     #0
                ldy     #0
; start of line (new line + start address)
; x counts up to 16 for each row
; y counts up to 256 for the whole page of memory
@next_row:
                jsr     cr
                
                lda     dump_start+1
                jsr     JMP_PRINT_HEX
                tya
                jsr     JMP_PRINT_HEX
                putc    ' '
                putc    ' '

                ldx     #0
; raw bytes
@next_hex_byte:
                lda     (dump_start),y
                jsr     JMP_PRINT_HEX
                putc    ' '
                iny
                inx
                cpx     #16
                beq     @ascii
                cpx     #8
                bne     @next_hex_byte
                putc    ' '
                bra     @next_hex_byte
; ascii representation
@ascii:
                ldx     #0
                tya
                sec
                sbc     #16             ; rewind 16 bytes for ascii
                tay
                putc    ' '
                putc    ' '
@next_ascii_byte:
                ; ascii: $20-$7E
                lda     (dump_start),y
                cmp     #$20            ; space
                bcc     @not_ascii
                cmp     #$7F
                bcs     @not_ascii
                jsr     JMP_PUTC
                bra     @continue_ascii_byte
@not_ascii:
                putc    '.'
@continue_ascii_byte:
                iny
                beq     @done
                inx
                cpx     #16
                beq     @next_row
                bra     @next_ascii_byte
@done:
                rts