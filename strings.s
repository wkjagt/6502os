.include "strings.inc"
.include "zeropage.inc"
.include "screen.inc"
.include "jump_table.inc"

.code

string_table:
                .word   s_startup, s_rcv_wait, s_unknown_cmd, s_rcv_done
                .word   s_rcv_start

s_startup:      .byte   "                           -- Shallow Thought OS --", 0                
s_rcv_wait:     .byte   "Initiate transfer on transmitter and then press any key.", 0
s_unknown_cmd:  .byte   ": unknown command", 0 
s_rcv_done:     .byte   "Transfer completed to $2000.", 0
s_rcv_start:    .byte   "Starting transfer to $2000...", 0

print_formatted_byte_as_hex:
                jsr     JMP_PRINT_HEX
                lda     #' '
                jsr     JMP_PUTC
                rts

print_byte_as_hex:
                pha                     ; keep a copy for the low nibble

                lsr                     ; shift high nibble into low nibble
                lsr
                lsr
                lsr

                jsr     print_nibble

                pla                     ; get original value back
                and     #%00001111      ; reset high nibble
                jsr     print_nibble
                rts

print_nibble:
                cmp     #10
                bcs     @letter         ; >= 10 (hex letter A-F)
                adc     #48             ; ASCII offset to numbers 0-9
                jmp     @print
@letter:
                adc     #54             ; ASCII offset to letters A-F
@print:
                jsr     JMP_PUTC
                rts

print_string_no_lf:
                asl                     ; multiply by 2 because size of memory address is 2 bytes
                tay
                lda     string_table,y  ; string index into string table
                sta     tmp3            ; LSB
                iny
                lda     string_table,y
                sta     tmp3+1          ; MSB

                ldy     #0
@next_char:
                lda     (tmp3),y
                beq     @done

                jsr     JMP_PUTC
                iny
                bra     @next_char
@done:
                rts

print_string:
                jsr     print_string_no_lf
                lda     #$0d
                jsr     JMP_PUTC
                lda     #$0a
                jsr     JMP_PUTC
                rts


; Turn two ascii bytes into a byte containing the value represented
; by the two characters 0-F
; A: zero page pointer to first character (the high nibble). The next char is the low nibble.
hex_to_byte:    sta     tmp2            ; we need the address to do lda (tmp2), y
                stz     tmp2+1
                
                ldy     #0              ; high nibble
                lda     (tmp2),y
                jsr     @shift_in_nibble

                iny
                lda     (tmp2),y        ; low nibble
                jsr     @shift_in_nibble

                lda     tmp1            ; put the result back in A as return value
                rts
@shift_in_nibble:
                cmp     #':'            ; the next ascii char after "9"
                bcc     @number
                                        ; assume it's a letter
                sbc     #87             ; get the letter value
                jmp     @continue
@number:
                sec
                sbc     #48
@continue:      
                ; calculated nibble is now in low nibble
                ; shift low nibble to high nibble
                asl 
                asl 
                asl 
                asl

                ; left shift hight nibble into result
                asl
                rol     tmp1
                asl
                rol     tmp1
                asl
                rol     tmp1
                asl
                rol     tmp1

                rts

cr:
                lda     #LF
                jsr     JMP_PUTC
                lda     #CR
                jsr     JMP_PUTC
                rts
