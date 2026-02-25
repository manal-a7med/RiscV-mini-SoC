#pd/floorplan.tcl
# 1. Initialize the floorplan (This calls the logic in InitFloorplan.tcl)
initialize_floorplan \
    -die_area $::env(DIE_AREA) \
    -core_area $::env(CORE_UTILIZATION) \
    -site $::env(PLACE_SITE)

source $::env(OPENROAD_SCRIPTS)/InitFloorplan.tcl   
# 2. Place Pins (The extension part)
# We want to separate UART from Clock to avoid noise/interference.
# Positions: 1=Top, 2=Bottom, 3=Left, 4=Right

# Place Clock and Reset on the Left
set_io_pin_constraint -direction input -side 3 -region {0 300} [get_ports clk]
set_io_pin_constraint -direction input -side 3 -region {400 600} [get_ports reset_n]

# Read the physical LEF file
read_lef ../macros/sky130_sram_1kbyte_1rw1r_32x256_8.lef

# Place UART pins on the Right
set_io_pin_constraint -direction output -side 4 -region {1 300} [get_ports uart_tx]
set_io_pin_constraint -direction input  -side 4 -region {400 600} [get_ports uart_rx]

# Place the Trap signal on the Top
set_io_pin_constraint -direction output -side 1 [get_ports trap]

# Manual Placement of the two SRAM macros
# Syntax: place_cell -inst_name <name> -origin <x> <y> -orientation <R0/MX/etc> (wrong)
# Note: Ensure the origins fit within your DIE_AREA (800 800) and core area (790 790)

# 4. PLACE THE MACROS (Otherwise they stay at 0,0)
# Adjust these coordinates so they are inside your 800x800 area

place_inst imem_inst/sram_macro 50 30 R0
place_inst dmem_inst/sram_macro 50 470 R0

# Add a halo/blockage around them so standard cells don't get too close
# (Prevents routing shorts)
add_buffer_cell_blockage -inst imem_inst/sram_macro -buffer 10
add_buffer_cell_blockage -inst dmem_inst/sram_macro -buffer 10

# 3. Execute Pin Placement
place_pins -random_seed 42