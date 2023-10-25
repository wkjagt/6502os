.include "screen.inc"
.include "via.inc"
.include "jump_table.inc"
.include "output.inc"

.code
                ; Set up data pins to communicate with the screen controller
init_screen:    lda     VIA1_DDRA
                ora     #SCRN_OUT_PINS
                and     #(SCRN_OUT_PINS | SCRN_UNUSED)
                sta     VIA1_DDRA

                ; clear output pins
                lda     #(SCRN_DATA_PINS|SCRN_AVAILABLE)
                trb     VIA1_PORTA
                
                lda     #0
                jsr     set_output_dev

                jsr     clear_screen
                jsr     JMP_CURSOR_ON

                rts

screen_cout:    pha                     ; we pull off the arg 3 times, once for high
                pha                     ; nibble, once for low nibble and once to put
                pha                     ; back the original value

                lda     #SCRN_DATA_PINS; clear data
                trb     VIA1_PORTA

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


wait_ack_high:  pha
@loop:          lda     VIA1_PORTA
                and     #SCRN_ACK
                beq     @loop
                pla
                rts
wait_ack_low:   pha
@loop:          lda     VIA1_PORTA
                and     #SCRN_ACK
                bne     @loop
                pla
                rts

cursor_on:      putc    CHOOSE_CURSOR
                putc    CURSOR_CHAR
                putc    CURSOR_BLINK
                rts

cursor_off:     putc    CHOOSE_CURSOR
                putc    ' '
                putc    CURSOR_SOLID
                rts

clear_screen:   putc    CLEAR_SCREEN
                rts

cursor_home:    putc    CURSOR_HOME
                rts

cursor_right:   putc    CURSOR_RIGHT
                rts

cursor_left:    putc    CURSOR_LEFT
                rts

cursor_up:      putc    CURSOR_UP
                rts

cursor_down:    putc    CURSOR_DOWN
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
