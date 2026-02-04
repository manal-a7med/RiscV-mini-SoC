`include "soc_param.vh"

module simple_interconnect (
    // ... (Your existing IO ports remain exactly the same)
    input wire clk,
    input wire reset_n,
    input  wire [31:0] cpu_addr,
    input  wire [31:0] cpu_wdata,
    input  wire [3:0]  cpu_wstrb,
    input  wire        cpu_valid,
    output reg  [31:0] cpu_rdata,
    output reg         cpu_ready,
    output wire [31:0] imem_addr,
    input  wire [31:0] imem_rdata,
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    output wire [3:0]  dmem_wstrb,
    input  wire [31:0] dmem_rdata,
    output wire [31:0] uart_addr,
    output wire [31:0] uart_wdata,
    output wire        uart_we,
    input  wire [31:0] uart_rdata,
    input  wire        uart_ready,
    output wire [31:0] timer_addr,
    output wire [31:0] timer_wdata,
    output wire        timer_we,
    input  wire [31:0] timer_rdata,
    input  wire        timer_ready
);

    // --- 1. Address Decoding Logic ---
    // Using 0x3FF (1023) for 1KB range
    wire is_imem  = (cpu_addr >= `MEM_INST_BASE) && (cpu_addr <= (`MEM_INST_BASE + 32'h0000_03FF));
    wire is_dmem  = (cpu_addr >= `MEM_DATA_BASE) && (cpu_addr <= (`MEM_DATA_BASE + 32'h0000_03FF));
    wire is_uart  = (cpu_addr >= `UART_BASE)  && (cpu_addr <= (`UART_BASE  + 32'h0000_000F));
    wire is_timer = (cpu_addr >= `TIMER_BASE) && (cpu_addr <= (`TIMER_BASE + 32'h0000_000F));

    // --- NEW: Ready Delay Logic ---
    // This creates the 1-cycle wait required for synchronous memory
    reg ready_delayed;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) 
            ready_delayed <= 1'b0;
        else 
            ready_delayed <= cpu_valid; 
    end

    // --- 2. Peripheral Chip Selects ---
    assign imem_addr   = cpu_addr;
    assign dmem_addr   = cpu_addr;
    assign dmem_wdata  = cpu_wdata;
    assign dmem_wstrb  = is_dmem ? cpu_wstrb : 4'b0000;
    assign uart_addr   = cpu_addr;
    assign uart_wdata  = cpu_wdata;
    assign uart_we     = is_uart && (|cpu_wstrb);
    assign timer_addr  = cpu_addr;
    assign timer_wdata = cpu_wdata;
    assign timer_we    = is_timer && (|cpu_wstrb);

    // --- 3. Read Data Multiplexer ---
    always @(*) begin
        cpu_rdata = 32'h0000_0000; // Explicit default driver
        if (is_imem)       cpu_rdata = imem_rdata;
        else if (is_dmem)  cpu_rdata = dmem_rdata;
        else if (is_uart)  cpu_rdata = uart_rdata;
        else if (is_timer) cpu_rdata = timer_rdata;
    end

    // --- 4. Updated 'Wait' / Ready Handshake ---
    always @(*) begin
        cpu_ready = 1'b0; // Explicit default driver
        if (!cpu_valid) begin
            cpu_ready = 1'b0;
        end else begin
            case (1'b1)
                // We use ready_delayed here to give memory 1 cycle to respond
                is_imem:  cpu_ready = ready_delayed; 
                is_dmem:  cpu_ready = ready_delayed;
                is_uart:  cpu_ready = uart_ready;   
                is_timer: cpu_ready = timer_ready;  
                default:  cpu_ready = 1'b1;         
            endcase
        end
    end

`ifndef SYNTHESIS
    always @(posedge clk) begin
        if (cpu_valid && cpu_ready) begin
            $display("TIME: %t | ADDR: %h | DATA: %h", $time, cpu_addr, cpu_rdata);
        end
    end
`endif 


endmodule