read_db output/signoff.odb
read_sdc ../pd/constraints.sdc
set_propagated_clock [all_clocks]

set block [[[::ord::get_db] getChip] getBlock]

puts "Running check_power_grid for VDD..."
catch {check_power_grid -net VDD -error_file psm_vdd.err}
puts "Running check_power_grid for VSS..."
catch {check_power_grid -net VSS -error_file psm_vss.err}

# Parse the error files - Wait, are they generated?
puts "Done."
