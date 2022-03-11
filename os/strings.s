.include "strings.inc"
.include "zeropage.inc"
.include "screen.inc"
.include "jump_table.inc"

.zeropage
tmp_string:     .res    2

.code

string_table:
                .word   s_startup, s_rcv_wait, s_unknown_cmd, s_rcv_done
                .word   s_rcv_start

; todo: most of these aren't specific to OS

s_startup:      .byte   "                           -- Pager OS --", 0                
s_rcv_wait:     .byte   "Initiate transfer on transmitter and then press any key.", 0
s_unknown_cmd:  .byte   ": unknown command", 0 
s_rcv_done:     .byte   " page(s) received.", 0
s_rcv_start:    .byte   "Starting transfer...", 0

print_formatted_byte_as_hex:
                jsr     JMP_PRINT_HEX
                putc    ' '
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

print_string:   jsr     print_string_no_lf
                putc    $0d             ; todo: use constant
                putc    $0a             ; todo: use constant
                rts

;=============================================================================
; Print the string that follows the JSR instruction that jumps to
; this routine. It uses the return address on the stack to find the
; bytes right after the JSR instruction. It updates the return address
; on the stack to return to the instruction that follows the bytes.
; The string data after the JSR instruction needs to end with a 0 byte.
; Example:
;               jsr     print_string2
;               .byte   "Print this string",0
;=============================================================================
print_string2:  pla                     ; get the return address from the stack
                sta     tmp_string      ; and put it in tmp_string. That way it
                pla                     ; can be used for indirect addressing to
                sta     tmp_string+1    ; read the string right after the JSR.

@loop:          inc     tmp_string      ; inc low byte to point to the next byte
                bne     @cont           ; of the string. Incr for the first byte
                inc     tmp_string+1    ; works because JSR pushed the address to
@cont:          lda     (tmp_string)    ; the last byte of the JSR instruction.
                beq     @done           ; Done when 0 is read.
                jsr     JMP_PUTC
                bra     @loop

@done:          lda     tmp_string+1    ; tmp_string was incremented to point to the
                pha                     ; 0 which ended the string, which is the byte
                lda     tmp_string      ; right before where RTS needs to go, which
                pha                     ; perfectly mirrors how JSR/RTS work together.
                rts


; Turn two ascii bytes into a byte containing the value represented
; by the two characters 0-F
; A: zero page pointer to first character (the high nibble). The next char is the low nibble.
hex_to_byte:    phy
                sta     tmp2            ; we need the address to do lda (tmp2), y
                stz     tmp2+1
                
                ldy     #0              ; high nibble
                lda     (tmp2),y
                jsr     @shift_in_nibble

                iny
                lda     (tmp2),y        ; low nibble
                jsr     @shift_in_nibble

                lda     tmp1            ; put the result back in A as return value
                ply
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

cr:             putc    LF
                putc    CR
                rts
