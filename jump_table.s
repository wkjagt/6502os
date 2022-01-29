.include "jump_table.inc"

.segment "JUMPTABLE"
JMP_DUMP:               .res 3          ; 0
JMP_RCV:                .res 3          ; 3
JMP_INIT_SCREEN:        .res 3          ; 6
JMP_RUN:                .res 3          ; 9
JMP_RESET:              .res 3          ; 12
JMP_PUTC:               .res 3          ; 15
JMP_PRINT_HEX:          .res 3          ; 18
JMP_XMODEM_RCV:         .res 3          ; 21
JMP_GETC:               .res 3          ; 24
JMP_INIT_KB:            .res 3          ; 27
JMP_LINE_INPUT:         .res 3          ; 30
JMP_IRQ_HANDLER:        .res 3          ; 33
JMP_NMI_HANDLER:        .res 3          ; 36
JMP_INIT_SERIAL:        .res 3          ; 39
JMP_CURSOR_ON:          .res 3          ; 42
JMP_CURSOR_OFF:         .res 3          ; 45
JMP_DRAW_PIXEL:         .res 3          ; 48
JMP_RMV_PIXEL:          .res 3          ; 51