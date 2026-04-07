gds read /home/manal/projects/RiscV-mini-SoC/pd/output/mini_soc_top.gds
load mini_soc_top
select top cell
extract all
ext2spice lvs
ext2spice
quit
