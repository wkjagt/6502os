.import __ACIA_START__

.global init_serial
.global rcv_byte
.global send_byte

SER_RXFL        = 1 << 3 ; Serial Receive full bit

ACIA_DATA       = __ACIA_START__ + $00
ACIA_STAT       = __ACIA_START__ + $01
ACIA_CMD        = __ACIA_START__ + $02
ACIA_CTRL       = __ACIA_START__ + $03
