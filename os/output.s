.include "output.inc"
.include "screen.inc"
.include "lcd.inc"

.zeropage
output_dev:     .res 2

.code

set_output_dev: phx
                asl     a
                tax
                lda     output_devs,x
                sta     output_dev
                inx
                lda     output_devs,x
                sta     output_dev+1
                plx
                rts

cout:           jmp     (output_dev)


output_devs:    .word   putchar, lcd_putc