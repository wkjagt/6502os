.include "acia.inc"

.code

init_serial:    lda     #%11001011      ; No parity, no echo, no interrupt
                sta     ACIA_CMD
                lda     #%00011111      ; 1 stop bit, 8 data bits, 19200 baud
                sta     ACIA_CTRL
                rts

rcv_byte:
                lda     ACIA_STAT
                and     #SER_RXFL
                beq     rcv_byte
                lda     ACIA_DATA

                rts

send_byte:
                sta     ACIA_DATA
                rts