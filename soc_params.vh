// rtl/include/soc_params.vh

// 4KB = 0x1000 bytes
`define MEM_INST_BASE   32'h0000_0000
`define MEM_INST_LIMIT  32'h0000_0FFF 

`define MEM_DATA_BASE   32'h0001_0000
`define MEM_DATA_LIMIT  32'h0001_0FFF 

// Peripheral addresses remain the same
`define UART_BASE       32'h1000_0000
`define TIMER_BASE      32'h1000_1000

// Clock Info
`define CPU_FREQ_MHZ    50