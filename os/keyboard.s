.include "keyboard.inc"
.include "via.inc"
.include "zeropage.inc"

;===========================================================================
; This reads characters from the keyboard. The keyboard sends ASCII characters
; 4 bits at a time. It sends 3 nibbles in total per character, where the
; the first two form the ASCII code, and the third consists of 4 flags,
; which represent the controls keys that were pressed.
; 
; Receiving a nibble works as follows:
; 1. When the keyboard has a new character available, it transitions
;    the "available line" from 0 to 1. This is the transition that the
;    `receive_nibble` routine waits for using "bpl". At the same time, the
;    first nibble is present on bit 0-3.
; 2. Once the transition is detected, the nibble is read, and shifted
;    into `kb_char_in`. The nibble remains available on the keyboard
;    until the ack line (bit 6) is transitioned from 0 to 1, which is how
;    this code signals to the keyboard that the nibble was read.
; 3. When the keyboard detects the transition on the ack line, it
;    transitions the avail line back to 0. The code below waits for that
;    transition before continuing. Once that is detected, the ack line is
;    set to 0 again, after which the state of the ack and avail lines are
;    back to where they started, and the system is ready for the next
;    nibble. The keyboard waits for this transition on the ack line
;    before continuing, so everything remains synchronized.
;===========================================================================

.zeropage

kb_char_in:             .res 1

.code

init_keyboard:  ; data direction on port B
                lda     #KB_ACK         ; only the ack pin is output
                sta     VIA1_DDRB
                rts

read_key:       phx
                ; receive the character
                jsr     receive_nibble
                jsr     receive_nibble

                lda     kb_char_in      ; character is now in A, hold on to it
                pha

                jsr     receive_nibble  ; receive the flags (control keys)
                pla                     ; this version ignores the flags
                plx
                rts

receive_nibble: lda     VIA1_PORTB
                bpl     receive_nibble  ; bpl checks for bit 7 which is
                asl                     ; the kb controller's avail signal
                asl
                asl
                asl

                ldx     #4
@rotate:        asl                     ; shift bit into carry
                rol     kb_char_in      ; rotate carry into CHAR
                dex
                bne     @rotate

                lda     VIA1_PORTB        ; send ack signal to kb controller
                ora     #KB_ACK
                sta     VIA1_PORTB
@wait_avail_low:lda     VIA1_PORTB        ; wait for available to go low
                bmi     @wait_avail_low   ; negative means bit 7 (avail) high

                lda     VIA1_PORTB           ; set ack low
                and     #!KB_ACK
                sta     VIA1_PORTB
                rts
