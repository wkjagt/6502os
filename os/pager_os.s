.include "jump_table.inc"
.include "strings.inc"
.include "keyboard.inc"
.include "screen.inc"
.include "acia.inc"
.include "zeropage.inc"
.include "storage.inc"
.include "input.inc"
.include "../tools/edit.inc"
.include "../tools/terminal.inc"
.include "../tools/receive.inc"

.import xmodem_receive
.import __INPUTBFR_START__

.code

reset:          sei                     ; no interrupts, but user programs can enable them
                ldx     #$ff
                txs
clear_ram:      stz     tmp1            ; low byte, always 0, index into it using y
                stz     tmp1+1          ; high byte, start at last page of RAM
                ldy     #0
                lda     #0
@loop:          sta     (tmp1), y
                iny
                bne     @loop
                inc     tmp1+1
                bne     @loop
copy_jumptable: ldx     #(end_jump_table-jump_table)
@loop:          lda     jump_table,x
                sta     __JUMPTABLE_START__,x
                dex
                cpx     #$ff            ; ugly. is there a better way?
                bne     @loop

                jsr     JMP_INIT_SCREEN
                jsr     JMP_INIT_KB
                jsr     JMP_INIT_SERIAL
                jsr     JMP_INIT_STORAGE

                println STR_STARTUP

                jsr     terminal
                bra     reset

; Interrupt handlers don't do anything for now, but they jump 
; through the jump table so they can be overriden in software
irq:            jmp     JMP_IRQ_HANDLER
nmi:            jmp     JMP_NMI_HANDLER
irqnmi:         rti

; This jump table isn't used at this location. These are default values
; That are copied to the JUMPTABLE segment in RAM on reset, and can be overriden
; from user software.
jump_table:                             ; todo: remove all non OS things
                jmp     receive
                jmp     init_screen
                jmp     run
                jmp     reset
                jmp     putchar
                jmp     print_byte_as_hex
                jmp     xmodem_receive
                jmp     read_key
                jmp     init_keyboard
                jmp     terminal
                jmp     irqnmi
                jmp     irqnmi
                jmp     init_serial
                jmp     cursor_on
                jmp     cursor_off
                jmp     draw_pixel
                jmp     rmv_pixel
                jmp     init_storage
                jmp     read_pages
                jmp     write_pages
                jmp     read_page
                jmp     write_page
                jmp     get_input
                jmp     clear_input
end_jump_table:

.segment "VECTORS"

                .word   nmi
                .word   reset
                .word   irq