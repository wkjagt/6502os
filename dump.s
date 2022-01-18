.import putc
.import print_byte_as_hex
.import cr

.export dump_page

dump_start = $0a

.code

dump_page:
                sta     dump_start+1
                ldx     #0
                ldy     #0
; start of line (new line + start address)
; x counts up to 16 for each row
; y counts up to 256 for the whole page of memory
@next_row:
                jsr     cr
                
                lda     dump_start+1
                jsr     print_byte_as_hex
                tya
                jsr     print_byte_as_hex
                lda     #' '
                jsr     putc
                lda     #' '
                jsr     putc

                ldx     #0
; raw bytes
@next_hex_byte:
                lda     (dump_start),y
                jsr     print_byte_as_hex
                lda     #' '
                jsr     putc
                iny
                inx
                cpx     #16
                beq     @ascii
                cpx     #8
                bne     @next_hex_byte
                lda     #' '
                jsr     putc
                bra     @next_hex_byte
; ascii representation
@ascii:
                ldx     #0
                tya
                sec
                sbc     #16             ; rewind 16 bytes for ascii
                tay
                lda     #' '
                jsr     putc
                lda     #' '
                jsr     putc
@next_ascii_byte:
                ; ascii: $20-$7E
                lda     (dump_start),y
                cmp     #$20            ; space
                bcc     @not_ascii
                cmp     #$7F
                bcs     @not_ascii
                jsr     putc
                bra     @continue_ascii_byte
@not_ascii:
                lda     #'.'
                jsr     putc
@continue_ascii_byte:
                iny
                beq     @done
                inx
                cpx     #16
                beq     @next_row
                bra     @next_ascii_byte
@done:
                rts