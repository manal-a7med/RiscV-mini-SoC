source /home/manal/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.tech/netgen/sky130A_setup.tcl

# Force top-level pin correspondence manually
# This tells netgen which layout net corresponds to which schematic pin
equate pins clk clk
equate pins reset_n reset_n
equate pins uart_rx uart_rx
equate pins uart_tx uart_tx
equate pins trap trap

# Ignore fillers (correct way)
permute default
property parallel enable

lvs blackbox sky130_sram_1kbyte_1rw1r_32x256_8
