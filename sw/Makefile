# --- Toolchain Configuration ---
# Using RISC-V GNU Toolchain

CROSS_COMPILE = riscv64-unknown-elf-
CC      = $(CROSS_COMPILE)gcc
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump

# Added -Wall for warnings and -Os for better code density
CFLAGS  = -march=rv32i -mabi=ilp32 -ffreestanding -nostdlib -Os -Iinc -Wall
LDFLAGS = -T linker.ld

BUILD_DIR = build

all: $(BUILD_DIR)/program.hex $(BUILD_DIR)/program.lst

# Added linker.ld as a dependency
$(BUILD_DIR)/program.elf: programs/boot.S programs/hello_world.c linker.ld
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) programs/boot.S programs/hello_world.c -o $@ $(LDFLAGS)

# Added --verilog-data-width 4 for 32-bit word alignment
# Updated OBJCOPY line
$(BUILD_DIR)/program.hex: $(BUILD_DIR)/program.elf
	$(OBJCOPY) -O verilog --verilog-data-width 4 $< $@
	sed -i '/@/d' $@

# New: Generates a disassembly file (useful for debugging your RTL)
$(BUILD_DIR)/program.lst: $(BUILD_DIR)/program.elf
	$(OBJDUMP) -D $< > $@

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean