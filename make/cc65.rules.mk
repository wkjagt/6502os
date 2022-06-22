CA65_BINARY=ca65
LD65_BINARY=ld65

CPU_FLAG=--cpu 65C02

CA65_FLAGS=$(CPU_FLAG) $(EXTRA_FLAGS)
LD65_FLAGS=

# Hexdump is used for "testing" the ROM
HEXDUMP_BINARY=hexdump
HEXDUMP_FLAGS=-C

# Checksum generator
MD5_BINARY=md5

# Standard utilities (rm/mkdir)
RM_BINARY=rm
RM_FLAGS=-f
MKDIR_BINARY=mkdir
MKDIR_FLAGS=-p
CP_BINARY=cp
CP_FLAGS=-f

BUILD_FOLDER=./build
TEMP_FOLDER=$(BUILD_FOLDER)/$(ROM_NAME)
ROM_FILE=$(BUILD_FOLDER)/$(ROM_NAME).bin
MAP_FILE=$(TEMP_FOLDER)/$(ROM_NAME).map
VICE_FILE=$(TEMP_FOLDER)/$(ROM_NAME).vice

ASM_OBJECTS=$(ASM_SOURCES:%.s=$(TEMP_FOLDER)/%.o)

# Default target
all: clean $(ROM_FILE) headerfile

# Compile assembler sources
$(TEMP_FOLDER)/%.o: %.s
	@$(MKDIR_BINARY) $(MKDIR_FLAGS) $(TEMP_FOLDER)
	$(CA65_BINARY) $(CA65_FLAGS) -o $@ -l $(@:.o=.lst) $<

# Link ROM image
$(ROM_FILE): $(ASM_OBJECTS) $(FIRMWARE_CFG)
	@$(MKDIR_BINARY) $(MKDIR_FLAGS) $(BUILD_FOLDER)
	$(LD65_BINARY) $(LD65_FLAGS) -C $(FIRMWARE_CFG) -o $@ -Ln $(VICE_FILE) -m $(MAP_FILE) $(ASM_OBJECTS)

headerfile:
	python header/header.py

# Build and dump output
test: all
	$(HEXDUMP_BINARY) $(HEXDUMP_FLAGS) $(ROM_FILE)
	$(MD5_BINARY) $(ROM_FILE)

# Clean build artifacts
clean:
	$(RM_BINARY) $(RM_FLAGS) $(ROM_FILE) \
	$(MAP_FILE) \
	$(ASM_OBJECTS) \
	$(ASM_OBJECTS:%.o=%.lst)

bios:
	minipro -p AT28C256 -w $(ROM_FILE) -s