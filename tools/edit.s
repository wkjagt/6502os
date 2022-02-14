.include "edit.inc"
.include "../os/jump_table.inc"
.include "../os/zeropage.inc"
.include "../os/strings.inc"
.include "../os/screen.inc"

.zeropage

cell:                   .res 1
active_page:            .res 2
input:                  .res 2
input_pointer:          .res 1
incomplete_entry:       .res 1          ; uses 1 bit only

.code
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
                lda     cell
                and     #LOW_NIBBLE     ; in rightmost column the four last bits are always set
                cmp     #LOW_NIBBLE
                beq     @next_key
                lda     #1
                jsr     update_cell
                jmp     @next_key

@cmp_left:      cpx     #LEFT
                bne     @cmp_up
                lda     cell
                and     #LOW_NIBBLE     ; ignore the 4 highest bits
                beq     @next_key            ; last 4 bits need to have something set
                lda     #$ff            ; -1
                jsr     update_cell
                jmp     @next_key

@cmp_up:        cpx     #UP
                bne     @cmp_down
                lda     cell
                and     #HIGH_NIBBLE    ; for the top row the high nibble is always 0
                beq     @next_key
                lda     #$f0            ; -16
                jsr     update_cell
                jmp     @next_key

@cmp_down:      cpx     #DOWN
                bne     @cmp_hex
                lda     cell
                and     #HIGH_NIBBLE    ; for the bottom row, the high nibble is always 1111
                cmp     #HIGH_NIBBLE
                beq     @next_key
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

@check_save:    cpx     #'s'
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
                jsr     set_cursor
                jmp     @next_key

@check_esc:     cpx     #ESC
                bne     @check_exit
                jmp     @reload

@check_exit:    cpx     #'q'
                beq     @exit

@check_pgup:    cpx     #PGUP
                bne     @check_pgdn
                inc     active_page+1
                jmp     @restart

@check_pgdn:    cpx     #PGDN
                bne     @next
                dec     active_page+1
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
                lda     #'_'
                jsr     JMP_PUTC
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


; cursor_home:    lda     #$01
;                 jsr     JMP_PUTC
;                 rts
; cursor_right:   lda     #$1C
;                 jsr     JMP_PUTC
;                 rts
; cursor_left:    lda     #$1D
;                 jsr     JMP_PUTC
;                 rts
; cursor_down:    lda     #$1F
;                 jsr     JMP_PUTC
;                 rts