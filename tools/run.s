.include "run.inc"
.import __PROGRAM_START__               ; todo: remove once run page is an arg

.code
; Very simple command to jump to the start of the receive buffer.
; Notes:
;   - This will crash the computer if whatever data is there
;     doesn't consist of a valid and correct program
;   - If the loaded program returns control with RTS, it gives
;     control back to line_input which is where the original JSR
;     is. After that only indirect jumps are used.
run:            jmp     __PROGRAM_START__       ; get page from cli arg
