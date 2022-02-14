.include "storage.inc"
.include "zeropage.inc"
.include "via.inc"

.import __PROGRAM_START__

init_storage:   lda     VIA1_DDRA
                ora     #(DATA_PIN | CLOCK_PIN)
                sta     VIA1_DDRA
                stz     current_drive
                rts

read_pages:     pha
                phy
                phx
                
                ldx     current_drive
                lda     drive_to_eeprom_block, x
                sta     stor_eeprom_block
                
                plx                     ;page count
                lda     #>__PROGRAM_START__
                sta     stor_ram_addr_h

@next_page:     stz     stor_ram_addr_l
                stz     stor_eeprom_addr_l
                jsr     read_sequence

                lda     #128
                sta     stor_ram_addr_l
                sta     stor_eeprom_addr_l
                jsr     read_sequence

                inc     stor_ram_addr_h
                inc     stor_eeprom_addr_h
                dex
                bne     @next_page

                ply
                pla
                rts


write_pages:    pha
                phy
                phx
                
                ldx     current_drive
                lda     drive_to_eeprom_block, x
                sta     stor_eeprom_block
                
                plx                     ;page count
                lda     #>__PROGRAM_START__
                sta     stor_ram_addr_h

@next_page:     stz     stor_ram_addr_l
                stz     stor_eeprom_addr_l
                jsr     write_sequence

                lda     #128
                sta     stor_ram_addr_l
                sta     stor_eeprom_addr_l
                jsr     write_sequence

                inc     stor_ram_addr_h
                inc     stor_eeprom_addr_h
                dex
                bne     @next_page

                ply
                pla
                rts

;=================================================================================
;               PRIVATE ROUTINES
;=================================================================================

;=================================================================================
; Write a sequence of bytes to the EEPROM
write_sequence: jsr     _init_sequence
                ldy     #0              ; start at 0
@byte_loop:     lda     (stor_ram_addr_l),y
                jsr     transmit_byte
                iny
                cpy     #128            ; compare with string lengths in TMP1
                bne     @byte_loop
                jsr     _stop_cond

@ack_loop:      jsr     _init_write
                bcs     @ack_loop
                rts
;=================================================================================
; Read a sequence of bytes from the EEPROM
read_sequence:  phx
                jsr     _init_sequence
                jsr     _init_read

                ldy     #0
@byte_loop:     jsr     _data_in
                ldx     #8              ; bit counter, counts down to 0
@bit_loop:      jsr     _clock_high
                lda     VIA1_PORTA           ; the eeprom should output the next bit on the data line
                lsr                     ; shift the reveived bit onto the carry flag
                rol     stor_byte_in         ; shift the received bit into the the received byte
                jsr     _clock_low
                
                dex
                bne     @bit_loop       ; keep going until all 8 bits are shifted in

                lda     stor_byte_in
                sta     (stor_ram_addr_l),y  ; store the byte

                iny
                cpy     #128
                beq     @done           ; no ack for last byte, as per the datasheet

                ; ack the reception of the byte
                jsr     _data_out       ; set the data line as output so we can ackknowledge

                lda     VIA1_PORTA
                and     #(DATA_PIN^$FF) ; set data line low to ack
                sta     VIA1_PORTA

                jsr     _clock_high     ; strobe it into the EEPROM
                jsr     _clock_low

                jmp     @byte_loop
@done:          jsr     _data_out

                jsr     _stop_cond
                plx
                rts

;=================================================================================
; An init sequence starts a write mode and sets the address. This is also used
; when we want to read, in which case _init_read is called after this, which sets
; the EEPROM to read mode, starting the read at the address provided.
_init_sequence: jsr     _init_write
                lda     stor_eeprom_addr_h
                jsr     transmit_byte
                lda     stor_eeprom_addr_l
                jsr     transmit_byte
                rts

;=================================================================================
; Set read mode
_init_read:     jsr     _start_cond
                lda     stor_eeprom_block    ; block / device
                asl                     
                ora     #(EEPROM_CMD | READ_MODE)
                jsr     transmit_byte   ; send command to EEPROM
                rts
 ;=================================================================================
; Set write mode               
_init_write:    jsr     _start_cond
                lda     stor_eeprom_block    ; block / device
                asl                     
                ora     #(EEPROM_CMD | WRITE_MODE)
                jsr     transmit_byte   ; send command to EEPROM
                rts

;=================================================================================
; Send the start condition to the EEPROM
_start_cond:    ; 1. DEACTIVATE BUS
                lda     VIA1_PORTA
                ora     #(DATA_PIN | CLOCK_PIN)      ; clock and data high
                sta     VIA1_PORTA
                ; 2. START CONDITION
                and     #(DATA_PIN^$FF) ; clock stays high, data goes low
                sta     VIA1_PORTA
                and     #(CLOCK_PIN^$FF); then pull clock low
                sta     VIA1_PORTA
                rts

;=================================================================================
; Send the stop condition to the EEPROM
_stop_cond:     lda     VIA1_PORTA
                and     #(DATA_PIN^$FF) ; data low
                sta     VIA1_PORTA
                jsr     _clock_high     ; clock high
                lda     VIA1_PORTA           ; TODO: can I get rid of this?
                ora     #DATA_PIN       ; data high
                sta     VIA1_PORTA
                rts

;=================================================================================
; Set the data line as input
_data_in:       lda     VIA1_DDRA
                and     #(DATA_PIN^$FF) ; set data line back to input
                sta     VIA1_DDRA
                rts

;=================================================================================
; Set the data line as input
_data_out:      lda     VIA1_DDRA
                ora     #DATA_PIN       ; set data line to output
                sta     VIA1_DDRA
                rts

;=================================================================================
; Transmit one byte to the EEPROM
; Args:
;   - A: the byte to transmit
transmit_byte:  pha
                phy
                sta     stor_byte_out
                ldy     #8
_transmit_loop: ; Set next byte on bus while clock is still low
                asl     stor_byte_out        ; shift next bit into carry
                lda     VIA1_PORTA
                bcc     _send_zero

                ; send one
                ora     #DATA_PIN
                jmp     _continue
_send_zero:     and     #(DATA_PIN^$FF)
_continue:      and     #(CLOCK_PIN^$FF); make sure clock is low when placing the bit on the bus
                sta     VIA1_PORTA

                jsr     _clock_high     ; toggle clock to strobe it into the eeprom
                jsr     _clock_low

                dey
                bne     _transmit_loop

                ; After each byte, the EEPROM expects a clock cycle during which 
                ; it pulls the data line low to signal that the byte was received
                jsr     _data_in
                jsr     _clock_high
                lsr     VIA1_PORTA           ; put ack bit in Carry
                jsr     _clock_low
                jsr     _data_out
                ply
                pla
                rts
;=================================================================================
; Toggle clock high
_clock_high:    lda     VIA1_PORTA
                ora     #CLOCK_PIN      ; clock high
                sta     VIA1_PORTA
                rts

;=================================================================================
; Toggle clock low
_clock_low:     lda     VIA1_PORTA       
                and     #(CLOCK_PIN^$FF); clock low
                sta     VIA1_PORTA
                rts


; 2, 3, 7, 8 are not used because there are no EEPROMS connected with A1 high
drive_to_eeprom_block:
                .byte   0, 1, 4, 5