.include "zeropage.inc"

.zeropage

kb_char_in:             .res 2
tmp1:                   .res 2
tmp2:                   .res 2
tmp3:                   .res 2
xmodem_byte_sink_vector:.res 2
dump_start:             .res 2
command_vector:         .res 2
param_index:            .res 2
inputbuffer_ptr:        .res 2
rcv_buffer_pointer:     .res 2

; storage routine args
stor_target_block:      .res 1          ; ARGS0
stor_target_addr:       .res 2          ; ARGS1/2 (H/L)
stor_src_addr:          .res 2          ; ARGS3/4 (L/H) 
stor_byte_cnt:          .res 1          ; ARGS5