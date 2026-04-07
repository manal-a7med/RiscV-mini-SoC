# --- Environment Setup ---
PROJECT_ROOT = $(shell pwd)
PD_DIR       = $(PROJECT_ROOT)/pd

# --- Targets ---
.PHONY: all software sim physical clean

all: software sim physical

# 1. Compile Software (C -> HEX)
software:
	@echo "--- Building Software ---"
	$(MAKE) -C sw/
	mkdir -p sim/hex
	cp sw/build/program.hex sim/hex/

# 2. Functional Simulation (Verilog Verification)
sim: software
	@echo "--- Running RTL Simulation ---"
	iverilog -o sim/sim_out -g2012 \
    	-DSIM \
    	-I rtl/include \
    	-y macros/ \
    	-s tb_mini_soc \
    	rtl/cpu/picorv32.v \
    	rtl/bus/simple_interconnect.v \
    	rtl/memory/instr_mem.v \
    	rtl/memory/data_mem.v \
    	rtl/peripherals/uart.v \
    	rtl/peripherals/timer.v \
    	rtl/top/mini_soc_top.v \
    	macros/sky130_sram_1kbyte_1rw1r_32x256_8.v \
    	sim/tb/tb_mini_soc.sv
	vvp sim/sim_out

# 3. Physical Design (Your Custom Flow)
physical:
	@echo "--- Starting Physical Design Flow ---"
	# Instead of the OpenROAD system flow, we call your local Makefile
	$(MAKE) -C $(PD_DIR) synth
	$(MAKE) -C $(PD_DIR) floorplan
	$(MAKE) -C $(PD_DIR) pdn
	$(MAKE) -C $(PD_DIR) placement
	$(MAKE) -C $(PD_DIR) report
	$(MAKE) -C $(PD_DIR) cts
	$(MAKE) -C $(PD_DIR) route
	$(MAKE) -C $(PD_DIR) sta
	$(MAKE) -C $(PD_DIR) signoff

# 4. Clean up
clean:
	@echo "--- Cleaning Project ---"
	rm -rf sim/sim_out
	rm -rf sim/hex/*
	$(MAKE) -C sw/ clean
	$(MAKE) -C pd/ clean