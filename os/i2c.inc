.global i2c_init
.global i2c_send_ack
.global i2c_read_byte
.global i2c_send_addr
.global i2c_start
.global i2c_stop
.global i2c_send_byte

I2C_DATABIT             = %01            
I2C_CLOCKBIT            = %10
I2C_DDR                 = $6003
I2C_PORT                = $6001

.macro i2c_data_up
                lda     #I2C_DATABIT    ; Clear data bit of the DDR
                trb     I2C_DDR         ; to make bit an input and let it float up.
.endmacro

.macro i2c_data_down
                lda     #I2C_DATABIT    ; Set data bit of the DDR
                tsb     I2C_DDR         ; to make bit an output and pull it down.
.endmacro

.macro i2c_clock_up
                lda     #I2C_CLOCKBIT
                trb     I2C_DDR
.endmacro

.macro i2c_clock_down
                lda     #I2C_CLOCKBIT
                tsb     I2C_DDR
.endmacro

.macro i2c_clock_pulse
                lda     #I2C_CLOCKBIT
                trb     I2C_DDR         ; Clock up
                tsb     I2C_DDR         ; Clock down
.endmacro
