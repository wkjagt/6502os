.include "lcd.inc"
.include "i2c.inc"

.zeropage
lcd_temp:                .res 1


.code

lcd_init:       jsr     lcd_reset
                jsr     lcd_set_4bit
                lcd_ins FUNC_SET_4BIT | FUNC_SET_2LINES | FUNC_SET_FONT5X8
                lcd_ins DISP_CTRL_DISPLAY_OFF | DISP_CTRL_CURSOR_OFF | DISP_CTRL_BLINK_OFF
                rts

;======================================================================
; Reset is tricky, because the LCD can be in either 8-bit mode (on power up)
; or in 4-bit mode (after a reset), and this needs to work in both cases.
; In 8 bit mode, the command is interpreted after only one write, in which
; case is uselessly gets set to 8 bit mode. The way the i2c backpack is
; connected to the LCD is that the top 4 bits are placed on the top 4 bits
; of the LCD, and the bottom 4 bits of the LCD are tied low. So the 8 bit
; command when read in 8-bit mode, isn't affected by this because the
; bottom 4 bits are already zeros only. Because we send the 8 bit command
; twice, the same command is executed by twice by the display.
; If it's in 4-bit mode already, after a reset (but not power down) of the
; computer, the command is interpreted after 2 writes, by combining 4 bits
; from the first write with the four bits from the second. In that case the
; two instruction writes  in this routines are interpreted as one instruction,
; with the top 4 bits of the instruction serving as both the low and the
; high nibble, making it: 00110011. This has the same effect as setting the
; LCD to 8-bit mode, because in this particular instruction, the last
; two bits are ignored.
;======================================================================
lcd_reset:      lda     #FUNC_SET_8BIT
                ldx     #LCD_RS_INST
                jsr     lcd_write
                lda     #FUNC_SET_8BIT
                ldx     #LCD_RS_INST
                jsr     lcd_write
                rts

lcd_clear:      lcd_ins CLR_DISPLAY
                rts

lcd_home:       lcd_ins RETURN_HOME
                rts

lcd_on:         lcd_ins DISP_CTRL_DISPLAY_ON | DISP_CTRL_CURSOR_OFF | DISP_CTRL_BLINK_OFF
                rts

lcd_set_4bit:   lda     #FUNC_SET_4BIT
                ldx     #LCD_RS_INST
                jsr     lcd_write
                rts

lcd_cursor_off: lcd_ins DISP_CTRL_DISPLAY_ON|DISP_CTRL_CURSOR_OFF
                rts

; ---------------------------------------------
; A contains data to send
; ---------------------------------------------
lcd_send_i2c:   pha
                jsr     i2c_start
                lda     #LCD_I2C_ADDRESS
                clc 
                jsr     i2c_send_addr
                pla
                jsr     i2c_send_byte
                jsr     i2c_stop
                rts

lcd_cout:       phx
                ldx     #LCD_RS_DATA
                jsr     lcd_write_4bit
                plx
                rts

lcd_write_4bit: phy                     ; save y
                phx                     ; save x
                pha                     ; keep around for low nibble
                ; send high nibble
                and     #$f0
                jsr     lcd_write

                ; send low nibble
                pla
                asl
                asl
                asl
                asl
                jsr     lcd_write

                plx                     ; restore x
                ply                     ; restore y
                rts

; A: data to write
; X: register   (data or instruction)
lcd_write:      stx     lcd_temp
                pha                     ; keep for EN toggle
                ora     #(LCD_EN|LCD_BT)
                ora     lcd_temp        ; select register
                jsr     lcd_send_i2c
                pla
                ora     #(LCD_BT)
                ora     lcd_temp        ; select register
                jsr     lcd_send_i2c
                rts
