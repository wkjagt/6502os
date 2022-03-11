.global cr
.global print_formatted_byte_as_hex
.global print_string
.global hex_to_byte
.global print_byte_as_hex

.macro prn      string, withcr              ; cr is optional
                jsr     print_string
                .byte   string, 0
.ifnblank       withcr
                cr
.endif
.endmacro

.macro cr
                putc    CR
                putc    LF
.endmacro


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