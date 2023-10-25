.global lcd_init
.global lcd_putc
.global lcd_clear
.global lcd_home
.global lcd_on
.global lcd_write_4bit

LCD_I2C_ADDRESS         = $27           ; i2c address of LCD display

LCD_RS_DATA             = %00000001
LCD_RS_INST             = %00000000
LCD_RW                  = %00000010
LCD_EN                  = %00000100
LCD_BT                  = %00001000
FUNC_SET_4BIT           = %00100000
FUNC_SET_8BIT           = %00110000
FUNC_SET_2LINES         = %00101000
FUNC_SET_FONT5X8        = %00100000
DISP_CTRL_DISPLAY_OFF   = %00001000
DISP_CTRL_DISPLAY_ON    = %00001100
DISP_CTRL_CURSOR_OFF    = %00001000
DISP_CTRL_CURSOR_ON     = %00001010
DISP_CTRL_BLINK_OFF     = %00001000
DISP_CTRL_BLINK_ON      = %00001001
CLR_DISPLAY             = %00000001
RETURN_HOME             = %00000010

.macro lcd_ins instruction
                lda     #instruction
                ldx     #LCD_RS_INST
                jsr     lcd_write_4bit
.endmacro
