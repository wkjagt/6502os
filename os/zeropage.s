.include "zeropage.inc"
; todo: move this to files that need these vars, except global ones
.zeropage

kb_char_in:             .res 2
tmp1:                   .res 2
tmp2:                   .res 2
tmp3:                   .res 2
dump_start:             .res 2
rcv_buffer_pointer:     .res 2

; storage routine args
stor_eeprom_block:      .res 1
stor_eeprom_addr_l:     .res 1
stor_eeprom_addr_h:     .res 1
stor_ram_addr_l:        .res 1
stor_ram_addr_h:        .res 1

stor_byte_in:           .res 1
stor_byte_out:          .res 1

current_drive:          .res 1