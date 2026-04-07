# Design Name and Platform
#pd/config.mk
export DESIGN_NAME="mini_soc_top"
export PLATFORM="sky130hd"

# Paths
export PROJECT_HOME="/home/manal/projects/RiscV-mini-SoC"

# Physical Design Constraints
export SDC_FILE="${PROJECT_HOME}/pd/constraints.sdc"
export CLOCK_PORT="clk"
export CLOCK_PERIOD="20.0"

# RTL Source Files
export VERILOG_FILES="${PROJECT_HOME}/rtl/cpu/picorv32.v \
                       ${PROJECT_HOME}/rtl/bus/simple_interconnect.v \
                       ${PROJECT_HOME}/rtl/memory/instr_mem.v \
                       ${PROJECT_HOME}/rtl/memory/data_mem.v \
                       ${PROJECT_HOME}/rtl/peripherals/uart.v \
                       ${PROJECT_HOME}/rtl/peripherals/timer.v \
                       ${PROJECT_HOME}/rtl/top/mini_soc_top.v"

# Include Directory - formatted for Yosys
export VERILOG_INCLUDE="-I${PROJECT_HOME}/rtl/include"

# Macro physical and timing data
export EXTRA_LEFS="${PROJECT_HOME}/macros/sky130_sram_1kbyte_1rw1r_32x256_8.lef"
export EXTRA_LIBS="${PROJECT_HOME}/macros/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib"
export EXTRA_GDS="${PROJECT_HOME}/macros/sky130_sram_1kbyte_1rw1r_32x256_8.gds"

# Floorplanning
export CORE_UTILIZATION="40"
export DIE_AREA="0 0 1500 1500"
export PLACE_SITE="unithd"
export IO_PCT="0.2"