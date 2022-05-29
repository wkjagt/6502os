.include "jump_table.inc"

.segment "JUMPTABLE"
JMP_RCV:                .res 3          ; 0
JMP_INIT_SCREEN:        .res 3          ; 3
JMP_RUN:                .res 3          ; 6
JMP_RESET:              .res 3          ; 9
JMP_PUTC:               .res 3          ; 12
JMP_PRINT_HEX:          .res 3          ; 15
JMP_XMODEM_RCV:         .res 3          ; 18
JMP_GETC:               .res 3          ; 21
JMP_INIT_KB:            .res 3          ; 24
JMP_LINE_INPUT:         .res 3          ; 27
JMP_IRQ_HANDLER:        .res 3          ; 30
JMP_NMI_HANDLER:        .res 3          ; 33
JMP_INIT_SERIAL:        .res 3          ; 36
JMP_CURSOR_ON:          .res 3          ; 39
JMP_CURSOR_OFF:         .res 3          ; 42
JMP_DRAW_PIXEL:         .res 3          ; 45
JMP_RMV_PIXEL:          .res 3          ; 48
JMP_INIT_STORAGE:       .res 3          ; 51
JMP_STOR_READ:          .res 3          ; 54
JMP_STOR_WRITE:         .res 3          ; 57
JMP_STOR_READ_PAGE:     .res 3          ; 60
JMP_STOR_WRITE_PAGE:    .res 3          ; 63
JMP_GET_INPUT:          .res 3          ; 66
JMP_CLR_INPUT:          .res 3          ; 69
JMP_LOAD_FAT:           .res 3          ; 72
JMP_CLEAR_FAT:          .res 3          ; 75
JMP_FIND_EMPTY_PAGE:    .res 3          ; 78
JMP_CLEAR_DIR:          .res 3          ; 81
JMP_LOAD_DIR:           .res 3          ; 84
JMP_SAVE_DIR:           .res 3          ; 87
JMP_SHOW_DIR:           .res 3          ; 90
JMP_FORMAT_DIVE:        .res 3          ; 93
JMP_PRINT_STRING:       .res 3          ; 96
JMP_ADD_TO_DIR:         .res 3          ; 99
JMP_FIND_EMPTY_DIR:     .res 3          ; 102
JMP_DELETE_DIR:         .res 3          ; 105
JMP_DELETE_FILE:        .res 3          ; 108
JMP_SAVE_FAT:           .res 3          ; 111
JMP_FIND_FILE:          .res 3          ; 114
JMP_INIT_GRAPHIC_SCREEN:.res 3          ; 117
JMP_SPRITE_PATTERNS_WRT:.res 3          ; 120
JMP_PATTERNS_WRITE:     .res 3          ; 123
JMP_COLORS_WRITE:       .res 3          ; 126
JMP_GRAPHICS_ON:        .res 3          ; 129
