.include "keyboard.inc"
.include "via.inc"
.include "zeropage.inc"

KB_ACK          =       %01000000

                .code

init_keyboard:
                ; data direction on port B
                lda     #KB_ACK         ; only the ack pin is output
                sta     VIA1_DDRB
                rts

read_key:
                phx
                ; receive the character
                jsr     receive_nibble
                jsr     receive_nibble

                lda     kb_char_in      ; character is now in A, hold on to it
                pha

                jsr     receive_nibble  ; receive the flags
                pla                     ; this version ignores the flags
                plx
                rts

receive_nibble:
                lda     VIA1_PORTB
                bpl     receive_nibble
                asl
                asl
                asl
                asl

                ldx     #4
@rotate:
                asl                     ; shift bit into carry
                rol     kb_char_in      ; rotate carry into CHAR
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
