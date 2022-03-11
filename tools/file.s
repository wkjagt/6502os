.include "../os/pager_os.inc"
.include "file.inc"

.zeropage
tmp_string:     .res 2

.code
;============================================================
;               Show the directory
;============================================================
show_dir:       stz     dir_page
@next_page:     inc     dir_page
                jsr     load_dir        ; load dir page into buffer
                jsr     output_dir
                lda     dir_page
                cmp     #4
                bne     @next_page
@done:          rts

output_dir:     ldx     #0
@next_item:     lda     DIR_BUFFER,x    ; first char of filename. If 0: empty entry
                beq     @skip

                jsr     print_file_name

                prn     "  ("
                lda     DIR_BUFFER+9,x
                jsr     JMP_PRINT_HEX
                prn     ")"

                putc LF             ; todo: in ROM replace with cr routine
                putc CR
@skip:          txa
                clc
                adc     #16
                beq     @done
                tax
                bra     @next_item      ; if 0: end of page
@done:          rts


format:         jsr     clear_fat
                jsr     clear_dir
                jsr     load_fat
                jsr     load_dir
                rts