.include "storage.inc"
.include "terminal.inc"
.include "../os/pager_os.inc"


.code

load:           jsr     get_args
                jmp     JMP_STOR_READ

save:           jsr     get_args
                jmp     JMP_STOR_WRITE

get_args:       ldx     TERM_ARG1
                bne     @count_given
                ldx     #1              ; 1 page by default todo: don't hardcode this here
@count_given:   lda     TERM_ARG2
                sta     stor_eeprom_addr_h  ; 0 is the default so no need to check
                lda     TERM_ARG3
                bne     @ram_page_given
                lda     #4              ; page 4 by default todo: don't hardcode this here
@ram_page_given:sta     stor_ram_addr_h
                rts

set_drive0:     lda     #0              ; todo: use arguments for this
                bra     set_drive
set_drive1:     lda     #1
                bra     set_drive
set_drive2:     lda     #2
                bra     set_drive
set_drive3:     lda     #3
set_drive:      sta     current_drive
                jsr     load_fat
                jsr     load_dir
                rts