.include "zeropage.inc"
; todo: move this to files that need these vars, except global ones
.zeropage

kb_char_in:             .res 2
tmp1:                   .res 2
tmp2:                   .res 2
tmp3:                   .res 2
dump_start:             .res 2
current_drive:          .res 1
load_page_count:        .res 1
load_page:              .res 1