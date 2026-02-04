`include "soc_param.vh"

module mini_soc_top (
    input  wire clk,
    input  wire reset_n,
    
    // UART Physical Pins
    output wire uart_tx,
    input  wire uart_rx,

    // Status Pin
    output wire trap
);

    // --- Internal Wires: CPU <-> Interconnect ---
    wire [31:0] cpu_addr;
    wire [31:0] cpu_wdata;
    wire [3:0]  cpu_wstrb;
    wire [31:0] cpu_rdata;
    wire        cpu_valid;
    wire        cpu_ready;
    wire        cpu_instr;

    // --- Internal Wires: Interconnect <-> Peripherals ---

    wire imem_cs_wire;
    wire dmem_cs_wire;
    
    wire [31:0] imem_addr, imem_rdata;
    wire [31:0] dmem_addr, dmem_wdata, dmem_rdata;
    wire [3:0]  dmem_wstrb;
    
    wire [31:0] uart_addr, uart_wdata, uart_rdata;
    wire        uart_we, uart_ready;
    
    wire [31:0] timer_addr, timer_wdata, timer_rdata;
    wire        timer_we, timer_ready;
    wire        timer_irq; // The "Provisioned" Interrupt Line

    // --- 1. CPU Instance (PicoRV32) ---
    picorv32 #(
        .ENABLE_IRQ(1),
        .PROGADDR_RESET(`MEM_INST_BASE), // Start at Instr Mem
        .STACKADDR(`MEM_DATA_LIMIT + 32'd1)       // Top of 4KB Data Mem
    ) cpu_inst (
        .clk      (clk),
        .resetn   (reset_n),
        .trap     (trap),
        .mem_valid(cpu_valid),
        .mem_instr(cpu_instr),
        .mem_ready(cpu_ready),
        .mem_addr (cpu_addr),
        .mem_wdata(cpu_wdata),
        .mem_wstrb(cpu_wstrb),
        .mem_rdata(cpu_rdata),
        // Connect Timer IRQ to bit 1 as discussed
        .irq      ({30'b0, timer_irq, 1'b0}) 
    );

    // --- 2. Interconnect Instance ---
    simple_interconnect bus_inst (
        .clk(clk), .reset_n(reset_n),
        .cpu_addr(cpu_addr), .cpu_wdata(cpu_wdata), .cpu_wstrb(cpu_wstrb),
        .cpu_valid(cpu_valid), .cpu_rdata(cpu_rdata), .cpu_ready(cpu_ready),
        
        .imem_addr(imem_addr), .imem_rdata(imem_rdata), .imem_cs(imem_cs_wire),
        
        .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata), .dmem_wstrb(dmem_wstrb),
        .dmem_rdata(dmem_rdata), .dmem_cs(dmem_cs_wire),
        
        .uart_addr(uart_addr), .uart_wdata(uart_wdata), .uart_we(uart_we),
        .uart_rdata(uart_rdata), .uart_ready(uart_ready),
        
        .timer_addr(timer_addr), .timer_wdata(timer_wdata), .timer_we(timer_we),
        .timer_rdata(timer_rdata), .timer_ready(timer_ready)
    );

    // --- 3. Memory & Peripheral Instances ---
    instr_mem imem_inst (
        .clk(clk), .addr(imem_addr), .rdata(imem_rdata), .cs(imem_cs_wire)
    );

    data_mem dmem_inst (
        .clk(clk), .addr(dmem_addr), .wdata(dmem_wdata), .we(|dmem_wstrb),
        .cs(dmem_cs_wire),   
        .wstrb(dmem_wstrb), .rdata(dmem_rdata)
    );

    uart_periph uart_inst (
        .clk(clk), .reset_n(reset_n),
        .addr(uart_addr), .wdata(uart_wdata), .we(uart_we),
        .rdata(uart_rdata), .ready(uart_ready), .tx(uart_tx), .rx(uart_rx)
    );

    timer_periph timer_inst (
        .clk(clk), .reset_n(reset_n),
        .addr(timer_addr), .wdata(timer_wdata), .we(timer_we),
        .rdata(timer_rdata), .ready(timer_ready), .irq(timer_irq)
    );

endmodule