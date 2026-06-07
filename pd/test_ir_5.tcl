read_lef /home/manal/OpenROAD/test/sky130hd/sky130hd.tlef
read_lef /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd.lef
read_lef ../macros/sky130_sram_1kbyte_1rw1r_32x256_8.lef
read_liberty /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd__tt_025C_1v80.lib
read_liberty ../macros/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib
read_db output/signoff.odb
read_sdc ../pd/constraints.sdc
set_propagated_clock [all_clocks]

add_pdn_stripe -grid stdcell_grid -layer met4 -width 1.6 -pitch 10 -offset 5
add_pdn_connect -grid stdcell_grid -layers {met1 met4}
pdngen

set_power_activity -global -activity 0.2
catch {check_power_grid -net VDD}
catch {check_power_grid -net VSS}

puts "Done testing dense pdn for GUI visualization."
