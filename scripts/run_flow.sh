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
        yosys -c "../pd/synth.tcl" 
        ;; # End of synth

    floorplan)
        echo "Running OpenROAD Floorplan for $DESIGN_NAME..."
        mkdir -p output
        /home/manal/OpenROAD/build/install/bin/openroad -no_init <<EOF

source ../pd/openroad_vars.tcl
read_lef /path/to/tech.lef

# 1. Read Tech LEF and Standard Cell LEF
read_lef /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd.tlef
read_lef /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd.lef

# 2. READ SRAM MACRO LEF (CRITICAL)
read_lef ../macros/sky130_sram_1kbyte_1rw1r_32x256_8.lef

# 3. Read Libs (Standard Cells + SRAM)
read_liberty /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd__tt_025C_1v80.lib
read_liberty ../macros/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib

read_verilog output/synth.v
link_design $DESIGN_NAME

initialize_floorplan -die_area "$DIE_AREA" \
                     -core_area "10 10 590 590" \
                     -site "$PLACE_SITE"

# 4. PLACE THE MACROS (Otherwise they stay at 0,0)
# Adjust these coordinates so they are inside your 600x600 area
place_cell -inst imem_inst/sram_macro -origin 50 50 -orient R0
place_cell -inst dmem_inst/sram_macro -origin 350 350 -orient R0

# 5. Apply your pin configuration
place_pins -hor_layers met3 -ver_layers met2 -cfg ../pd/pin_order.cfg

write_def output/floorplan.def
EOF
        ;; # End of floorplan

    pdn)
        echo "Generating Power Distribution Network (PDN)..."
        openroad -no_init <<EOF
read_lef /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd.tlef
read_lef /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd.lef
read_def output/floorplan.def

add_global_connection -net VDD -pin_pattern VPWR -power
add_global_connection -net VSS -pin_pattern VGND -ground

set_voltage_domain -name CORE -power VDD -ground VSS

define_pdn_grid -name stdcell_grid -starts_with POWER
add_pdn_stripe -grid stdcell_grid -layer met1 -width 0.48 -pitch 5.44 -offset 0
add_pdn_stripe -grid stdcell_grid -layer met4 -width 1.6 -pitch 27.2 -offset 13.6

add_global_connection -net VDD -pin_pattern vccd1 -power
add_global_connection -net VSS -pin_pattern vssd1 -ground   

pdngen
write_def output/pdn.def
EOF
        ;; # End of pdn

    *)
        echo "Usage: $0 --step {synth|floorplan|pdn}"
        ;;
esac