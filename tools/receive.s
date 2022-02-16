.include "receive.inc"
.include "../os/strings.inc"
.include "../os/jump_table.inc"
.include "../os/zeropage.inc"

.import __PROGRAM_START__               ; todo: remove once rcv takes a page param

; The rcv command. It waits for a keypress to give the user the opportunity to start
; the transmission on the transmitting computer. A key press sends the initial NAK
; and starts receiving. It uses xmodem_byte_sink_vector as a vector to a routine that
; receives each data byte in the A register.
.code

receive:        println STR_RCV_WAIT

                ; The sender starts transmitting bytes as soon as
                ; it receives a NAK byte from the receiver. To be
                ; able to synchronize the two, the workflow is:
                ; 1. start sending command on sender
                ; 2. Press any key on the receiver to start the
                ;    transmission
                jsr     JMP_GETC

                print   STR_RCV_START
                lda     #>__PROGRAM_START__
                jsr     JMP_PRINT_HEX
                lda     #<__PROGRAM_START__
                jsr     JMP_PRINT_HEX
                jsr     cr

                jsr     JMP_XMODEM_RCV
                txa
                ina
                lsr                     ; packet count to page count
                jsr     JMP_PRINT_HEX
                println STR_RCV_DONE
                rts