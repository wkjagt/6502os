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