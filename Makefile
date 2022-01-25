ROM_NAME=shallow_thought

ASM_SOURCES=shallow_thought.s\
			screen.s keyboard.s\
			xmodem.s\
			strings.s\
			dump.s\
			acia.s\
			jump_table.s

FIRMWARE_CFG=firmware.cfg

include ./make/cc65.rules.mk