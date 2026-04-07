# pd/synth.tcl

# 1. Read the SRAM as a library FIRST
yosys read_verilog -lib ../macros/sky130_sram_1kbyte_1rw1r_32x256_8.v

# 1. Read files with absolute include path
# Using -sv for SystemVerilog features (like your includes)

yosys read_verilog -sv -I/home/manal/projects/RiscV-mini-SoC/rtl/include \
    -DHEX_PATH="../sw/build/program.hex" \
    ../rtl/cpu/picorv32.v \
    ../rtl/bus/simple_interconnect.v \
    ../rtl/memory/instr_mem.v \
    ../rtl/memory/data_mem.v \
    ../rtl/peripherals/uart.v \
    ../rtl/peripherals/timer.v \
    ../rtl/top/mini_soc_top.v

# IMPORTANT: Tell Yosys the SRAM is a blackbox
yosys hierarchy -check -top mini_soc_top -check

yosys read_liberty -lib ../macros/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib

yosys blackbox sky130_sram_1kbyte_1rw1r_32x256_8

#yosys read_lef ../macros/sky130_sram_1kbyte_1rw1r_32x256_8.lef


# 3. High-level synthesis
# These are the fundamental Yosys RTL optimization passes
yosys proc; yosys opt; yosys fsm; yosys opt; yosys memory; yosys opt;


# 4. Mapping to Sky130
yosys techmap
yosys dfflibmap -liberty /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd__tt_025C_1v80.lib
yosys abc -liberty /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd__tt_025C_1v80.lib
yosys clean

# 5. Prepare for OpenROAD
yosys splitnets -ports
yosys setundef -zero
yosys check

# Map logical 1 and 0 to Sky130 Tie-Hi/Lo cells
yosys hilomap -hicell sky130_fd_sc_hd__conb_1 HI -locell sky130_fd_sc_hd__conb_1 LO

# 6. Output netlist - This must match what run_flow.sh expects
# Change this to output/synth.v so floorplan step can find it
#mkdir -p output
# Add -noattr to remove the attributes that confuse OpenROAD
yosys write_verilog -noattr -noexpr -nodec output/synth.v
yosys stat