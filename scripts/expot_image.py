import pya

# Setup paths
layout = pya.Layout()
main_window = pya.Application.instance().main_window()

# Load LEFs and DEF
# Ensure these paths match your local OpenROAD installation
# Use absolute paths or correct relative paths from where you run the command
lefs = [
    "/home/manal/OpenROAD/test/sky130hd/sky130hd.tlef",
    "/home/manal/OpenROAD/test/sky130hd/sky130_fd_sc_hd.lef",
    "/home/manal/projects/RiscV-mini-SoC/macros/sky130_sram_1kbyte_1rw1r_32x256_8.lef"
]

cell_view = main_window.load_layout("/home/manal/projects/RiscV-mini-SoC/pd/output/routed.def", 0)
view = cell_view.view()

# Export a 4000x4000 pixel image for your presentation
view.zoom_fit()
view.save_image("MiniSoC_Final_Layout.png", 4000, 4000)
print("High-res layout exported to MiniSoC_Final_Layout.png")