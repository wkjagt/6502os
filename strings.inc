.global cr
.global print_formatted_byte_as_hex
.global print_string_no_lf
.global print_string
.global hex_to_byte
.global string_table
.global print_byte_as_hex

STR_STARTUP             = $00
STR_XMODEM_START        = $01
STR_UNKNOWN_CMD         = $02
STR_PROMPT              = $03

SPACE                   = $20
LF                      = $0A
CR                      = $0D
DEL                     = $7F
BS                      = $08