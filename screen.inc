.global init_screen
.global putc

CLEAR_SCREEN    =       $0c
CHOOSE_CURSOR   =       2               ; choose cursor command to screen
CURSOR_CHAR     =       $db             ; solid block
CURSOR_BLINK    =       3

SCRN_DATA_PINS  =       %11110000       ; In 4 bit mode: send 4 bits of data at a time
SCRN_AVAILABLE  =       %00000100       ; To tell the screen that new data is available
SCRN_ACK        =       %00001000       ; Input pin for the screen to ack the data
SCRN_OUT_PINS   =       SCRN_DATA_PINS | SCRN_AVAILABLE
SCRN_UNUSED     =       %00000011       ; unused pins on this port

