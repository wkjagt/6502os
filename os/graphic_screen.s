.include "graphic_screen.inc"

.export BG_TRANSPARENT
.export BG_BLACK
.export BG_MEDIUM_GREEN
.export BG_LIGHT_GREEN
.export BG_DARK_BLUE
.export BG_LIGHT_BLUE
.export BG_DARK_RED
.export BG_CYAN
.export BG_MEDIUM_RED
.export BG_LIGHT_RED
.export BG_DARK_YELLOW
.export BG_LIGHT_YELLOW
.export BG_DARK_GREEN
.export BG_MAGENTA
.export BG_GRAY
.export BG_WHITE

.export FG_TRANSPARENT
.export FG_BLACK
.export FG_MEDIUM_GREEN
.export FG_LIGHT_GREEN
.export FG_DARK_BLUE
.export FG_LIGHT_BLUE
.export FG_DARK_RED
.export FG_CYAN
.export FG_MEDIUM_RED
.export FG_LIGHT_RED
.export FG_DARK_YELLOW
.export FG_LIGHT_YELLOW
.export FG_DARK_GREEN
.export FG_MAGENTA
.export FG_GRAY
.export FG_WHITE
.export VDP_REGISTER_SELECT
.export VDP_REG
.export VDP_VRAM
.export VDP_NAME_TABLE_BASE
.export VDP_SPRITE_ATTR_TABLE_BASE
.export VDP_WRITE_VRAM_BIT

; name table:           contains a value for each 8x8 region on the screen,
;                       and points to one of the patterns
; color table:          32 bytes, each defining the colors for 8 patterns in 
;                       the pattern table
; pattern table:        a list of patterns to be used as background, selected by
;                       the name table
; sprite pattern table: a list of patterns to be used as sprites
; sprite attr table:    table containing position, color etc for each of the
;                       32 sprites

.zeropage

vdp_write_ptr:  .res 2
vdp_write_end:  .res 2
vdp_register_1: .res 1

.export vdp_write_ptr                   ; todo: this is only to have these in the map file
.export vdp_write_end                   ; together with fake using them somewhere else (pager_os.s)

.code

vdp_init:       jsr     clear_vram
                jsr     init_regs
                rts

clear_vram:     vdp_write_addr $0000
                ldx #$ff                ; VRAM size
                ldy #$40
@loop:          stz VDP_VRAM
                dex
                bne @loop
                dey
                bne @loop
                rts

graphics_on:    lda     vdp_register_1
                ora     #VIDEO_ENABLE
                sta     vdp_register_1
                sta     VDP_REG
                lda     #(1 | VDP_REGISTER_SELECT)
                sta     VDP_REG
                rts

vdp_sprite_pattern_table_write:
                vdp_write_addr VDP_SPRITE_PATTERNS_TABLE_BASE
                jsr     _write_vram
                rts

vdp_pattern_table_write:
                vdp_write_addr VDP_PATTERN_TABLE_BASE
                jsr     _write_vram
                rts

vdp_color_table_write:
                vdp_write_addr VDP_COLOR_TABLE_BASE
                jsr     _write_vram
                rts

_next_write:    inc     vdp_write_ptr   ; inc low byte of write ptr
                bne     _write_vram     ; if that didn't cause a 0, next write
                inc     vdp_write_ptr+1 ; if low byte inc caused 0, inc high byte
_write_vram:    lda     (vdp_write_ptr)
                sta     VDP_VRAM
                lda     vdp_write_ptr
                cmp     vdp_write_end
                bne     _next_write
                lda     vdp_write_ptr+1
                cmp     vdp_write_end+1
                bne     _next_write
                rts


init_regs:      vdp_write_register VDP_REGISTER_0_DEFAULT, 0
                vdp_write_register VDP_REGISTER_1_DEFAULT, 1
                vdp_write_register VDP_REGISTER_2_DEFAULT, 2
                vdp_write_register VDP_REGISTER_3_DEFAULT, 3
                vdp_write_register VDP_REGISTER_4_DEFAULT, 4
                vdp_write_register VDP_REGISTER_5_DEFAULT, 5
                vdp_write_register VDP_REGISTER_6_DEFAULT, 6
                vdp_write_register VDP_REGISTER_7_DEFAULT, 7

                lda     #VDP_REGISTER_1_DEFAULT  ; keep a local copy because these are
                sta     vdp_register_1          ; write only registers on the TMS9918A
                rts