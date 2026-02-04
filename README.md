Component,Status
Software,"Done (93 bytes, fits 1KB)"
Logic (RTL),"Done (Pipelined Interconnect, Handshake fixed)"
Simulation,"Done (Verified ""Hello World"" in terminal)"
Physical (PD),"In Progress (Synthesis passing, Floorplan next)"
 
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
