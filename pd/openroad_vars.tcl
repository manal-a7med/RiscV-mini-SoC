# pd/openroad_vars.tcl

# Define the library and technology
set std_cell_library "sky130_fd_sc_hd"

# Layer constraints (Sky130 usually uses 5 metal layers)
set min_routing_layer "met1"
set max_routing_layer "met5"

# Placement density (since you chose 40% in config.mk)
set placement_density 0.40

# Macro spacing (Prevents standard cells from being placed too close to SRAM pins)
set macro_halo 10
set macro_channel_width 20

# Clock Tree Synthesis (CTS) settings
set cts_buffer "sky130_fd_sc_hd__clkbuf_1"