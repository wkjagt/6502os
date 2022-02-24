NAK             =       $15
ACK             =       $06
EOT             =       $04
SOH             =       $01

.global xmodem_receive
.globalzp rcv_start_page
.globalzp rcv_page_count