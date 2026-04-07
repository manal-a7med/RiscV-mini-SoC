#pd/floorplan.tcl (this file is not used in the current flow, but it's a template for how to do
                #manual floorplanning if you want to customize it further. The current flow uses the more automated approach in run_flow.sh))
# 1. Initialize the floorplan (This calls the logic in InitFloorplan.tcl)
initialize_floorplan \
    -die_area $::env(DIE_AREA) \
    -core_area $::env(CORE_UTILIZATION) \
    -site "unithd"

source $::env(OPENROAD_SCRIPTS)/InitFloorplan.tcl   
# 2. Place Pins (The extension part)
# We want to separate UART from Clock to avoid noise/interference.
# Positions: 1=Top, 2=Bottom, 3=Left, 4=Right

# 3. Pin Constraints (Updated for 1500um scale)
# West Side (3): Clock and Reset separated by a wide gap
set_io_pin_constraint -direction input -side 3 -region {0 400} [get_ports clk]
set_io_pin_constraint -direction input -side 3 -region {800 1200} [get_ports reset_n]

# Read the physical LEF file
read_lef ../macros/sky130_sram_1kbyte_1rw1r_32x256_8.lef

# East Side (4): UART
set_io_pin_constraint -direction output -side 4 -region {0 400} [get_ports uart_tx]
set_io_pin_constraint -direction input  -side 4 -region {600 1000} [get_ports uart_rx]

# Place the Trap signal on the Top
set_io_pin_constraint -direction output -side 1 [get_ports trap]

# Manual Placement of the two SRAM macros

# 4. PLACE THE MACROS (Otherwise they stay at 0,0)
# Adjust these coordinates so they are inside your 1500x1500 area

place_inst imem_inst/sram_macro 100 100 R0
place_inst dmem_inst/sram_macro 900 100 R0

# Add a halo/blockage around them so standard cells don't get too close
# (Prevents routing shorts)
add_buffer_cell_blockage -inst imem_inst/sram_macro -buffer 20
add_buffer_cell_blockage -inst dmem_inst/sram_macro -buffer 20

# 6. Execute Pin Placement
place_pins -hor_layers met3 -ver_layers met2