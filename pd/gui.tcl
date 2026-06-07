read_lef /home/manal/OpenROAD/test/sky130hd/sky130hd.tlef
read_lef /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd.lef
read_lef ../macros/sky130_sram_1kbyte_1rw1r_32x256_8.lef

read_liberty /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd__tt_025C_1v80.lib
read_liberty ../macros/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib

read_db output/signoff_gui.odb

# Restore Timing
read_sdc ../pd/constraints.sdc
set_propagated_clock [all_clocks]
set_wire_rc -signal -layer met2
set_wire_rc -clock -layer met3
estimate_parasitics -placement

# Re-generate Routing Congestion Heatmap (Does not overwrite Detailed Routing physically)
global_route

# Run Power Analysis to populate "IR Drop" heat map
# Default toggle rate of 0.2 (20%) is standard for global power analysis
set_power_activity -global -activity 0.2
catch { redirect -file /dev/null { analyze_power_grid -net VDD } }
catch { redirect -file /dev/null { analyze_power_grid -net VSS } }

puts "=========================================================="
puts "GUI Successfully Loaded with Timing and IR Drop Data!"
puts "You can now select Window -> Timing Report to view timing."
puts "To view Heatmaps, check the 'Heat Maps' box on the left."
puts "=========================================================="
