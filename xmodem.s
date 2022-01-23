.include "acia.inc"
.include "addresses.inc"

.export xmodem_receive

RD_SRL_B        =       $838D
NAK             =       $15
ACK             =       $06
EOT             =       $04
SOH             =       $01

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
                jsr     xmodem_byte_sink

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

xmodem_byte_sink:
                ; We came here through a JSR, so the return address is on the stack
                ; jumping from here because there's no jsr (addr). The routine that
                ; this jumps to can do a rts, which will go back to the original place
                ; in @next_data_byte.
                jmp     (xmodem_byte_sink_vector)
