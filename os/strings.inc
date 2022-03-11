.global cr
.global print_formatted_byte_as_hex
.global print_string_no_lf
.global print_string
.global print_string2
.global hex_to_byte
.global string_table
.global print_byte_as_hex

.macro println str_index
                lda     #str_index
                jsr     print_string
.endmacro

.macro print str_index
                lda     #str_index
                jsr     print_string_no_lf
.endmacro

.macro prn      string
                jsr     print_string2
                .byte   string,0
.endmacro

STR_STARTUP             = $00
STR_RCV_WAIT            = $01
STR_UNKNOWN_CMD         = $02
STR_RCV_DONE            = $03
STR_RCV_START           = $04

SPACE                   = $20
LF                      = $0A
CR                      = $0D
DEL                     = $7F
BS                      = $08
ESC                     = $1B
RIGHT                   = $1C
LEFT                    = $1D
UP                      = $1E
DOWN                    = $1F
PGUP                    = $14
PGDN                    = $15