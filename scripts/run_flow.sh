#!/bin/bash
# scripts/run_flow.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../pd/config.mk"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --step)   STEP="$2";   shift ;;
        --design) DESIGN="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

case $STEP in
    synth)
        echo "Running Yosys Synthesis for $DESIGN_NAME..."
        mkdir -p output
        yosys -c "../pd/synth.tcl" | tee output/synth.log
        ;; # End of synth

    floorplan)
        echo "Running OpenROAD Floorplan for $DESIGN_NAME..."
        mkdir -p output
        /home/manal/OpenROAD/build/install/bin/openroad -no_init <<EOF

source ../pd/openroad_vars.tcl

# 1. Read Tech LEF and Standard Cell LEF
read_lef /home/manal/OpenROAD/test/sky130hd/sky130hd.tlef
read_lef /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd.lef

# 2. READ SRAM MACRO LEF (CRITICAL)
read_lef ../macros/sky130_sram_1kbyte_1rw1r_32x256_8.lef

# 3. Read Libs (Standard Cells + SRAM)
read_liberty /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd__tt_025C_1v80.lib
read_liberty ../macros/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib

read_verilog output/synth.v
link_design mini_soc_top

initialize_floorplan -die_area {0 0 900 900} -core_area {10.12 10.88 889.88 889.12} -site "unithd"

# 2. CREATE TRACKS (Crucial fix for PPL-0022)
# This defines the "roads" for the wires to travel on
make_tracks li1  -x_offset 0.17 -x_pitch 0.34 -y_offset 0.17 -y_pitch 0.34

make_tracks met1 -x_offset 0.17 -x_pitch 0.34 -y_offset 0.17 -y_pitch 0.34
make_tracks met2 -x_offset 0.23 -x_pitch 0.46 -y_offset 0.23 -y_pitch 0.46
make_tracks met3 -x_offset 0.34 -x_pitch 0.68 -y_offset 0.34 -y_pitch 0.68

make_tracks met4 -x_offset 0.46 -x_pitch 0.92 -y_offset 0.46 -y_pitch 0.92
make_tracks met5 -x_offset 1.70 -x_pitch 3.40 -y_offset 1.70 -y_pitch 3.40

# 4. PLACE THE MACROS (Otherwise they stay at 0,0)
# Adjust these coordinates so they are inside your 800x800 area
# (Adjusted Y to fit inside 900um)
# Macro 1:
place_macro -macro_name imem_inst/sram_macro -location {50 30} -orientation R0 -exact
# Macro 2: 
place_macro -macro_name dmem_inst/sram_macro -location {50 470} -orientation R0 -exact


# 5. Set Macro Halo (Using your verified documentation syntax)
# Documentation says {width height}, let's use 10um for both
#set_macro_halo -macro_name imem_inst/sram_macro -halo {10 10}
#set_macro_halo -macro_name dmem_inst/sram_macro -halo {10 10}

# 6. Pin Placement
# Since -config/-cfg failed, we follow the doc's tip: 
# place individual critical pins first, then let the tool handle the rest.
place_pin -pin_name clk -layer met3 -location {0 400} -force_to_die_boundary
place_pin -pin_name reset_n -layer met3 -location {0 450} -force_to_die_boundary

# Randomly place the remaining pins (UART, Trap) on specified layers
place_pins -hor_layers met3 -ver_layers met2

write_def output/floorplan.def
EOF
        ;; # End of floorplan

    pdn)
        echo "Generating Power Distribution Network (PDN)..."
        mkdir -p output
        /home/manal/OpenROAD/build/install/bin/openroad -no_init <<EOF

# 1. Read the Floorplan DEF we just created
read_lef /home/manal/OpenROAD/test/sky130hd/sky130hd.tlef
read_lef /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd.lef
read_lef ../macros/sky130_sram_1kbyte_1rw1r_32x256_8.lef
read_def output/floorplan.def

# 2. Define Global Connections
# Connect the logic power
add_global_connection -net VDD -pin_pattern VPWR -power
add_global_connection -net VSS -pin_pattern VGND -ground
# Connect the SRAM power
add_global_connection -net VDD -pin_pattern vccd1 -power
add_global_connection -net VSS -pin_pattern vssd1 -ground

set_voltage_domain -name CORE -power VDD -ground VSS

# 3. Define the Grid
# Met1 rails provide power to every single row of standard cells
define_pdn_grid -name stdcell_grid -starts_with POWER
add_pdn_stripe -grid stdcell_grid -layer met1 -width 0.48 -pitch 5.44 -offset 0

# Met4 stripes provide the "backbone" of the power
# We use a 27.2 pitch to ensure a strap lands near or over the macros
add_pdn_stripe -grid stdcell_grid -layer met4 -width 1.6 -pitch 27.2 -offset 13.6

add_global_connection -net VDD -pin_pattern vccd1 -power
add_global_connection -net VSS -pin_pattern vssd1 -ground   

# 4. CONNECT THE LAYERS (Crucial for a working chip)
# This drops vias between met1 and met4
add_pdn_connect -grid stdcell_grid -layers {met1 met4}

pdngen
write_def output/pdn.def
EOF
        ;; # End of pdn

        placement)
        echo "Running Global Placement for $DESIGN_NAME..."
        /home/manal/OpenROAD/build/install/bin/openroad -no_init <<EOF
