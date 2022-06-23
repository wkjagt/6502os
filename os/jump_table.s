.include "jump_table.inc"

.segment "JUMPTABLE"
JMP_RCV:                .res 3
JMP_INIT_SCREEN:        .res 3
JMP_PUTC:               .res 3
JMP_PRINT_HEX:          .res 3
JMP_XMODEM_RCV:         .res 3
JMP_GETC:               .res 3
JMP_INIT_KB:            .res 3
JMP_LINE_INPUT:         .res 3
JMP_IRQ_HANDLER:        .res 3
JMP_NMI_HANDLER:        .res 3
JMP_INIT_SERIAL:        .res 3
JMP_CURSOR_ON:          .res 3
JMP_CURSOR_OFF:         .res 3
JMP_DRAW_PIXEL:         .res 3
JMP_RMV_PIXEL:          .res 3
JMP_INIT_STORAGE:       .res 3
JMP_STOR_READ:          .res 3
JMP_STOR_WRITE:         .res 3
JMP_STOR_READ_PAGE:     .res 3
JMP_STOR_WRITE_PAGE:    .res 3
JMP_GET_INPUT:          .res 3
JMP_CLR_INPUT:          .res 3
JMP_LOAD_FAT:           .res 3
JMP_CLEAR_FAT:          .res 3
JMP_FIND_EMPTY_PAGE:    .res 3
JMP_CLEAR_DIR:          .res 3
JMP_LOAD_DIR:           .res 3
JMP_SAVE_DIR:           .res 3
JMP_SHOW_DIR:           .res 3
JMP_FORMAT_DIVE:        .res 3
JMP_PRINT_STRING:       .res 3
JMP_ADD_TO_DIR:         .res 3
JMP_FIND_EMPTY_DIR:     .res 3
JMP_DELETE_DIR:         .res 3
JMP_DELETE_FILE:        .res 3
JMP_SAVE_FAT:           .res 3
JMP_FIND_FILE:          .res 3
JMP_INIT_GRAPHIC_SCREEN:.res 3
JMP_SPRITE_PATTERNS_WRT:.res 3
JMP_PATTERNS_WRITE:     .res 3
JMP_COLORS_WRITE:       .res 3
JMP_GRAPHICS_ON:        .res 3
