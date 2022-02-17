.include "terminal.inc"

.code
; Very simple command to jump to the start of the receive buffer.
; Notes:
;   - This will crash the computer if whatever data is there
;     doesn't consist of a valid and correct program
;   - If the loaded program returns control with RTS, it gives
;     control back to line_input which is where the original JSR
;     is. After that only indirect jumps are used.
run:            lda     TERM_ARG1
                bne     @arg_given
                lda     #4
                sta     TERM_ARG1
@arg_given:     jmp     (TERM_ARG_ADDR1)       ; get page from cli arg
