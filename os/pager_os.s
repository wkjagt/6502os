.include "jump_table.inc"
.include "strings.inc"
.include "keyboard.inc"
.include "screen.inc"
.include "acia.inc"
.include "zeropage.inc"
.include "storage.inc"
.include "input.inc"
.include "file.inc"
.include "graphic_screen.inc"
.include "timer.inc"
.include "../tools/edit.inc"
.include "../tools/terminal.inc"
.include "../tools/receive.inc"
.export reset
.import xmodem_receive
.import __PROGRAM_START__
.import __PROGRAM_SIZE__

PROGRAM_LAST_PAGE = __PROGRAM_START__ + __PROGRAM_SIZE__ - 1

.code

reset:          sei                     ; no interrupts, but user programs can enable them
                ldx     #$ff
                txs

clear_zeropage: ldx     #0
@loop:          stz     0,x             ; clear 0 page
                stz     1,x             ; clear stack
                inx
                bne     @loop

copy_jumptable: ldx     #(end_jump_table-jump_table)
@loop:          lda     jump_table,x
                sta     __JUMPTABLE_START__,x
                dex
                cpx     #$ff            ; ugly. is there a better way?
                bne     @loop

                jsr     JMP_INIT_SCREEN
                jsr     JMP_INIT_GRAPHIC_SCREEN

                prn     "Starting OkaDOS.",1
                cr

                prn     "Initializing RAM... "
                jsr     clear_ram
                prn     "OK.", 1
                                
                prn     "Initializing keyboard... "
                jsr     JMP_INIT_KB
                prn     "OK.", 1
                
                prn     "Initializing serial port... "
                jsr     JMP_INIT_SERIAL
                prn     "OK.", 1

                prn     "Initializing storage... "
                jsr     JMP_INIT_STORAGE
                prn     "OK.", 1

                prn     "Initializing timer... "
                jsr     init_timer
                prn     "OK.", 1

                cr
                prn     "Ready.",1
                cr

                jsr     terminal
                jmp     reset

clear_ram:      stz     tmp1            ; low byte, always 0, index into it using y
                lda     #>PROGRAM_LAST_PAGE
                sta     tmp1+1          ; page number of first page after RAM

                ldy     #0

@page_loop:     dec     tmp1+1          ; previous RAM page
@loop:          lda     #0
                sta     (tmp1), y
                iny
                bne     @loop

                lda     tmp1+1
                cmp     #>__PROGRAM_START__
                bne     @page_loop
                rts

irq:            jsr     inc_timer
                jmp     JMP_IRQ_HANDLER
nmi:            jmp     JMP_NMI_HANDLER
irqnmi:         rti

; This jump table isn't used at this location. These are default values
; That are copied to the JUMPTABLE segment in RAM on reset, and can be overriden
; from user software.
; todo: move to jumptable.s
jump_table:     ; todo: remove all non OS things
                jmp     receive
                jmp     init_screen
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
                jmp     load_fat
                jmp     clear_fat
                jmp     find_empty_page
                jmp     clear_dir
                jmp     load_dir
                jmp     save_dir
                jmp     show_dir
                jmp     format_drive
                jmp     print_string
                jmp     add_to_dir
                jmp     find_empty_dir
                jmp     delete_dir
                jmp     delete_file
                jmp     save_fat
                jmp     find_file
                jmp     vdp_init
                jmp     vdp_sprite_pattern_table_write
                jmp     vdp_pattern_table_write
                jmp     vdp_color_table_write
                jmp     graphics_on
end_jump_table:

.segment "VECTORS"

                .word   nmi
                .word   reset
                .word   irq