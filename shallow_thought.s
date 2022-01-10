                .include "strings.inc"

                .import init_screen
                .import init_keyboard
                .import wait_for_key_press
                .import send_byte_to_screen
                .import xmodem_receive
                .import print_formatted_byte_as_hex
                .import print_string

.import string_table

xmodem_byte_sink_vector = $08

                .code

reset:
                jsr     init_screen
                jsr     init_keyboard

                ; startup message
                lda     #STR_STARTUP
                jsr     print_string

                lda     #STR_ANY_KEY
                jsr     print_string

                ; set the vector for what to do with each byte coming in through xmodem
                lda     #<print_formatted_byte_as_hex
                sta     xmodem_byte_sink_vector
                lda     #>print_formatted_byte_as_hex
                sta     xmodem_byte_sink_vector+1


                ; The sender starts transmitting bytes as soon as
                ; it receives a NAK byte from the receiver. To be
                ; able to synchronize the two, the workflow is:
                ; 1. start sending command on sender
                ; 2. Press any key on the receiver to start the
                ;    transmission
                jsr     wait_for_key_press
                jsr     xmodem_receive
                rts

; ; this only adds a space
; print_formatted_byte_as_hex:
;                 jsr     print_byte_as_hex
;                 lda     #' '
;                 jsr     send_byte_to_screen
;                 rts

; print_byte_as_hex:
;                 pha                     ; keep a copy for the low nibble

;                 lsr                     ; shift high nibble into low nibble
;                 lsr
;                 lsr
;                 lsr

;                 jsr     print_nibble

;                 pla                     ; get original value back
;                 and     #%00001111      ; reset high nibble
;                 jsr     print_nibble
;                 rts

; print_nibble:
;                 cmp     #10
;                 bcs     @letter         ; >= 10 (hex letter A-F)
;                 adc     #48             ; ASCII offset to numbers 0-9
;                 jmp     @print
; @letter:
;                 adc     #54             ; ASCII offset to letters A-F
; @print:
;                 jsr     send_byte_to_screen
;                 rts

; print_string:
;                 asl                     ; multiply by 2 because size of memory address is 2 bytes
;                 tay
;                 lda     string_table,y  ; string index into string table
;                 sta     tmp3            ; LSB
;                 iny
;                 lda     string_table,y
;                 sta     tmp3+1          ; MSB

;                 ldy #0
; @next_char:
;                 lda (tmp3),y
;                 beq @done

;                 jsr send_byte_to_screen
;                 iny
;                 bra @next_char
; @done:
;                 lda     #$0d
;                 jsr     send_byte_to_screen
;                 lda     #$0a
;                 jsr     send_byte_to_screen
;                 rts

; strings ========================================

; str_startup     =       0
; str_any_key     =       1

; string_table:
;                 .word s_startup, s_any_key

; s_startup:      .byte "Shallow Thought v0.01", 0                
; s_any_key:      .byte "Press any key", 0
