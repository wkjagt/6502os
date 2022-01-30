.include "storage.inc"
.include "zeropage.inc"
.include "via.inc"

init_storage:   lda     VIA1_DDRA
                ora     #(DATA_PIN | CLOCK_PIN)
                sta     VIA1_DDRA

                rts

;=================================================================================
;               ROUTINES
;=================================================================================

;=================================================================================
; Write a sequence of bytes to the EEPROM
; Args:
;   - ARGS+0: Block / device address. Three bits: 00000BDD
;   - ARGS+1: High byte of target address on the EEPROM
;   - ARGS+2: Low byte of target address on the EEPROM
;   - ARGS+3: Low byte of vector pointing to first byte to transmit
;   - ARGS+4: High byte of vector pointing to first byte to transmit
;   - ARGS+5: Number of bytes to write (max: 128)
write_sequence:
                jsr     _init_sequence
                ldy     #0              ; start at 0
@byte_loop:
                lda     (stor_src_addr),y
                jsr     transmit_byte
                iny
                cpy     stor_byte_cnt            ; compare with string lengths in TMP1
                bne     @byte_loop
                jsr     _stop_condition

                ; wait for write sequence to be completely written to EEPROM.
                ; This isn't always needed, but it's safer to do so, and doesn't
                ; waste much time.
ack_loop:
                jsr     _start_condition
                lda     #(EEPROM_CMD | WRITE_MODE)
                ora     stor_target_block
                jsr     transmit_byte   ; send command to EEPROM
                lda     tmp3
                bne     ack_loop
                rts
;=================================================================================
; Read a sequence of bytes from the EEPROM
; Args:
;   - ARGS+0: Block / device address. Three bits: 00000BDD
;   - ARGS+1: High byte of target address on the EEPROM
;   - ARGS+2: Low byte of target address on the EEPROM
;   - ARGS+3: Low byte of vector pointing to where to write the first byte
;   - ARGS+4: High byte of vector pointing to where to write the first byte
;   - ARGS+5: Number of bytes to read
read_sequence:
                phx
                jsr     _init_sequence

                ; Now that the address is set, start read mode
                jsr     _start_condition

                ; send block / device / read mode (same as used to write the address)
                lda     #(EEPROM_CMD | READ_MODE)
                ora     stor_target_block
                jsr     transmit_byte   ; send command to EEPROM

                ldy     #0              ; byte counter, counts up to length in ARGS+5
@byte_loop:
                jsr     _data_in
                ldx     #8              ; bit counter, counts down to 0
@bit_loop:
                jsr     _clock_high
                lda     VIA1_PORTA           ; the eeprom should output the next bit on the data line
                lsr                     ; shift the reveived bit onto the carry flag
                rol     tmp2         ; shift the received bit into the the received byte
                jsr     _clock_low
                
                dex
                bne     @bit_loop       ; keep going until all 8 bits are shifted in

                lda     tmp2
                sta     (stor_src_addr),y      ; store the byte following the provided vector

                iny
                cpy     stor_byte_cnt
                beq     @done           ; no ack for last byte, as per the datasheet

                ; ack the reception of the byte
                jsr     _data_out        ; set the data line as output so we can ackknowledge

                lda     VIA1_PORTA
                and     #(DATA_PIN^$FF)  ; set data line low to ack
                sta     VIA1_PORTA

                jsr     _clock_high      ; strobe it into the EEPROM
                jsr     _clock_low

                jmp     @byte_loop
@done:
                jsr     _data_out

                jsr     _stop_condition
                plx
                rts
;=================================================================================
;               PRIVATE ROUTINES
;=================================================================================

;=================================================================================
; This initializes a read or write sequence by generating the start condition,
; selecting the correct block and device by sending the command to the EEPROM,
; and setting the internal address pointer to the selected address.
;
; Args (sent to read_sequence or write_sequence):
;   - ARGS+0: Block / device address. Three bits: 00000BDD
;   - ARGS+1: High byte of target address on the EEPROM
;   - ARGS+2: Low byte of target address on the EEPROM
_init_sequence:
                ; send start condition
                jsr     _start_condition
                ; send block / device / write mode
                lda     stor_target_block            ; block / device
                asl                     
                sta     stor_target_block
                lda     #(EEPROM_CMD | WRITE_MODE)
                ora     stor_target_block
                jsr     transmit_byte   ; send command to EEPROM

                ; set high and low bytes of the target address (high first)
                lda     stor_target_addr
                jsr     transmit_byte
                lda     stor_target_addr+1
                jsr     transmit_byte
                rts
;=================================================================================
; Send the start condition to the EEPROM
_start_condition:
                ; 1. DEACTIVATE BUS
                lda     VIA1_PORTA
                ora     #(DATA_PIN | CLOCK_PIN)      ; clock and data high
                sta     VIA1_PORTA
                ; 2. START CONDITION
                and     #(DATA_PIN^$FF)     ; clock stays high, data goes low
                sta     VIA1_PORTA
                and     #(CLOCK_PIN^$FF)     ; then pull clock low
                sta     VIA1_PORTA
                rts

;=================================================================================
; Send the stop condition to the EEPROM
_stop_condition:
                lda     VIA1_PORTA
                and     #(DATA_PIN^$FF)  ; data low
                sta     VIA1_PORTA
                jsr     _clock_high      ; clock high
                lda     VIA1_PORTA               ; TODO: can I get rid of this?
                ora     #DATA_PIN        ; data high
                sta     VIA1_PORTA
                rts

;=================================================================================
; Set the data line as input
_data_in:
                lda     VIA1_DDRA
                and     #(DATA_PIN^$FF)      ; set data line back to input
                sta     VIA1_DDRA
                rts

;=================================================================================
; Set the data line as input
_data_out:
                lda     VIA1_DDRA
                ora     #DATA_PIN       ; set data line to output
                sta     VIA1_DDRA
                rts

;=================================================================================
; Transmit one byte to the EEPROM
; Args:
;   - A: the byte to transmit
transmit_byte:
                pha
                phy
                sta     tmp1
                ldy     #8
@transmit_loop:
                ; Set next byte on bus while clock is still low
                asl     tmp1        ; shift next bit into carry
                lda     VIA1_PORTA
                bcc     @send_zero

                ; send one
                ora     #DATA_PIN
                jmp     @continue
@send_zero:
                and     #(DATA_PIN^$FF)
@continue:
                and     #(CLOCK_PIN^$FF); make sure clock is low when placing the bit on the bus
                sta     VIA1_PORTA

                jsr     _clock_high     ; toggle clock to strobe it into the eeprom
                jsr     _clock_low

                dey
                bne     @transmit_loop

                ; After each byte, the EEPROM expects a clock cycle during which 
                ; it pulls the data line low to signal that the byte was received
                jsr     _data_in
                jsr     _clock_high
                lda     VIA1_PORTA
                and     #DATA_PIN       ; only save last bit
                sta     tmp3
                jsr     _clock_low
                jsr     _data_out
                ply
                pla
                rts
;=================================================================================
; Toggle clock high
_clock_high:    ; toggle clock from high to low to strobe the bit into the eeprom
                lda     VIA1_PORTA
                ora     #CLOCK_PIN      ; clock high
                sta     VIA1_PORTA
                rts

;=================================================================================
; Toggle clock low
_clock_low:         
                lda     VIA1_PORTA       
                and     #(CLOCK_PIN^$FF)  ; clock low
                sta     VIA1_PORTA
                rts
