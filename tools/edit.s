.include "edit.inc"
.include "../os/jump_table.inc"
.include "../os/zeropage.inc"
.include "../os/strings.inc"
.include "../os/screen.inc"

.import __INPUTBFR_START__

.zeropage

cell:                   .res 1
active_page:            .res 2
input:                  .res 2
input_pointer:          .res 1
incomplete_entry:       .res 1          ; uses 1 bit only

.code

; The edit CLI command
edit:           clc
                lda     #<__INPUTBFR_START__    ; todo: move this to terminal parse logic
                adc     param_index     ; calculate the start of the param
                
                jsr     hex_to_byte     ; this puts the page number in A
                jsr     edit_page
                rts


;========================================================================
;        EDIT A PAGE
; 
; A: the page to edit
;========================================================================
edit_page:      stz     active_page
                sta     active_page+1
@restart:       stz     cell
@reload:        jsr     reset_input
                jsr     JMP_INIT_SCREEN
                lda     active_page+1
                jsr     JMP_DUMP        ; use dump as data view
                jsr     set_cursor
@next_key:      jsr     JMP_GETC
                tax                     ; puts pressed char in X

@cmp_right:     cpx     #RIGHT
                bne     @cmp_left
                lda     #1
                jsr     update_cell
                jmp     @next_key

@cmp_left:      cpx     #LEFT
                bne     @cmp_up
                lda     #$ff            ; -1
                jsr     update_cell
                jmp     @next_key

@cmp_up:        cpx     #UP
                bne     @cmp_down
                lda     #$f0            ; -16
                jsr     update_cell
                jmp     @next_key

@cmp_down:      cpx     #DOWN
                bne     @cmp_hex
                lda     #16
                jsr     update_cell
                jmp     @next_key
                
@cmp_hex:       cpx     #'0'
                bcc     @check_save
                cpx     #':'            ; next ascii after 9
                bcs     @capital
                txa
                jsr     hex_input
                jmp     @next_key
@capital:       cpx     #'A'
                bcc     @check_save
                cpx     #'G'
                bcs     @letter
                txa
                jsr     hex_input
                jmp     @next_key
@letter:        cpx     #'a'
                bcc     @check_save
                cpx     #'g'
                bcs     @check_save
                txa
                sec
                sbc     #32             ; make capital letter
                jsr     hex_input
                jmp     @next_key

@check_save:    cpx     #LF
                bne     @check_esc
                lda     incomplete_entry
                bne     @next
                lda     #input
                jsr     hex_to_byte     ; byte into A
                ldy     cell
                sta     (active_page), y
                jsr     reset_input
                jsr     JMP_INIT_SCREEN
                lda     active_page+1
                jsr     JMP_DUMP
                lda     #1
                jsr     update_cell
                jmp     @next_key

@check_esc:     cpx     #ESC
                bne     @check_exit
                jmp     @reload

@check_exit:    cpx     #'q'
                beq     @exit

@check_pgup:    cpx     #PGUP
                bne     @check_pgdn
                dec     active_page+1
                jmp     @restart

@check_pgdn:    cpx     #PGDN
                bne     @next
                inc     active_page+1
                jmp     @restart

@next:          jmp     @next_key

@exit:          jsr     JMP_INIT_SCREEN
                rts
; ================================================================================
;      A hex nibble was input. treat it here
; ================================================================================
hex_input:      ldx     input_pointer
                sta     input,x         ; store char in input and
                jsr     JMP_PUTC        ; overwrite the char on screen
                cpx     #1
                beq     @last_pos
                putc    '_'
                jsr     cursor_left
                inc     input_pointer
                rts
@last_pos:      jsr     cursor_left
                stz     incomplete_entry
                rts

reset_input:    stz     input
                stz     input+1
                stz     input_pointer
                lda     #1
                sta     incomplete_entry
                rts

update_cell:    beq     @no_adj
                jsr     set_cursor

                pha
                ldy     cell            ; cell before moving
                lda     (active_page),y
                jsr     JMP_PRINT_HEX
                pla

                sta     tmp1
                clc
                lda     cell
                adc     tmp1
                sta     cell
@no_adj:        jsr     reset_input     ; fall through to set_cursor


set_cursor:     pha
                jsr     cursor_home
                jsr     cursor_down
                ldx     #6
@to_start:      jsr     cursor_right
                dex
                bne     @to_start

@hor_adjust:    lda     cell
                and     #LOW_NIBBLE      ; only keep low nibble
                tax
                beq     @ver_adjust
@right:         jsr     cursor_right
                jsr     cursor_right
                jsr     cursor_right
                dex
                bne     @right

                ; if we're at the right of the separation, we need to move one
                ; more position to the right. 
                lda     cell
                and     #%00001000      ; on the right side, bit 3 is always set
                beq     @ver_adjust
                jsr     cursor_right

@ver_adjust:    lda     cell
                lsr                     ; only keep high nibble
                lsr
                lsr
                lsr
                tax
                beq     @done
@down:          jsr     cursor_down
                dex
                bne     @down
@done:          pla
                rts