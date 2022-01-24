.include "acia.inc"
.include "addresses.inc"

.export xmodem_receive

NAK             =       $15
ACK             =       $06
EOT             =       $04
SOH             =       $01

xmodem_receive:
                ; tell the sender to start sending
                jsr     nak

; Receiving bytes are done in two nested loops:
; @next_packet receives xmodem packets of 131 bytes long,
; including the 128 data bytes, and loops until an EOT byte
; is received right after a 
; @next_data_byte receives each of the 128 data bytes
@next_packet:
                jsr     rcv_byte        ; receive SOH or EOT
                cmp     #EOT
                beq     @eot

                cmp     #SOH
                beq     @continue_header

                ; todo: error if ending up here?
@continue_header:
                jsr     rcv_byte        ; packet sequence number
                jsr     rcv_byte        ; packet sequence number checksum
                ; todo: add up and check if 0

                ldy     #128            ; 128 data bytes
@next_data_byte:
                jsr     rcv_byte
                jsr     xmodem_byte_sink

                dey
                bne     @next_data_byte 

                jsr     rcv_byte        ; receive the data packet checksum

                ; todo: verify checksum and send ACK or NAK
                jsr     ack

                jmp     @next_packet
@eot:
                jsr     ack
                rts

xmodem_byte_sink:
                ; We came here through a JSR, so the return address is on the stack
                ; jumping from here because there's no jsr (addr). The routine that
                ; this jumps to can do a rts, which will go back to the original place
                ; in @next_data_byte.
                jmp     (xmodem_byte_sink_vector)

ack:
                lda     #ACK
                jsr     send_byte
                rts

nak:
                lda     #NAK
                jsr     send_byte
                rts