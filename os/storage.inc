.global init_storage
.global write_pages
.global read_pages
.global write_page
.global read_page

DATA_PIN                = %01            
CLOCK_PIN               = %10

EEPROM_CMD              = %10100000
WRITE_MODE              = 0
READ_MODE               = 1