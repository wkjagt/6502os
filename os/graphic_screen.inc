.global vdp_init

VDP_VRAM                          = $4400
VDP_REG                           = $4401
VDP_WRITE_VRAM_BIT                = %01000000  ; pattern of second vram address write: 01AAAAAA
VDP_REGISTER_BITS                 = %10000000  ; pattern of second register write: 10000RRR
VDP_NAME_TABLE_BASE               = $0400
VDP_PATTERN_TABLE_BASE            = $0800
VDP_COLOR_TABLE_BASE              = $0200
VDP_SPRITE_PATTERNS_TABLE_BASE    = $0000
VDP_SPRITE_ATTR_TABLE_BASE        = $0100

BG_TRANSPARENT                    = $0
BG_BLACK                          = $1
BG_MEDIUM_GREEN                   = $2
BG_LIGHT_GREEN                    = $3
BG_DARK_BLUE                      = $4
BG_LIGHT_BLUE                     = $5
BG_DARK_RED                       = $6
BG_CYAN                           = $7
BG_MEDIUM_RED                     = $8
BG_LIGHT_RED                      = $9
BG_DARK_YELLOW                    = $A
BG_LIGHT_YELLOW                   = $B
BG_DARK_GREEN                     = $C
BG_MAGENTA                        = $D
BG_GRAY                           = $E
BG_WHITE                          = $F

FG_TRANSPARENT                    = $10 * BG_TRANSPARENT
FG_BLACK                          = $10 * BG_BLACK
FG_MEDIUM_GREEN                   = $10 * BG_MEDIUM_GREEN
FG_LIGHT_GREEN                    = $10 * BG_LIGHT_GREEN
FG_DARK_BLUE                      = $10 * BG_DARK_BLUE
FG_LIGHT_BLUE                     = $10 * BG_LIGHT_BLUE
FG_DARK_RED                       = $10 * BG_DARK_RED
FG_CYAN                           = $10 * BG_CYAN
FG_MEDIUM_RED                     = $10 * BG_MEDIUM_RED
FG_LIGHT_RED                      = $10 * BG_LIGHT_RED
FG_DARK_YELLOW                    = $10 * BG_DARK_YELLOW
FG_LIGHT_YELLOW                   = $10 * BG_LIGHT_YELLOW
FG_DARK_GREEN                     = $10 * BG_DARK_GREEN
FG_MAGENTA                        = $10 * BG_MAGENTA
FG_GRAY                           = $10 * BG_GRAY
FG_WHITE                          = $10 * BG_WHITE

; Register 0
GRAPHIC_MODE_1_M3                 = 0 << 1
EXTVDP_OFF                        = 0 << 0

; Register 1
VRAM_16K                          = 1 << 7
VIDEO_BLANK                       = 0 << 6
INTERRUPT_ENABLE                  = 1 << 5
GRAPHIC_MODE_1_M1                 = 0 << 4
GRAPHIC_MODE_1_M2                 = 0 << 3
SPRITE_SIZE_8X8                   = 0 << 1
SPRITE_MAG_1X                     = 0 << 0

VDP_REGISTER_0_DEFAULT            = GRAPHIC_MODE_1_M3 | EXTVDP_OFF
VDP_REGISTER_1_DEFAULT            = VRAM_16K | VIDEO_BLANK | INTERRUPT_ENABLE | GRAPHIC_MODE_1_M1 | GRAPHIC_MODE_1_M2 | SPRITE_SIZE_8X8 | SPRITE_MAG_1X
VDP_REGISTER_2_DEFAULT            = VDP_NAME_TABLE_BASE / $400
VDP_REGISTER_3_DEFAULT            = VDP_COLOR_TABLE_BASE / $40
VDP_REGISTER_4_DEFAULT            = VDP_PATTERN_TABLE_BASE / $800
VDP_REGISTER_5_DEFAULT            = VDP_SPRITE_ATTR_TABLE_BASE / $80
VDP_REGISTER_6_DEFAULT            = VDP_SPRITE_PATTERNS_TABLE_BASE / $800
VDP_REGISTER_7_DEFAULT            = BG_BLACK | FG_WHITE

.macro          vdp_write_addr addr
                pha
                lda #<addr
                sta VDP_REG
                lda #(VDP_WRITE_VRAM_BIT | >addr) ; see second register write pattern
                sta VDP_REG
                pla
.endmacro


.macro          vdp_write_register value, register
                lda     value
                sta     VDP_REG
                lda     register | VDP_REGISTER_BITS
                sta     VDP_REG
.endmacro