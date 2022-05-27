.include "graphic_screen.inc"

.code

vdp_init:       jsr     clear_vram
                jsr     init_regs
                rts


clear_vram:     vdp_write_addr $0000
                ldx #$ff
                ldy #$40
@loop:          stz VDP_VRAM
                dex
                bne @loop
                dey
                bne @loop
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