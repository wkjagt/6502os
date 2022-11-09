.include "via.inc"
.include "timer.inc"

.zeropage

ticks:                  .res 4

.code


init_timer:     lda     #VIA_ACR_TIMER1_FREE_RUN
                sta     VIA1_ACR
                lda     #$0e            ; every 10ms @ 1Mhz
                sta     VIA1_T1CL
                lda     #$27
                sta     VIA1_T1CH
                lda     #(VIA_IER_SET | VIA_IER_TIMER1)
                sta     VIA1_IER
                stz     ticks
                stz     ticks + 1
                stz     ticks + 2
                stz     ticks + 3
                cli
                rts

inc_timer:      bit     VIA1_T1CL            ; clear T1 interrupt
                inc     ticks
                bne     @done
                inc     ticks + 1
                bne     @done
                inc     ticks + 2
                bne     @done
                inc     ticks + 3
@done:          rts                
