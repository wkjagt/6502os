.include "storage.inc"
.include "terminal.inc"
.include "../os/pager_os.inc"


.code

load:           lda     TERM_ARG1
                bne     @using_pages
                
                prn     " Filename: "
                jsr     JMP_GET_INPUT
                jsr     load_file
                bcc     @found
                cr
                prn     "Not found", 1
@found:         rts
@using_pages:   jsr     get_page_args
                jmp     JMP_STOR_READ

save:           lda     TERM_ARG1
                bne     @using_pages
                prn     " Filename: "
                jsr     JMP_GET_INPUT
                jmp     save_file
@using_pages:   jsr     get_page_args
                jmp     JMP_STOR_WRITE

;=======================================================================
;               These are page related args, that are used when load
;               and save are used with hex args, in the following order:
;                   - page count
;                   - drive page
;                   - RAM page
;=======================================================================

get_page_args:  ldx     TERM_ARG1
                lda     TERM_ARG2
                sta     stor_eeprom_addr_h  ; 0 is the default so no need to check
                lda     TERM_ARG3
                bne     @ram_page_given
                lda     #6              ; page 4 by default todo: don't hardcode this here
@ram_page_given:sta     stor_ram_addr_h
                rts



;======================================================
;               Routines to set the current drive
;======================================================
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