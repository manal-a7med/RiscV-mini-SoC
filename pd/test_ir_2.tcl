read_lef /home/manal/OpenROAD/test/sky130hd/sky130hd.tlef
read_lef /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd.lef
read_lef ../macros/sky130_sram_1kbyte_1rw1r_32x256_8.lef
read_liberty /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd__tt_025C_1v80.lib
read_liberty ../macros/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib
read_db output/signoff.odb

# Remove all fillers
remove_fillers

# Also let's run global_route so that the Routing Congestion heatmap is populated!!
# Wait, if we use output/routed.odb or signoff.odb, we shouldn't run global_route unless it doesn't break anything. 
# actually let's just do global_route -congestion_iterations 0? No, just global_route.
global_route

set_power_activity -global -activity 0.2
analyze_power_grid -net VDD
analyze_power_grid -net VSS

puts "IR DROP TEST COMPLETE"
