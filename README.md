Component,Status
   Software,"Done (93 bytes, fits 1KB)"\n  
   Logic (RTL),"Done (Pipelined Interconnect, Handshake fixed)"\n
   Simulation,"Done (Verified ""Hello World"" in terminal)"\n
   Physical (PD),"In Progress (Synthesis passing, Floorplan next)"\n
 
 RISC-V RV32I Mini SoC — RTL to GDSII using OpenROAD
 Project Overview

This project presents the design, verification, synthesis, and physical implementation of a lightweight RISC-V (RV32I) Mini System-on-Chip (SoC) using a fully open-source ASIC flow.

The SoC integrates a 32-bit RV32I processor core, on-chip instruction and data memories, and basic peripherals such as UART and Timer.
The complete design is taken from Register Transfer Level (RTL) to GDSII using Yosys and OpenROAD, targeting the SKY130 (130 nm) open PDK.

This project emphasizes hands-on VLSI design, clean RTL hierarchy, and realistic physical-design closure rather than post-hoc analysis.

SoC Architecture
High-Level Block Diagram

                 ┌──────────────┐
                 │   RV32I CPU  │
                 │ (PicoRV32)   │
                 └──────┬───────┘
                        │
               ┌────────▼────────┐
               │ Simple Bus /     │
               │ Address Decode   │
               └──┬──────┬──────┬┘
                  │      │      │
        ┌─────────▼─┐ ┌──▼───┐ ┌▼────────┐
        │ Instr Mem │ │ UART │ │  Timer  │
        └───────────┘ └──────┘ └─────────┘
                  │
            ┌─────▼─────┐
            │ Data Mem  │
            └───────────┘
✔ Single-core
✔ Single clock domain
✔ Memory-mapped peripherals
✔ Fully synthesizable RTL

Key Features
RV32I CPU Core (PicoRV32 / Ibex-style)
Synthesized Instruction Memory (IMEM)
Synthesized Data Memory (DMEM)
UART Peripheral for serial communication
Timer Peripheral with programmable registers
Simple Memory-Mapped Interconnect
RTL → GDSII Flow using OpenROAD
SKY130 130 nm Technology

Memory Map
| Address Range               | Function                   |
| --------------------------- | -------------------------- |
| `0x0000_0000 – 0x0000_3FFF` | Instruction Memory (16 KB) |
| `0x0001_0000 – 0x0001_3FFF` | Data Memory (16 KB)        |
| `0x1000_0000`               | UART Data Register         |
| `0x1000_0004`               | UART Status Register       |
| `0x1000_0008`               | UART Baud Control          |
| `0x1000_1000`               | Timer Count Register       |
| `0x1000_1004`               | Timer Compare Register     |
| `0x1000_1008`               | Timer Control Register     |

Project Directory Structure
riscv-mini-soc/
├── rtl/            # RTL design files
├── sim/            # Testbench and RTL simulation
├── sw/             # Bare-metal software
├── synth/          # Yosys synthesis scripts
├── pd/             # OpenROAD physical design
├── scripts/        # Build automation scripts
└── docs/           # Diagrams, screenshots, report

Design Flow
1️⃣ RTL Design
Modular, hierarchical RTL
Single synchronous clock
No inferred latches
2️⃣ Functional Verification
RTL simulation using testbench
Bare-metal programs for:
CPU boot
UART output
Timer operation
3️⃣ Logic Synthesis
Tool: Yosys
Target frequency: 50–100 MHz
Positive timing slack achieved post-synthesis
4️⃣ Physical Design
Tool: OpenROAD
Steps:
Floorplanning
Placement
Clock Tree Synthesis (CTS)
Routing
Sign-off checks

Physical Design Targets & Results
| Metric           | Value             |
| ---------------- | ----------------- |
| Technology       | SKY130 (130 nm)   |
| Standard Cells   | `sky130_fd_sc_hd` |
| Target Frequency | 50–100 MHz        |
| Gate Count       | ~50k–75k          |
| Core Area        | ~0.4–0.55 mm²     |
| WNS (Post-Route) | ≥ 0 ns            |
| TNS (Post-Route) | 0 ns              |
| DRC / LVS        | Clean             |


