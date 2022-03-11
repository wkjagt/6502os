.include "jump_table.inc"
.include "file.inc"
.include "zeropage.inc"
.include "zeropage.inc"

drive_page      = stor_eeprom_addr_h 
ram_page        = stor_ram_addr_h
READ_PAGE       = JMP_STOR_READ_PAGE
WRITE_PAGE      = JMP_STOR_WRITE_PAGE

.zeropage
dir_page:       .res 1
next_empty_page:.res 1

.code
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*******************************************************************************
;               FAT RELATED ROUTINES
;*******************************************************************************
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;============================================================
;               Clear the FAT
;============================================================
clear_fat:      ldx     #0
@clear_buffer:  stz     FAT_BUFFER,x
                inx
                bne     @clear_buffer

                ; don't make the first 5 pages available
                lda     #$FF
                sta     FAT_BUFFER+0    ; FAT
                sta     FAT_BUFFER+1    ; DIR 1
                sta     FAT_BUFFER+2    ; DIR 2
                sta     FAT_BUFFER+3    ; DIR 3
                sta     FAT_BUFFER+4    ; DIR 4

                ; write this new clear FAT buffer from RAM to the drive
                stz     drive_page      ; page 0 in eeprom
                lda     #>FAT_BUFFER
                sta     ram_page        ; where we stored the 0s
                jsr     WRITE_PAGE
                rts

;============================================================
;               Load FAT into RAM
;============================================================
load_fat:       phx
                pha
                stz     drive_page      ; page 0 in eeprom
                lda     #>FAT_BUFFER
                sta     ram_page        ; where we stored the 0s
                jsr     READ_PAGE

                ; set the current page to the first empty page
                jsr     find_empty_page
                sta     next_empty_page

                pla
                plx
                rts

;============================================================
;               Find the next empty page in the FAT
;               Puts the page number in A
;============================================================
find_empty_page:phx
                ldx     #0
@loop:          lda     FAT_BUFFER,x
                beq     found
                inx
                bra     @loop
found:          txa
                plx
                rts


;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*******************************************************************************
;               DIR RELATED ROUTINES
;*******************************************************************************
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;============================================================
;               Clear the whole directory
;               Used when formatting a drive
;============================================================
clear_dir:      ldx     #0
@clear_buffer:  stz     DIR_BUFFER,x
                inx
                bne     @clear_buffer

                ldy     #4              ; dir takes up 4 pages
@clear_page:    sty     drive_page
                lda     #>DIR_BUFFER
                sta     ram_page
                jsr     WRITE_PAGE
                dey
                bne     @clear_page     ; don't do page 0 because that's FAT
                rts

;===============================================================
;               Load a page from one of the 4 DIR pages of
;               the directory into RAM.
;===============================================================
load_dir:       jsr     dir_args
                jsr     READ_PAGE
                rts

save_dir:       phx                     ; todo: document why this is needed
                pha
                jsr     dir_args
                jsr     WRITE_PAGE
                pla
                plx
                rts

dir_args:       lda     dir_page
                sta     drive_page
                lda     #>DIR_BUFFER
                sta     ram_page        ; where we stored the 0s
                rts

;============================================================
;               Print the file name in the directory at
;               index X
;============================================================
print_file_name:phx
                ldy     #MAX_FILE_NAME_LEN
@next_char:     lda     DIR_BUFFER,x
                bne     @not_a_space    ; spaces are decoded as 0s
                lda     #' '
@not_a_space:   jsr     JMP_PUTC
                inx
                dey
                bne     @next_char
                plx
                rts