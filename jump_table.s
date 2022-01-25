.include "jump_table.inc"

.segment "JUMPTABLE"
JMP_DUMP:               .res 3
JMP_RCV:                .res 3
JMP_INIT_SCREEN:        .res 3
JMP_RUN:                .res 3
JMP_RESET:              .res 3
JMP_PUTC:               .res 3
JMP_PRINT_HEX:          .res 3
JMP_XMODEM_RCV:         .res 3
JMP_GETC:               .res 3
JMP_INIT_KB:            .res 3
JMP_LINE_INPUT:         .res 3
JMP_IRQ_HANDLER:        .res 3
JMP_NMI_HANDLER:        .res 3
JMP_INIT_SERIAL:        .res 3