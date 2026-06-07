#!/bin/bash
cd /home/manal/projects/RiscV-mini-SoC/pd

# 1. Run openroad to dump the PSM-0039 warnings for VDD and VSS
cat << 'TCL_EOF' > /tmp/dump_psm.tcl
read_lef /home/manal/OpenROAD/test/sky130hd/sky130hd.tlef
read_lef /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd.lef
read_lef ../macros/sky130_sram_1kbyte_1rw1r_32x256_8.lef
read_liberty /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd__tt_025C_1v80.lib
read_liberty ../macros/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib
read_db output/signoff.odb
read_sdc constraints.sdc
set_propagated_clock [all_clocks]
set_power_activity -global -activity 0.2
catch {analyze_power_grid -net VDD}
catch {analyze_power_grid -net VSS}
TCL_EOF

echo "Dumping PSM warnings..."
/home/manal/OpenROAD/build/install/bin/openroad -no_init /tmp/dump_psm.tcl > /tmp/psm_dump.log 2>&1

# 2. Extract instance names
grep "PSM-0039" /tmp/psm_dump.log | awk '{print $4}' | awk -F'/' '{print $1}' | sort | uniq > /tmp/psm_unconnected.txt

# 3. Create deletion TCL script
cat << 'TCL_EOF' > /tmp/delete_psm.tcl
read_lef /home/manal/OpenROAD/test/sky130hd/sky130hd.tlef
read_lef /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd.lef
read_lef ../macros/sky130_sram_1kbyte_1rw1r_32x256_8.lef
read_liberty /home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd__tt_025C_1v80.lib
read_liberty ../macros/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib
read_db output/signoff.odb
set block [[[::ord::get_db] getChip] getBlock]
TCL_EOF

while read inst_name; do
    echo "set inst [\$block findInst \"$inst_name\"]" >> /tmp/delete_psm.tcl
    echo "if {\$inst != \"NULL\"} { odb::dbInst_destroy \$inst }" >> /tmp/delete_psm.tcl
done < /tmp/psm_unconnected.txt

echo "write_db output/signoff_gui.odb" >> /tmp/delete_psm.tcl

echo "Applying cleanups..."
/home/manal/OpenROAD/build/install/bin/openroad -no_init /tmp/delete_psm.tcl > /dev/null 2>&1
echo "Cleanup complete."

