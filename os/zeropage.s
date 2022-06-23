.include "zeropage.inc"
; todo: move this to files that need these vars, except global ones
.zeropage

tmp1:                   .res 2
tmp2:                   .res 2
tmp3:                   .res 2
current_drive:          .res 1
load_page_count:        .res 1
load_page:              .res 1