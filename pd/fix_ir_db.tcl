read_lef /home/manal/OpenROAD/test/sky130hd/sky130hd.tlef
read_lef /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd.lef
read_lef ../macros/sky130_sram_1kbyte_1rw1r_32x256_8.lef
read_liberty /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd__tt_025C_1v80.lib
read_liberty ../macros/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib
read_db output/signoff.odb
read_sdc ../pd/constraints.sdc
set_propagated_clock [all_clocks]

puts "Injecting visualization short-grid..."
add_pdn_stripe -grid stdcell_grid -layer met4 -width 1.6 -pitch 5 -offset 5
add_pdn_connect -grid stdcell_grid -layers {met1 met4}
pdngen

write_db output/signoff_gui.odb
puts "GUI database generated."
