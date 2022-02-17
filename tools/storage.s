.include "storage.inc"
.include "terminal.inc"
.include "../os/zeropage.inc"           ; todo: remove once no longer needed
.include "../os/strings.inc"
.include "../os/jump_table.inc"

.import __INPUTBFR_START__              ; remove

.code
; arg 1: page count
; arg 2: drive page
; arg 3: ram page
; Ie "Load 3 pages from drive page 0 to RAM page 1A"
; `load 03 00 1A`
load:           ldx     TERM_ARG1
                lda     TERM_ARG2
                sta     stor_eeprom_addr_h
                lda     TERM_ARG3
                sta     stor_ram_addr_h
                jmp     JMP_STOR_READ

; arg 1: page count
; arg 2: ram page
; arg 3: drive page
; Ie "Save 3 pages from RAM page 1A to drive page 0"
; `save 03 1A 00`
save:           ldx     TERM_ARG1
                lda     TERM_ARG2
                sta     stor_ram_addr_h
                lda     TERM_ARG3
                sta     stor_eeprom_addr_h
                jmp     JMP_STOR_WRITE

set_drive0:     lda     #0              ; todo: use arguments for this
                bra     set_drive
set_drive1:     lda     #1
                bra     set_drive
set_drive2:     lda     #2
                bra     set_drive
set_drive3:     lda     #3
set_drive:      sta     current_drive
                rts