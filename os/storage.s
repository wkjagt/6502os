.include "storage.inc"
.include "zeropage.inc"
.include "via.inc"
.include "file.inc"
.include "i2c.inc"
.include "jump_table.inc"

.importzp current_drive

.zeropage
stor_eeprom_i2c_addr:   .res 1
stor_eeprom_addr_l:     .res 1
stor_eeprom_addr_h:     .res 1
stor_ram_addr_l:        .res 1
stor_ram_addr_h:        .res 1

.code

init_storage:   stz     current_drive

                ; todo: move this elsewhere
                lda     #1
                sta     dir_page
                jsr     load_fat
                jsr     load_dir
                rts

;===========================================================================
; read multiple pages from EEPROM into RAM.
; Uses:
;    - current_drive:      0-3. Used to determine the i2c address
;    - x:                  numbers of pages to read from EEPROM
;    - stor_ram_addr_h:    page in RAM to start writing data to
;    - stor_eeprom_addr_h: page in EEPROM to start reading data from
;===========================================================================
read_pages:     jsr     read_page
                inc     stor_ram_addr_h         ; next RAM page
                inc     stor_eeprom_addr_h      ; next EEPROM page
                dex
                bne     read_pages
                rts

;===========================================================================
; read one pages from EEPROM into RAM.
; Uses:
;    - current_drive:      0-3. Used to determine the i2c address
;    - stor_ram_addr_h:    page in RAM write data to
;    - stor_eeprom_addr_h: page in EEPROM to read data from
;===========================================================================
read_page:      pha
                phy
                phx

                ldx     current_drive
                lda     drive_to_ic2addr, X
                sta     stor_eeprom_i2c_addr

                stz     stor_ram_addr_l
                stz     stor_eeprom_addr_l
                jsr     read_sequence

                lda     #128
                sta     stor_ram_addr_l
                sta     stor_eeprom_addr_l
                jsr     read_sequence

                plx
                ply
                pla
                rts

;===========================================================================
; write multiple pages from RAM to EEPROM.
; Uses:
;    - current_drive:      0-3. Used to determine the i2c address
;    - x:                  numbers of pages to write to EEPROM
;    - stor_ram_addr_h:    page in RAM to start reading data from
;    - stor_eeprom_addr_h: page in EEPROM to start writing data to
; TODO: adapt this routine to use write_page
;===========================================================================
write_pages:    jsr     write_page
                inc     stor_ram_addr_h         ; next RAM page
                inc     stor_eeprom_addr_h      ; next EEPROM page
                dex
                bne     write_pages
                rts

;===========================================================================
; write one page from RAM to EEPROM.
; Uses:
;    - current_drive:      0-3. Used to determine the i2c address
;    - stor_ram_addr_h:    page in RAM to start reading data from
;    - stor_eeprom_addr_h: page in EEPROM to start writing data to
;===========================================================================
write_page:     pha
                phy
                phx


                ldx     current_drive
                lda     drive_to_ic2addr, X
                sta     stor_eeprom_i2c_addr

                stz     stor_ram_addr_l
                stz     stor_eeprom_addr_l
                jsr     write_sequence

                lda     #128
                sta     stor_ram_addr_l
                sta     stor_eeprom_addr_l
                jsr     write_sequence

                plx
                ply
                pla
                rts

;=================================================================================
;               PRIVATE ROUTINES
;=================================================================================

;=================================================================================
; Write a sequence of bytes to the EEPROM
write_sequence: jsr     init_access

                ; send 128 bytes
                ldy     #0              ; start at 0
@byte_loop:     lda     (stor_ram_addr_l),y
                jsr     i2c_send_byte
                iny
                cpy     #128            ; compare with string lengths in TMP1
                bne     @byte_loop
                jsr     i2c_stop

                ; 3. ack on eeprom is by sending the control byte again
@ack_loop:      jsr     i2c_start
                lda     stor_eeprom_i2c_addr
                clc
                jsr     i2c_send_addr
                bcs     @ack_loop
                rts

;=================================================================================
; Read a sequence of bytes from the EEPROM
read_sequence:  phx
                jsr     init_access

                jsr     i2c_start
                lda     stor_eeprom_i2c_addr
                sec                     ; read
                jsr     i2c_send_addr

                ldy     #0
@byte_loop:     jsr     i2c_read_byte
                sta     (stor_ram_addr_l),y  ; store the byte
                iny
                cpy     #128
                beq     @done           ; no ack for last byte, as per the datasheet
                jsr     i2c_send_ack
                jmp     @byte_loop
@done:          jsr     i2c_stop
                plx
                rts

init_access:    jsr     i2c_start
                
                ; 1. send control byte
                lda     stor_eeprom_i2c_addr
                clc                     ; write
                jsr     i2c_send_addr
                
                ; 2. send address in eeprom to use
                jsr     set_address
                rts
;=================================================================================
; This sets the address in the EEPROM, that is then used by the read or write
; that follows. It uses the write mode, regardless if the operation that follows
; is a read or write.
;=================================================================================
set_address:    lda     stor_eeprom_addr_h
                jsr     i2c_send_byte
                lda     stor_eeprom_addr_l
                jsr     i2c_send_byte
                rts

drive_to_ic2addr:
                .byte   $50, $51, $54, $55
