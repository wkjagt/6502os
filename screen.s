                .import VIA1_DDRA
                .import VIA1_PORTA

                .export init_screen
                .export send_byte_to_screen


CLEAR_SCREEN    =       $0c
CHOOSE_CURSOR   =       2               ; choose cursor command to screen
CURSOR_CHAR     =       $db             ; solid block
CURSOR_BLINK    =       3

SCRN_DATA_PINS  =       %11110000       ; In 4 bit mode: send 4 bits of data at a time
SCRN_AVAILABLE  =       %00000100       ; To tell the screen that new data is available
SCRN_ACK        =       %00001000       ; Input pin for the screen to ack the data
SCRN_OUT_PINS   =       SCRN_DATA_PINS | SCRN_AVAILABLE
SCRN_UNUSED     =       %00000011       ; unused pins on this port

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

                lda     #CLEAR_SCREEN
                jsr     send_byte_to_screen
                lda     #CHOOSE_CURSOR
                jsr     send_byte_to_screen
                lda     #CURSOR_CHAR
                jsr     send_byte_to_screen
                lda     #CURSOR_BLINK
                jsr     send_byte_to_screen

                rts

send_byte_to_screen:
                pha                     ; we pull off the arg twice, once for high
                pha                     ; nibble and once for low nibble

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