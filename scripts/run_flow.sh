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
        source ../pd/synth.tcl
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

initialize_floorplan -die_area {0 0 1500 1500} -core_area {30 30 1470 1470} -site "unithd"

# 2. CREATE TRACKS (Crucial fix for PPL-0022)

make_tracks li1  -x_offset 0.17 -x_pitch 0.34 -y_offset 0.17 -y_pitch 0.34

make_tracks met1 -x_offset 0.17 -x_pitch 0.34 -y_offset 0.17 -y_pitch 0.34
make_tracks met2 -x_offset 0.23 -x_pitch 0.46 -y_offset 0.23 -y_pitch 0.46
make_tracks met3 -x_offset 0.34 -x_pitch 0.68 -y_offset 0.34 -y_pitch 0.68

make_tracks met4 -x_offset 0.46 -x_pitch 0.92 -y_offset 0.46 -y_pitch 0.92
make_tracks met5 -x_offset 1.70 -x_pitch 3.40 -y_offset 1.70 -y_pitch 3.40

# 4. PLACE THE MACROS (Otherwise they stay at 0,0)

#place_macro -macro_name imem_inst/sram_macro -location {100 100} -orientation R0 -exact
#place_macro -macro_name dmem_inst/sram_macro -location {1400 100} -orientation R0 -exact

# Replace manual place_macro commands with this:
#rtl_macro_placer -max_num_macro 2 -min_num_macro 1 -halo_width 20 -halo_height 20 -target_util 0.40 -report_directory output/rtlmp_reports -write_macro_placement output/rtlmp_reports/macro_placement.tcl
source output/rtlmp_reports/macro_placement.tcl

# 6. Pin Placement
# Since -config/-cfg failed, we follow the doc's tip: 
# place individual critical pins first, then let the tool handle the rest.
place_pin -pin_name clk -layer met3 -location {0 1000} -force_to_die_boundary
place_pin -pin_name reset_n -layer met3 -location {0 1100} -force_to_die_boundary

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
add_pdn_stripe -grid stdcell_grid -layer met4 -width 1.6 -pitch 40 -offset 20

# Met5: Global Horizontal "Highways" (Critical for 2000um span)
# These carry the bulk of the current from the chip edges
add_pdn_stripe -grid stdcell_grid -layer met5 -width 2.4 -pitch 60 -offset 30.0

add_pdn_ring -grid stdcell_grid -layers {met4 met5} -widths {3 3} -spacings {1.6 1.6} -core_offsets {10 10}

# 4. CONNECT THE LAYERS (Crucial for a working chip)
# This drops vias between met1 and met4
add_pdn_connect -grid stdcell_grid -layers {met1 met4}
# Connect met4 vertical stripes to met5 horizontal highways
add_pdn_connect -grid stdcell_grid -layers {met4 met5}

pdngen
write_def output/pdn.def
EOF
        ;; # End of pdn

        placement)
        echo "Running Global Placement for $DESIGN_NAME..."
        /home/manal/OpenROAD/build/install/bin/openroad -no_init <<EOF


read_lef /home/manal/OpenROAD/test/sky130hd/sky130hd.tlef
read_lef /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd.lef
read_lef ../macros/sky130_sram_1kbyte_1rw1r_32x256_8.lef
read_liberty /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd__tt_025C_1v80.lib
read_liberty ../macros/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib

read_def output/pdn.def

#place_macro -macro_name {dmem_inst/sram_macro} -location {80.04 1000.64} -orientation MY
#place_macro -macro_name {imem_inst/sram_macro} -location {80.04 80.64} -orientation MY
#set_macro_halo -inst imem_inst/sram_macro -halo {10 10 10 10}
#set_macro_halo -inst dmem_inst/sram_macro -halo {10 10 10 10}
#source output/rtlmp_reports/macro_placement.tcl

# 4. Execute Global Placement
global_placement -density 0.10 -pad_left 2 -pad_right 2

#set_placement_padding -masters "sky130_fd_sc_hd__*" -left 2 -right 2

# 1. Insert Tie-Cells (This replaces 'zero_' with real cells)
insert_tiecells sky130_fd_sc_hd__conb_1/HI -prefix "TIE_HIGH_"
insert_tiecells sky130_fd_sc_hd__conb_1/LO -prefix "TIE_LOW_"

# Optimize Mirroring (Reduces wirelength by flipping cells)
optimize_mirroring

#remove_fillers

# 2. Re-legalize because we just added new cells to the design
detailed_placement

filler_placement "sky130_fd_sc_hd__fill_*"

# 6. Check for overlaps (Safety check)
check_placement -verbose

write_def output/placement.def
write_db output/placement.odb
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

# 1. REMOVE OLD FILLERS (To make room for clock buffers)
remove_fillers

# 2. Setup Timing Constraints
read_sdc ../pd/constraints.sdc

set_wire_rc -clock -layer met3
set_wire_rc -signal -layer met2

# 2. Synthesis of the tree
clock_tree_synthesis -root_buf sky130_fd_sc_hd__clkbuf_16 -buf_list "sky130_fd_sc_hd__clkbuf_4 sky130_fd_sc_hd__clkbuf_8 sky130_fd_sc_hd__clkbuf_16"

