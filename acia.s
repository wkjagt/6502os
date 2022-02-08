.include "acia.inc"

.code

init_serial:    lda     #%11001011      ; No parity, no echo, no interrupt
                sta     ACIA_CMD
                lda     #%00011111      ; 1 stop bit, 8 data bits, 19200 baud
                sta     ACIA_CTRL
                rts

rcv_byte:
                ; reading a byte through serial connection
                ; is wrapped in turning DTR on and off. However
                ; it seems to not completely work, since we still
                ; need a short pause between the bytes when sending.
                phx
                lda     #%11001011      ; terminal ready
                sta     ACIA_CMD
@loop:                
                lda     ACIA_STAT
                and     #SER_RXFL
                beq     @loop
                lda     ACIA_DATA

                ldx     #%11001010      ; terminal not ready
                stx     ACIA_CMD
                plx
                rts

send_byte:
                sta     ACIA_DATA
                rts