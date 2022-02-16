.include "storage.inc"
.include "terminal.inc"
.include "../os/zeropage.inc"           ; todo: remove once no longer needed
.include "../os/strings.inc"
.include "../os/jump_table.inc"

.import __INPUTBFR_START__              ; remove

.code
; ex: `load 00 04` means load 4 pages from eeprom, starting at page 0
                ; page arg
load:           jsr     load_save_args
                jmp     JMP_STOR_READ
save:           jsr     load_save_args
                jmp     JMP_STOR_WRITE

load_save_args: lda     TERM_ARG1
                sta     stor_eeprom_addr_h
                ldx     TERM_ARG2
                rts

set_drive0:     lda     #0
                bra     set_drive
set_drive1:     lda     #1
                bra     set_drive
set_drive2:     lda     #2
                bra     set_drive
set_drive3:     lda     #3
set_drive:      sta     current_drive
                rts