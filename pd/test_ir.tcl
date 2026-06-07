read_lef /home/manal/OpenROAD/test/sky130hd/sky130hd.tlef
read_lef /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd.lef
read_lef ../macros/sky130_sram_1kbyte_1rw1r_32x256_8.lef
read_liberty /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd__tt_025C_1v80.lib
read_liberty ../macros/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib
read_db output/signoff.odb

# Attempt to delete all FILLERs to see if it fixes PSM-0069
foreach inst [get_cells FILLER_*] {
    db::delete_cell [set [db::get_cell $inst]] # no wait it's not db::get_cell. wait
}
