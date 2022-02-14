.global init_screen
.global putc
.global cursor_on
.global cursor_off
.global draw_pixel
.global rmv_pixel
.global cursor_right
.global cursor_left
.global cursor_upts
.global cursor_down
.global cursor_home

CURSOR_HOME     =       $01
CHOOSE_CURSOR   =       $02               ; choose cursor command to screen
CURSOR_BLINK    =       $03
CURSOR_SOLID    =       $04
DRAW_PIXEL      =       $05
RESET_PIXEL     =       $06
CLEAR_SCREEN    =       $0C
CURSOR_RIGHT    =       $1C
CURSOR_LEFT     =       $1D
CURSOR_UP       =       $1E
CURSOR_DOWN     =       $1F

CURSOR_CHAR     =       $DB             ; solid block
SCRN_DATA_PINS  =       %11110000       ; In 4 bit mode: send 4 bits of data at a time
SCRN_AVAILABLE  =       %00000100       ; To tell the screen that new data is available
SCRN_ACK        =       %00001000       ; Input pin for the screen to ack the data
SCRN_OUT_PINS   =       SCRN_DATA_PINS | SCRN_AVAILABLE
SCRN_UNUSED     =       %00000011       ; unused pins on this port