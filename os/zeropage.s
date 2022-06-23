.include "zeropage.inc"
.zeropage

tmp1:                   .res 2
tmp2:                   .res 2
tmp3:                   .res 2
load_page_count:        .res 1          ; todo: is there a better place for these 2?
load_page:              .res 1