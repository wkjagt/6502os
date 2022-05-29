.include "graphic_screen.inc"

.zeropage

vdp_write_ptr:  .res 2
vdp_write_end:  .res 2

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
                rts