repair_timing
#the above command fixed our major tiining errors WNS = -9.02 -> +0.204 and TNS = -4183 -> 0.0 AND VIOLATING_ENDPOINTS = 1392 ->0;
#HOLD values turned out to be positve and <1ns, so we are good on that front.
#setup and hold violations are now fixed, but we have 0.204ns of slack on the critical path, which is more than enough for our 20ns clock period. We can proceed to routing with confidence that our design will meet timing.
#setup and hold skew are +0.35 and -0.32 respectively. (ideal/ managable is <0.5ns)

remove_fillers
# 3. Re-legalize placement because new buffers were added
detailed_placement
check_placement
estimate_parasitics -placement
repair_design

# 4. RE-ADD FILLERS (To bridge the power rails again)
filler_placement "sky130_fd_sc_hd__fill_*"

# Report CTS Metrics
report_clock_skew -setup -clock clk
report_clock_skew -hold -clock clk

report_cts -out_file output/cts_report.txt
report_checks -path_delay min_max -group_path_count 5
#report_parasitics 
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
read_sdc constraints.sdc

set_wire_rc -signal -layer met2
set_wire_rc -clock  -layer met3

# 2. REDEFINE TRACKS (Fixes GRT-0701)
# We must define tracks for ALL layers used in Sky130
make_tracks li1  -x_offset 0.17 -x_pitch 0.34 -y_offset 0.17 -y_pitch 0.34

make_tracks met1 -x_offset 0.17 -x_pitch 0.34 -y_offset 0.17 -y_pitch 0.34
make_tracks met2 -x_offset 0.23 -x_pitch 0.46 -y_offset 0.23 -y_pitch 0.46
make_tracks met3 -x_offset 0.34 -x_pitch 0.68 -y_offset 0.34 -y_pitch 0.68

make_tracks met4 -x_offset 0.46 -x_pitch 0.92 -y_offset 0.46 -y_pitch 0.92
make_tracks met5 -x_offset 1.70 -x_pitch 3.40 -y_offset 1.70 -y_pitch 3.40

#set_global_routing_layer_adjustment li1 0.05
set_global_routing_layer_adjustment met1 0.4
set_global_routing_layer_adjustment met2 0.6
set_global_routing_layer_adjustment met3-met5 0.8

# 3. Set Routing Constraints
set_routing_layers -signal met1-met5 
set_routing_layers -clock met3-met5


#set_macro_extension 2
#remove_fillers
# 4. Global Routing (The 'Flight Plan')
global_route
estimate_parasitics -global_routing

detailed_route -output_drc output/drc.log -verbose 1
repair_antennas "sky130_fd_sc_hd__diode_2"
detailed_route -output_drc output/drc.log -verbose 1 -droute_end_iter 64 -drc_report_iter_step 10

repair_timing
#filler_placement "sky130_fd_sc_hd__fill_*"
report_checks

# 6. Final Report
report_wire_length -detailed_route -summary
report_checks -path_delay max -format full_clock_expanded
report_tns
report_wns

write_def output/routed.def
write_db output/routed.odb

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

read_def output/routed.def
read_sdc ../pd/constraints.sdc
set_propagated_clock [all_clocks] 
#we want propageted clock and not ideal clock, because we want to see the effect of clock tree synthesis and routing on our timing. If we used ideal clocks, we would be ignoring the delays introduced by the clock buffers and the interconnect, which are critical to understanding the real performance of our design.

# Estimate parasitics based on placement (RC values)
set_wire_rc -signal -layer met2
set_wire_rc -clock  -layer met3

estimate_parasitics -placement

# Report timing
report_checks -path_delay max -format full_clock_expanded -digits 4
report_tns
report_wns
EOF
        ;;

        signoff)
        echo "Running Post-Route Sign-off STA..."
        /home/manal/OpenROAD/build/install/bin/openroad -no_init <<EOF

# 1. Read the routed design
read_lef /home/manal/OpenROAD/test/sky130hd/sky130hd.tlef
read_lef /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd.lef
read_lef ../macros/sky130_sram_1kbyte_1rw1r_32x256_8.lef
read_liberty /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd__tt_025C_1v80.lib
read_liberty ../macros/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib

# 2. Extract Parasitics from the actual metal
read_def output/routed.def
read_sdc ../pd/constraints.sdc

set_propagated_clock [all_clocks]

set_wire_rc -signal -layer met2
set_wire_rc -clock -layer met3

estimate_parasitics -placement                 

# 3. Report Final Timing
report_checks -path_delay max -format full_clock_expanded
report_checks -path_delay min
report_tns
report_wns

report_design_area
report_clock_skew
report_power

write_verilog output/final_netlist.v
write_def output/final.def

write_db output/signoff.odb
EOF
        ;;

    *)
#Usage message
        echo "Usage: $0 --step {synth|floorplan|pdn|placement|cts|sta|route|signoff} --design DESIGN_NAME"
        ;;
esac