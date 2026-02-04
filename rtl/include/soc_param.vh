// rtl/include/soc_params.vh

// 1 KB = 0x400 bytes
`define MEM_INST_BASE   32'h0000_0000
`define MEM_INST_LIMIT  32'h0000_03FF

`define MEM_DATA_BASE   32'h0001_0000
`define MEM_DATA_LIMIT  32'h0001_03FF

// Peripherals
`define UART_BASE       32'h1000_0000
`define TIMER_BASE      32'h1000_1000

// Clock
`define CPU_FREQ_MHZ    50

