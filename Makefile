ROM_NAME=shallow_thought

ASM_SOURCES=os/shallow_thought.s\
			os/screen.s\
			os/keyboard.s\
			os/xmodem.s\
			os/strings.s\
			os/acia.s\
			os/jump_table.s\
			os/zeropage.s\
			os/storage.s\
			tools/dump.s\
			tools/edit.s\
			tools/terminal.s

FIRMWARE_CFG=firmware.cfg

include ./make/cc65.rules.mk