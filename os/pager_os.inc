.include        "screen.inc"
.include        "acia.inc"
.include        "jump_table.inc"        ; todo: remove
.include        "keyboard.inc"
.include        "storage.inc"
.include        "strings.inc"
.include        "via.inc"
.include        "zeropage.inc"
.include        "input.inc"
.include        "xmodem.inc"
.include        "file.inc"

PROGRAM_START           = $0600
PROGRAM_START_PAGE      = $06

.global         reset