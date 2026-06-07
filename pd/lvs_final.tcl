source /home/manal/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.tech/netgen/sky130A_setup.tcl

# Treat filler cells as black boxes with no pins
foreach cell {sky130_fd_sc_hd__fill_1 sky130_fd_sc_hd__fill_2
              sky130_fd_sc_hd__fill_4 sky130_fd_sc_hd__fill_8} {
    ignore_cell $cell
}

# Treat SRAM as black box
blackbox sky130_sram_1kbyte_1rw1r_32x256_8
