.include "strings.inc"
.include "zeropage.inc"
.include "screen.inc"

.code

string_table:
                .word   s_startup, s_xmodem_start, s_unknown_cmd

s_startup:      .byte   "                           -- Shallow Thought OS --", 0                
s_xmodem_start: .byte   "Initiate transfer on transmitter and then press any key", 0
s_unknown_cmd:  .byte  ": unknown command", 0 

print_formatted_byte_as_hex:
                jsr     print_byte_as_hex
                lda     #' '
                jsr     putc
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
                jsr     putc
                rts

print_string:
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

                jsr     putc
                iny
                bra     @next_char
@done:
                lda     #$0d
                jsr     putc
                lda     #$0a
                jsr     putc
                rts


; Turn two ascii bytes into a byte containing the value represented
; by the two characters 0-F
hex_to_byte:
                sta     tmp2            ; we need the address to do lda (tmp2), y

                ldy     #0              ; high byte
                lda     (tmp2),y
                jsr     @shift_in_nibble

                iny
                lda     (tmp2),y        ; low byte
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
                jsr     putc
                lda     #CR
                jsr     putc
                rts
