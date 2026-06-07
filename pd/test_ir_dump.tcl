read_lef /home/manal/OpenROAD/test/sky130hd/sky130hd.tlef
read_lef /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd.lef
read_lef ../macros/sky130_sram_1kbyte_1rw1r_32x256_8.lef
read_liberty /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd__tt_025C_1v80.lib
read_liberty ../macros/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib
read_db output/signoff.odb
read_sdc ../pd/constraints.sdc
set_propagated_clock [all_clocks]
set_power_activity -global -activity 0.2
catch {analyze_power_grid -net VDD -error_file psm_err_vdd.txt}
catch {analyze_power_grid -net VSS -error_file psm_err_vss.txt}
