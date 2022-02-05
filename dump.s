.include "jump_table.inc"
.include "strings.inc"
.include "screen.inc"
.include "zeropage.inc"

.export dump_page

.code

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
                lda     #' '
                jsr     JMP_PUTC
                lda     #' '
                jsr     JMP_PUTC

                ldx     #0
; raw bytes
@next_hex_byte:
                lda     (dump_start),y
                jsr     JMP_PRINT_HEX
                lda     #' '
                jsr     JMP_PUTC
                iny
                inx
                cpx     #16
                beq     @ascii
                cpx     #8
                bne     @next_hex_byte
                lda     #' '
                jsr     JMP_PUTC
                bra     @next_hex_byte
; ascii representation
@ascii:
                ldx     #0
                tya
                sec
                sbc     #16             ; rewind 16 bytes for ascii
                tay
                lda     #' '
                jsr     JMP_PUTC
                lda     #' '
                jsr     JMP_PUTC
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
                lda     #'.'
                jsr     JMP_PUTC
@continue_ascii_byte:
                iny
                beq     @done
                inx
                cpx     #16
                beq     @next_row
                bra     @next_ascii_byte
@done:
                rts