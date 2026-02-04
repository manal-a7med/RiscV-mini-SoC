#!/bin/bash
# scripts/build_sw.sh

# Path to your cross-compiler
PREFIX="riscv64-unknown-elf-"
CC="${PREFIX}gcc"
OBJCOPY="${PREFIX}objcopy"

# Target file
SOURCE="../sw/hello.c"
BUILD_DIR="../sw/build"
mkdir -p $BUILD_DIR

echo "Compiling Software..."
# -march=rv32i: Use basic RISC-V instructions
# -mabi=ilp32: Use 32-bit integer ABI
# -T: Use your custom linker script
$CC -march=rv32i -mabi=ilp32 -Wl,-T,../sw/linker.ld -ffreestanding -nostdlib \
    -o $BUILD_DIR/program.elf $SOURCE

# Convert ELF to Verilog Hex format
$OBJCOPY -O verilog $BUILD_DIR/program.elf $BUILD_DIR/program.hex

echo "Success: $BUILD_DIR/program.hex generated."