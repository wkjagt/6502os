.export print_formatted_byte_as_hex
.export print_string

.import send_byte_to_screen

tmp1 = $02
tmp2 = $04
tmp3 = $06

.code

string_table:
                .word s_startup, s_any_key

s_startup:      .byte "Shallow Thought v0.01", 0                
s_any_key:      .byte "Press any key", 0

; this only adds a space
print_formatted_byte_as_hex:
                jsr     print_byte_as_hex
                lda     #' '
                jsr     send_byte_to_screen
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
                jsr     send_byte_to_screen
                rts

print_string:
                asl                     ; multiply by 2 because size of memory address is 2 bytes
                tay
                lda     string_table,y  ; string index into string table
                sta     tmp3            ; LSB
                iny
                lda     string_table,y
                sta     tmp3+1          ; MSB

                ldy #0
@next_char:
                lda (tmp3),y
                beq @done

                jsr send_byte_to_screen
                iny
                bra @next_char
@done:
                lda     #$0d
                jsr     send_byte_to_screen
                lda     #$0a
                jsr     send_byte_to_screen
                rts
