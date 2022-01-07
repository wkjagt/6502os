                .import VIA1_DDRA
                .import VIA1_PORTA
                .import VIA1_DDRB
                .import VIA1_PORTB

                .import ACIA_DATA
                .import ACIA_CMD

                .import init_screen
                .import send_byte_to_screen

NAK             =       $15
ACK             =       $06
EOT             =       $04
SOH             =       $01

; kb
KB_CHAR_IN      =       $0
KB_ACK          =       %01000000
RD_SRL_B        =       $838D

                .zeropage

tmp1:           .res 2
tmp2:           .res 2
tmp3:           .res 2

                .code

screen_init:
                jsr     init_screen

                ; startup message
                lda     #str_startup
                jsr     print_string

kb_init:
                ; data direction on port B
                lda     #KB_ACK         ; only the ack pin is output
                sta     VIA1_DDRB

                lda     #str_any_key
                jsr     print_string

wait_for_key_press:
                ; The sender starts transmitting bytes as soon as
                ; it receives a NAK byte from the receiver. To be
                ; able to synchronize the two, the workflow is:
                ; 1. start sending command on sender
                ; 2. Press any key on the receiver to start the
                ;    transmission
                lda     VIA1_PORTB
                bpl     wait_for_key_press

                ; take the key from the buffer and ignore it
                jsr     receive_nibble
                jsr     receive_nibble
                jsr     receive_nibble

xmodem_receive:
                ; tell the sender to start sending
                lda     #NAK
                sta     ACIA_DATA

; Receiving bytes are done in two nested loops:
; @next_packet receives xmodem packets of 131 bytes long,
; including the 128 data bytes, and loops until an EOT byte
; is received right after a 
; @next_data_byte receives each of the 128 data bytes
@next_packet:
                jsr     receive_byte    ; receive SOH or EOT
                cmp     #EOT
                beq     @eot

                cmp     #SOH
                beq     @continue_header

                ; todo: error if ending up here?
@continue_header:
                jsr     receive_byte    ; packet sequence number
                jsr     receive_byte    ; packet sequence number checksum
                ; todo: add up and check if 0

                ldy     #128            ; 128 data bytes
@next_data_byte:
                jsr     receive_byte
                jsr     print_formatted_byte_as_hex

                dey
                bne     @next_data_byte 

                jsr     receive_byte    ; receive the data packet checksum

                ; todo: verify checksum and send ACK or NAK

                lda     #ACK
                sta     ACIA_DATA

                jmp     @next_packet
@eot:
                lda     #ACK
                sta     ACIA_DATA
                rts

receive_byte:
                ; reading a byte through serial connection
                ; is wrapped in turning DTR on and off. However
                ; it seems to not completely work, since we still
                ; need a short pause between the bytes when sending.
                lda     #%11001011      ; terminal ready
                sta     ACIA_CMD

                jsr     RD_SRL_B        ; blocking
                pha

                lda     #%11001010      ; terminal not ready
                sta     ACIA_CMD

                pla
                rts

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

receive_nibble:
                lda     VIA1_PORTB        ; LDA loads bit 7 (avail) into N
                ; move low nibble from PORT B to high nibble
                asl
                asl
                asl
                asl

                ldx     #4
@rotate:
                asl                     ; shift bit into carry
                rol     KB_CHAR_IN      ; rotate carry into CHAR
                dex
                bne     @rotate

                lda     VIA1_PORTB        ; send ack signal to kb controller
                ora     #KB_ACK
                sta     VIA1_PORTB
@wait_avail_low:
                lda     VIA1_PORTB        ; wait for available to go low
                bmi     @wait_avail_low ; negative means bit 7 (avail) high

                lda     VIA1_PORTB           ; set ack low
                and     #!KB_ACK
                sta     VIA1_PORTB
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

; strings ========================================

str_startup     =       0
str_any_key     =       1

string_table:
                .word s_startup, s_any_key

s_startup:      .byte "Shallow Thought v0.01", 0                
s_any_key:      .byte "Press any key", 0