Verification Strategy
RTL simulation with memory read/write tests
UART “Hello World” output
Timer register validation
Waveform-based debugging

Tools Used
| Tool                    | Purpose             |
| ----------------------- | ------------------- |
| Verilog / SystemVerilog | RTL design          |
| Yosys                   | Logic synthesis     |
| OpenROAD                | Physical design     |
| SKY130 PDK              | Technology          |
| GTKWave                 | Waveform viewing    |
| RISC-V GCC              | Bare-metal software |


Educational Value
This project demonstrates:
End-to-end ASIC design flow
Clean SoC-level integration
Practical timing closure
Open-source VLSI tooling proficiency

It is well-suited for:
VLSI term projects
ASIC design coursework
RTL → GDSII learning

How to Build (Example)
# Run RTL simulation
./scripts/run_sim.sh

# Run synthesis
./scripts/run_yosys.sh

# Run physical design
./scripts/run_openroad.sh

Future Extensions
Replace synthesized memory with OpenRAM SRAM
Add SPI or I2C peripheral
Integrate simple accelerator
Power analysis and optimization


Project Status Update
RISC-V RV32I Mini SoC — RTL to GDSII using OpenROAD
Project Overview

This project presents the design, verification, synthesis, and physical implementation of a lightweight RISC-V (RV32I) Mini System-on-Chip (SoC). The design has been successfully taken from RTL to a fully routed 2000μm x 2000μm physical layout using the SKY130 (130 nm) open PDK.
SoC Architecture
The SoC integrates a PicoRV32 CPU core with a simple memory-mapped interconnect. Unlike the initial plan for synthesized memory, the current implementation utilizes Hardened SRAM Macros for Instruction and Data storage to emulate realistic industrial ASIC design.
Key Features
    CPU Core: PicoRV32 (RV32I).
    Memory: Dual 1KB 1RW1R SRAM Macros (Sky130 OpenRAM).
    Peripherals: UART for serial debug and a Programmable Timer.
    Physical Area: Large-scale 4 mm² die to ensure high routability and signal integrity.
    Logic Constants: Handled via physical Tie-Low/Tie-High cell insertion to ensure DRC compliance.

Physical Design Targets & Results
Physical Design Strategy (The "Tapeout" Flow)
    Synthesis: Performed using Yosys, achieving a clean netlist for the PicoRV32 and peripherals.
    Floorplanning: Scaled to 2000μm to accommodate SRAM macros with 30μm halos to prevent pin congestion.
    PDN (Power Grid): Robust multi-layer grid using met1, met4, and met5 to minimize IR drop across the 2mm span.
    Placement: Global and detailed placement at 20% density with 6-site padding to clear local interconnect (li1) spacing.
    CTS: Clock tree synthesis utilizing clkbuf_8 and clkbuf_16 to drive the clock signal across the large die.
    Routing: Global and detailed routing successfully managed 86,921 vias and over half a meter of copper wiring.

Educational Value & Outcomes
    Troubleshooting: Demonstrated proficiency in resolving complex tool errors, including DRT-0305 (Ground net signal type) and EST-0005 (Parasitic estimation mismatch).
    Infrastructure: Successfully recompiled OpenROAD with Qt5 GUI support on a Linux/Ubuntu environment (Lenovo LOQ).
    Analysis: Performed post-route Sign-off STA and Power Analysis, identifying that 60.8% of consumption is driven by combinational logic.

Future Extensions
    DRC Closure: Implement Antenna Diode insertion to clear remaining 90 metal spacing violations.
    GDSII Export: Generate final stream-out for foundry submission.
    Optimization: Re-run flow with increased density to reduce total wire length and parasitic capacitance.
    
    34.5 mW power results and 2000µm layout.
