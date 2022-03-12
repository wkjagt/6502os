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
load_size       = rcv_page_count
load_page       = rcv_start_page
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
                jsr     load_dir    ; load dir page into buffer
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

;===========================================================================
;               Delete a file. This doesn't delete the actual data.
;               It only frees up the entries in the directory and the
;               FAT so the pages can be reused.
;===========================================================================
delete_file:    jsr     find_file
                bcs     @not_found
                lda     DIR_BUFFER+8,x  ; load start page from directory entry
                jsr     delete_dir
@loop:          tax                     ; A contains the FAT page number
                lda     FAT_BUFFER,x
                stz     FAT_BUFFER,x    ; overwrite the page entry with a 0
                cmp     #LAST_PAGE      ; see if A (the page number)
                beq     @done
                bra     @loop
@not_found:     lda     #ERR_FILE_NOT_FOUND
                sta     error_code
                sec
                rts
@done:          jsr     save_dir
                jsr     save_fat
                clc
                rts

;====================================================================================
;               Save a new file to EEPROM
;               Start reading from RAM at page held at load_page
;               Read number of pages held at load_size
;               The filename is taken from the input buffer
;====================================================================================
save_file:      jsr     find_file       ; to see if it exists already
                bcc     @file_exists    ; carry clear means file was found
                jsr     find_empty_dir  ; x contains entry index
                bcs     @dir_full       ; carry clear means empty spot was found
                
                jsr     add_to_dir      ; save the file to the directory
                
                ldy     load_size       ; the size of the file that was received over xmodem
                ldx     load_page
@save_page:     lda     next_empty_page ; pointer to the next empty page in the eeprom
                sta     drive_page      ; used by the storage routine as target page
                stx     ram_page        ; used by the storage routine as source page

                jsr     WRITE_PAGE      ; write the page

                lda     #LAST_PAGE      ; mark the page that was just written to as the last page of the file
                phx
                ldx     next_empty_page ; in the FAT for now. If it's not, it'll be overwritten after. But for
                sta     FAT_BUFFER,x    ; now we want to avoid find_empty_page to still see it as empty.
                plx

                dey                     ; keep track of how many pages are left to save
                beq     @done

                inx
                jsr     find_empty_page ; find the next available page in the EEPROM
                phx
                ldx     next_empty_page  
                sta     FAT_BUFFER,x    ; current page in FAT points to next avail page
                plx
                sta     next_empty_page ; update the current page pointer for the next loop

                bra     @save_page
@done:          jsr     save_fat        ; all done, save the updated FAT back to the EEPROM
                jsr     save_dir        ; save the updated directory
                clc                     ; success
                rts
@file_exists:   lda     #ERR_FILE_EXISTS
                sta     error_code
                sec
                rts
@dir_full:      lda     #ERR_DIR_FULL
                sta     error_code
                sec
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
;               Save updated FAT to the drive
;               This saves page 4 in RAM (the FAT buffer) to
;               page 0 on the EEPROM (where the FAT is stored)
;============================================================
save_fat:       phx
                pha
                stz     drive_page      ; page 0 in eeprom
                lda     #>FAT_BUFFER
                sta     ram_page
                jsr     WRITE_PAGE

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


;===============================================================
;               Find an empty spot in the directory
;               This traverses all 4 directory pages,
;               loading each into RAM, until it finds
;               an emptry entry.
;               It leaves the carry flag clear if an entry is found,
;               or set when no entry is found.
;               TODO: can we reuse find_file with an empty file name?
;===============================================================
find_empty_dir: stz     dir_page
@next_page:     inc     dir_page        ; set next dir page
                jsr     load_dir    ; load dir page into buffer
                jsr     @find_in_page
                bcc     @done
                lda     dir_page
                cmp     #4              ; todo: constant for dir page count
                bne     @next_page
@done:          rts

@find_in_page:  ldx     #0
@next_entry:    lda     DIR_BUFFER,x
                beq     @in_page
                txa
                clc
                adc     #16             ; todo: constant for dir entry length
                tax
                beq     @not_in_page
                bra     @next_entry
@in_page:       clc                     ; "found" flag
                rts
@not_in_page:   sec
                rts

;===========================================================================
;               Delete an entry from the directory by overwriting the 16
;               bytes of the entry with 0s. The active directory page needs
;               to be set for this to work correctly
;               X: the index to the start of the entry which can be set
;               using find_file for example.
;
;               Overwrites X and Y
;===========================================================================
delete_dir:     ldy     #16             ; todo: replace with constant for entry length
@loop:          stz     DIR_BUFFER,x
                inx
                dey
                bne     @loop
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
show_dir:       prn     "name     start     pages",1
                prn     "------------------------"
                stz     dir_page
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

                cr
                jsr     print_file_name
                prn     " "
                lda     DIR_BUFFER+8,x  ; todo: use constant
                jsr     JMP_PRINT_HEX
                prn     "        "
                lda     DIR_BUFFER+9,x  ; todo: use constant
                jsr     JMP_PRINT_HEX



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