.include "screen.inc"
.include "via.inc"
.include "jump_table.inc"

.code

init_screen:
                ; Set up data pins to communicate with the screen controller
                lda     VIA1_DDRA
                ora     #SCRN_OUT_PINS
                and     #(SCRN_OUT_PINS | SCRN_UNUSED)
                sta     VIA1_DDRA

                ; start with all pins low. Not needed (maybe) but
                ; it's nice to start with clean outputs
                lda     VIA1_PORTA
                and     #SCRN_UNUSED
                sta     VIA1_PORTA
                
                jsr     clear_screen
                jsr     JMP_CURSOR_ON

                rts

putc:
                pha                     ; we pull off the arg 3 times, once for high
                pha                     ; nibble, once for low nibble and once to put
                pha                     ; back the original value

                lda     VIA1_PORTA
                and     #!SCRN_DATA_PINS; clear data
                sta     VIA1_PORTA

                jsr     wait_ack_low
                pla
                and     #%11110000      ; mask out low nibble
                ora     VIA1_PORTA
                sta     VIA1_PORTA

                ora     #SCRN_AVAILABLE ; flip available = high
                sta     VIA1_PORTA

                jsr     wait_ack_high

                and     #%00001111      ; clear data so we can ora with high nibble
                sta     VIA1_PORTA

                pla                     ; get the original byte back
                asl                     ; shift low nibble into high nibble
                asl                     
                asl
                asl                     

                ora     VIA1_PORTA
                sta     VIA1_PORTA

                and     #(SCRN_AVAILABLE ^ $FF)     ; flip available = low
                sta     VIA1_PORTA

                jsr     wait_ack_low
                pla
                rts


wait_ack_high:
                pha
@loop:
                lda     VIA1_PORTA
                and     #SCRN_ACK
                beq     @loop
                pla
                rts
wait_ack_low:
                pha
@loop:
                lda     VIA1_PORTA
                and     #SCRN_ACK
                bne     @loop
                pla
                rts

cursor_on:      lda     #CHOOSE_CURSOR
                jsr     JMP_PUTC
                lda     #CURSOR_CHAR
                jsr     JMP_PUTC
                lda     #CURSOR_BLINK
                jsr     JMP_PUTC
                rts

cursor_off:     lda     #CHOOSE_CURSOR
                jsr     JMP_PUTC
                lda     #' '
                jsr     JMP_PUTC
                lda     #CURSOR_SOLID
                jsr     JMP_PUTC
                rts

clear_screen:   lda     #CLEAR_SCREEN
                jsr     JMP_PUTC
                rts

draw_pixel:     lda     #DRAW_PIXEL
                bra     send_pixel
rmv_pixel:      lda     #RESET_PIXEL
send_pixel:     jsr     JMP_PUTC
                txa
                jsr     JMP_PUTC
                tya
                jsr     JMP_PUTC
                rts

