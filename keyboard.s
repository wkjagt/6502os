                .import VIA1_DDRB
                .import VIA1_PORTB

                .export init_keyboard
                .export wait_for_key_press

KB_CHAR_IN      =       $0
KB_ACK          =       %01000000

                .code

init_keyboard:
                ; data direction on port B
                lda     #KB_ACK         ; only the ack pin is output
                sta     VIA1_DDRB
                rts

wait_for_key_press:
                lda     VIA1_PORTB
                bpl     wait_for_key_press

                ; take the key from the buffer and ignore it
                jsr     receive_nibble
                jsr     receive_nibble
                jsr     receive_nibble
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
