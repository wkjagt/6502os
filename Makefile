ROM_NAME=pager_os

ASM_SOURCES=os/pager_os.s\
			os/screen.s\
			os/keyboard.s\
			os/xmodem.s\
			os/strings.s\
			os/acia.s\
			os/jump_table.s\
			os/zeropage.s\
			os/storage.s\
			os/input.s\
			os/file.s\
			tools/dump.s\
			tools/edit.s\
			tools/terminal.s\
			tools/receive.s\
			tools/storage.s\
			tools/run.s\
			tools/file.s

FIRMWARE_CFG=firmware.cfg

include ./make/cc65.rules.mk