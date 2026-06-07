# Tell netgen to ignore filler cells
foreach cell {sky130_fd_sc_hd__fill_1 sky130_fd_sc_hd__fill_2 
              sky130_fd_sc_hd__fill_4 sky130_fd_sc_hd__fill_8} {
    ignore_cell $cell
}

# Treat SRAM as black box — don't descend into it
blackbox sky130_sram_1kbyte_1rw1r_32x256_8