# 1. Read Tech, Cells, Macros
read_lef /home/manal/OpenROAD/test/sky130hd/sky130hd.tlef
read_lef /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd.lef
read_lef ../macros/sky130_sram_1kbyte_1rw1r_32x256_8.lef
read_liberty /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd__tt_025C_1v80.lib
read_liberty ../macros/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib

# 2. Read the PDN DEF (Crucial: Placement needs the power grid info)
read_def output/pdn.def

# 3. Set Placement Density
# Since you have a large 900x900 die, 0.40 (40%) is very safe and easy to route.
set_global_placement_option -density 0.40

# 4. Execute Global Placement
global_placement

# This adds 2 sites of space between cells to make routing easier
set_placement_padding -global -left 2 -right 2

# Optimize Mirroring (Reduces wirelength by flipping cells)
optimize_mirroring

# 5. Detail Placement (Aligns cells to the rows/sites)
# This fixes overlaps and ensures every cell is on a legal 'unithd' site.
detailed_placement

# 6. Check for overlaps (Safety check)
check_placement -verbose

filler_placement "sky130_fd_sc_hd__fill_*"

write_def output/placement.def
EOF
        ;;

        sta)
        echo "Running Static Timing Analysis for $DESIGN_NAME..."
        /home/manal/OpenROAD/build/install/bin/openroad -no_init <<EOF
read_lef /home/manal/OpenROAD/test/sky130hd/sky130hd.tlef
read_lef /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd.lef
read_lef ../macros/sky130_sram_1kbyte_1rw1r_32x256_8.lef
read_liberty /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd__tt_025C_1v80.lib
read_liberty ../macros/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib

read_def output/placement.def
read_sdc ../pd/constraints.sdc

# Estimate parasitics based on placement (RC values)
set_wire_rc -layer met1
estimate_parasitics -placement

# Report timing
report_checks -path_delay max -format full_clock_expanded -digits 4
report_tns
report_wns
EOF
        ;;

        cts)
        echo "Running CTS..."
        /home/manal/OpenROAD/build/install/bin/openroad -no_init <<EOF
read_lef /home/manal/OpenROAD/test/sky130hd/sky130hd.tlef
read_lef /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd.lef
read_lef ../macros/sky130_sram_1kbyte_1rw1r_32x256_8.lef
read_liberty /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd__tt_025C_1v80.lib
read_liberty ../macros/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib
read_def output/placement.def
read_sdc ../pd/constraints.sdc

# 1. REMOVE OLD FILLERS (To make room for clock buffers)
remove_fillers

# 2. Synthesis of the tree
clock_tree_synthesis -root_buf sky130_fd_sc_hd__clkbuf_16 -buf_list "sky130_fd_sc_hd__clkbuf_2 sky130_fd_sc_hd__clkbuf_4 sky130_fd_sc_hd__clkbuf_8"

# 3. Re-legalize placement because new buffers were added
detailed_placement

# 4. RE-ADD FILLERS (To bridge the power rails again)
filler_placement "sky130_fd_sc_hd__fill_*"

# Report CTS Metrics
report_clock_skew -clock clk
report_cts -out_file output/cts_report.txt

# 5. Save the result
write_def output/cts.def
EOF
        ;;

        route)
        echo "Running Global and Detailed Routing..."
        /home/manal/OpenROAD/build/install/bin/openroad -no_init <<EOF
        
read_lef /home/manal/OpenROAD/test/sky130hd/sky130hd.tlef
read_lef /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd.lef
read_lef ../macros/sky130_sram_1kbyte_1rw1r_32x256_8.lef
read_liberty /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd__tt_025C_1v80.lib
read_liberty ../macros/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib
read_def output/cts.def

# 1. Fix the Net Type Error     
#set_net_type -type SIGNAL {cpu_inst/zero_}

# 2. REDEFINE TRACKS (Fixes GRT-0701)
# We must define tracks for ALL layers used in Sky130
make_tracks li1  -x_offset 0.17 -x_pitch 0.34 -y_offset 0.17 -y_pitch 0.34

make_tracks met1 -x_offset 0.17 -x_pitch 0.34 -y_offset 0.17 -y_pitch 0.34
make_tracks met2 -x_offset 0.23 -x_pitch 0.46 -y_offset 0.23 -y_pitch 0.46
make_tracks met3 -x_offset 0.34 -x_pitch 0.68 -y_offset 0.34 -y_pitch 0.68
make_tracks met4 -x_offset 0.46 -x_pitch 0.92 -y_offset 0.46 -y_pitch 0.92 

make_tracks met5 -x_offset 1.70 -x_pitch 3.40 -y_offset 1.70 -y_pitch 3.40

# 3. Set Routing Constraints
set_routing_layers -signal li1-met5 -clock li1-met5

# 4. Global Routing (The 'Flight Plan')
# This organizes where wires should go to avoid traffic jams.
global_route -guide_file output/route.guide -congestion_iterations 100
#just the command "global_route" will suffice/use the default settings, but we can specify more options if needed:

# 5. Detailed Routing (The actual metal drawing)
# Using the flags from openroad documentation:
detailed_route -output_drc output/drc.log -verbose 1

# 6. Final Report
report_wire_length -detailed_route -summary

# 7. Save the final routed design
write_def output/routed.def
EOF
        ;;

    *)
#Usage message
        echo "Usage: $0 --step {synth|floorplan|pdn|placement|sta|cts|route}"
        ;;
esac