kb_char_in              = $00

; additional "registers"
tmp1                    = $02
tmp2                    = $04
tmp3                    = $06

xmodem_byte_sink_vector = $08
dump_start              = $0a
command_vector          = $0c
param_index             = $0e
keybuffer_ptr           = $10

; this is not the keyboard buffer, but the typed line
keybuffer               = $80
