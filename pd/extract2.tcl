gds read /home/manal/projects/RiscV-mini-SoC/pd/output/mini_soc_top.gds
load mini_soc_top
port makeall
select top cell
extract all
ext2spice lvs
ext2spice subcircuit top on
ext2spice global off
ext2spice
quit
