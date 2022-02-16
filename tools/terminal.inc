.globalzp       command_vector
.globalzp       inputbuffer_ptr
.globalzp       terminal_args

.global         terminal
.global         run                     ; todo: remove
.global         rcv                     ; todo: remove
.global         reset                   ; todo: remove

TERM_ARG_ADDR1  = terminal_args + 0
TERM_ARG_ADDR2  = terminal_args + 2
TERM_ARG_ADDR3  = terminal_args + 4
TERM_ARG1       = terminal_args + 1
TERM_ARG2       = terminal_args + 3
TERM_ARG3       = terminal_args + 5
