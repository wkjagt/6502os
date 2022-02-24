.include "xmodem.inc"
.include "acia.inc"

.zeropage
rcv_page_count:         .res 1
rcv_start_page:         .res 1
rcv_buffer_pointer:     .res 2

.code
; A: the page to start saving received data
xmodem_receive: stz     rcv_page_count
                stz     rcv_buffer_pointer
                sta     rcv_buffer_pointer+1
                sta     rcv_start_page  ; this one doesn't get updated

                ; tell the sender to start sending
                ldx     #0              ; packet counter
                jsr     nak

; Receiving bytes are done in two nested loops:
; @next_packet receives xmodem packets of 131 bytes long,
; including the 128 data bytes, and loops until an EOT byte
; is received right after a 
; @next_data_byte receives each of the 128 data bytes
@next_packet:   jsr     rcv_byte        ; receive SOH or EOT
                cmp     #EOT
                beq     @eot

                cmp     #SOH
                beq     @continue_header

                ; todo: error if ending up here?
@continue_header:
                jsr     rcv_byte        ; packet sequence number
                jsr     rcv_byte        ; packet sequence number checksum
                ; todo: add up and check if 0
                inx
                ldy     #128            ; 128 data bytes
@next_data_byte:jsr     rcv_byte
                jsr     save_to_ram

                dey
                bne     @next_data_byte 

                jsr     rcv_byte        ; receive the data packet checksum

                ; todo: verify checksum and send ACK or NAK
                jsr     ack

                jmp     @next_packet
@eot:           jsr     ack

                txa
                ina
                lsr                     ; packet count to page count
                sta     rcv_page_count

                rts

save_to_ram:    sta     (rcv_buffer_pointer)
                inc     rcv_buffer_pointer
                bne     @done
                inc     rcv_buffer_pointer+1
@done:          rts     

ack:
                lda     #ACK
                jsr     send_byte
                rts

nak:
                lda     #NAK
                jsr     send_byte
                rts