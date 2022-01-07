ROM_NAME=shallow_thought

ASM_SOURCES=shallow_thought.s via.s acia.s screen.s
FIRMWARE_CFG=firmware.cfg

include ./make/cc65.rules.mk
