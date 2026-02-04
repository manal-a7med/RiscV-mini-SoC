#pd/constraints.sdc

# Define the clock: 50MHz -> 20ns period
create_clock -name clk -period 20.0000 [get_ports {clk}]

# Set clock uncertainty (safety margin for jitter/skew)
set_clock_uncertainty 0.2500 [get_clocks {clk}]

# Set constraints for Input pins (Reset and UART RX)
# Assume 20% of the clock period is consumed outside the chip
set_input_delay -clock [get_clocks {clk}] 4.0000 [get_ports {reset_n}]
set_input_delay -clock [get_clocks {clk}] 4.0000 [get_ports {uart_rx}]

# Set constraints for Output pins (UART TX and Trap)
set_output_delay -clock [get_clocks {clk}] 4.0000 [get_ports {uart_tx}]
set_output_delay -clock [get_clocks {clk}] 4.0000 [get_ports {trap}]
# Set load on output pins (Standard for Sky130)
set_load 0.0334 [all_outputs]

# Avoid buffering the reset net too much initially
set_drive 0.1 [all_inputs]
set_load  0.1 [all_outputs]


