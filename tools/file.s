.include "../os/pager_os.inc"
.include "file.inc"

.code
dir:            jmp     show_dir        ; jsr / rts
format:         jmp     format_drive    ; jsr / rts
