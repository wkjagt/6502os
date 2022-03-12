.include "file.inc"
.include "jump_table.inc"
.include "zeropage.inc"
.include "zeropage.inc"
.include "strings.inc"
.include "screen.inc"
.include "xmodem.inc"                   ; todo: remove this dependency

.import __INPUTBFR_START__

drive_page      = stor_eeprom_addr_h 
ram_page        = stor_ram_addr_h
READ_PAGE       = JMP_STOR_READ_PAGE
WRITE_PAGE      = JMP_STOR_WRITE_PAGE

.zeropage
dir_page:       .res 1
next_empty_page:.res 1
error_code:     .res 1

.code

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*******************************************************************************
;               FILE RELATED ROUTINES
;*******************************************************************************
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
save_file:      rts

;===========================================================================
;               Load file
;===========================================================================
load_file:      jsr     find_file
                bcs     @not_found
                lda     DIR_BUFFER+8,x  ; start page

                sta     drive_page      ; read from dir/fat
                lda     #6              ; default start page, todo: don't hardcode
                sta     ram_page
                
@next_page:     jsr     READ_PAGE

                ldx     drive_page
                lda     FAT_BUFFER,x    ; next page
                cmp     #$FF            ; last page, todo: use constant
                beq     @done

                sta     drive_page
                inc     ram_page
                bra     @next_page
@not_found:     lda     #ERR_FILE_NOT_FOUND
                sta     error_code
                sec
                rts
@done:          clc                     ; success
                rts

;===========================================================================
;               Find a file in the directory buffer
;               When the file is found, carry is clear
;               and the X register points to the start of the entry.
;               When the file is not found, carry is set, and X
;               should be ignored.
;===========================================================================
find_file:      stz     dir_page
@next_page:     inc     dir_page        ; set next dir page
                jsr     JMP_LOAD_DIR    ; load dir page into buffer
                jsr     @find_in_page
                bcc     @done
                lda     dir_page
                cmp     #4
                bne     @next_page
@done:          rts
@find_in_page:  ldx     #0
@loop:          jsr     match_filename
                bcc     @found          ; carry clear means file found
                txa
                clc
                adc     #16
                tax
                bne     @loop
                sec                     ; set carry to signal file not found
@found:         rts

; x: pointer to start of dir entry in RAM
; return:
;     carry set:   no match
;     carry clear: matched
match_filename: phx
                phy
                ldy     #0
@loop:          lda    DIR_BUFFER,x
                cmp    __INPUTBFR_START__,y
                bne    @no_match
                inx
                iny
                cpy     #MAX_FILE_NAME_LEN
                bne     @loop
                clc                     ; matched
                bra     @done
@no_match:      sec
@done:          ply
                plx
                rts


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
;               Load the current DIR page from the drive into RAM.
;===============================================================
load_dir:       jsr     dir_args
                jsr     READ_PAGE
                rts

;===============================================================
;               Save the current DIR page from RAM to the drive.
;===============================================================
save_dir:       phx                     ; todo: document why this is needed
                pha
                jsr     dir_args
                jsr     WRITE_PAGE
                pla
                plx
                rts

; private routine used by the two routines above
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

;============================================================
;               Show the contents of the directory of the
;               currently selected drive. Format:
;
;               filename (size in pages)
;============================================================
show_dir:       stz     dir_page
@next_page:     inc     dir_page
                jsr     load_dir        ; load dir page into buffer
                jsr     output_dir
                lda     dir_page
                cmp     #4              ; todo: use constant
                bne     @next_page
@done:          rts

output_dir:     ldx     #0
@next_item:     lda     DIR_BUFFER,x    ; first char of filename. If 0: empty entry
                beq     @skip

                jsr     print_file_name

                prn     "  ("
                lda     DIR_BUFFER+9,x  ; todo: use constant
                jsr     JMP_PRINT_HEX
                prn     ")"

                putc    LF
                putc    CR
@skip:          txa
                clc
                adc     #16
                beq     @done
                tax
                bra     @next_item      ; if 0: end of page
@done:          rts

;===============================================================
;               Add a file to the directory
;               X contains the start of the first free dir entry
;                 in page 5 (ie 32 for the 3rd entry)
;               The inputbuffer is used to read a filename
;               next_empty_page was initialized by load_fat to point
;               to the next empry page that can be written to
;
;               NOTE: this only interacts with the DIR buffer
;               currently in RAM. It doesn't need to know anything
;               about multiple DIR pages in a drive, because 
;               find_empty_dir is called first and sets X and dir_page
;===============================================================
add_to_dir:     ldy     #0
                phx                     ; keep this for a bit later when we save the page number
@loop:          lda     __INPUTBFR_START__,y
                sta     DIR_BUFFER,x
                inx
                iny
                cpy     #MAX_FILE_NAME_LEN + 1
                bne     @loop
                plx                     ; the index to the start of the entry
                lda     next_empty_page ; pointer to the first page where the file will be saved
                sta     DIR_BUFFER+8,x  ; todo: constant for first page offset
                lda     rcv_page_count  ; save the size in byte 9 of the dir entry
                sta     DIR_BUFFER+9,x  ; todo: constant for size offset
                rts

;============================================================
;               Format the current drive by clearing the FAT
;               and the directory.
;============================================================
format_drive:   jsr     clear_fat
                jsr     clear_dir
                jsr     load_fat
                jsr     load_dir
                rts