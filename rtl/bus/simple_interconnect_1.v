`include "soc_params.vh"

module simple_interconnect (
    input wire clk,
    input wire reset_n,

    // CPU Interface (PicoRV32 Native)
    input  wire [31:0] cpu_addr,
    input  wire [31:0] cpu_wdata,
    input  wire [3:0]  cpu_wstrb,
    input  wire        cpu_valid,
    output reg  [31:0] cpu_rdata,
    output reg         cpu_ready,

    // Instruction Memory Interface
    output wire [31:0] imem_addr,
    input  wire [31:0] imem_rdata,

    // Data Memory Interface
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    output wire [3:0]  dmem_wstrb,
    input  wire [31:0] dmem_rdata,

    // UART Interface
    output wire [31:0] uart_addr,
    output wire [31:0] uart_wdata,
    output wire        uart_we,
    input  wire [31:0] uart_rdata,
    input  wire        uart_ready,  // UART 'Wait' signal

    // Timer Interface
    output wire [31:0] timer_addr,
    output wire [31:0] timer_wdata,
    output wire        timer_we,
    input  wire [31:0] timer_rdata,
    input  wire        timer_ready  // Timer 'Wait' signal
);
    

    // --- 1. Address Decoding Logic ---
    // Using wire assignments for better timing (Mask & Compare)
    wire is_imem  = (cpu_addr >= `MEM_INST_BASE) && (cpu_addr <= `MEM_INST_LIMIT);
    wire is_dmem  = (cpu_addr >= `MEM_DATA_BASE) && (cpu_addr <= `MEM_DATA_LIMIT);
    //it was struggling with Aliasing here
    // Instead of bit-slicing, check if it's within the specific peripheral block (e.g., 16 bytes)
    wire is_uart  = (cpu_addr >= `UART_BASE)  && (cpu_addr <= (`UART_BASE  + 32'h0000_000F));
    wire is_timer = (cpu_addr >= `TIMER_BASE) && (cpu_addr <= (`TIMER_BASE + 32'h0000_000F));
//this is superior for Physical Design
//When you run OpenROAD, the synthesis tool (Yosys) will create "Magnitude Comparators."
//Timing: These paths are very fast.
//Safety: There is zero chance that the UART and Timer signals will "overlap."
//If you accidentally try to read an address like 0x1000_0500 (which is in the middle of nowhere),
//the cpu_ready signal will correctly stay low or your default case will catch it, preventing the CPU from reading garbage.

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
        if (is_imem)       cpu_rdata = imem_rdata;
        else if (is_dmem)  cpu_rdata = dmem_rdata;
        else if (is_uart)  cpu_rdata = uart_rdata;
        else if (is_timer) cpu_rdata = timer_rdata;
        else               cpu_rdata = 32'h0000_0000;
    end

    // --- 4. The 'Wait' / Ready Handshake ---
    // This is where you control the CPU stall logic
    always @(*) begin
        if (!cpu_valid) begin
            cpu_ready = 1'b0;
        end else begin
            case (1'b1)
                is_imem:  cpu_ready = 1'b1;         // IMEM is 1-cycle (Zero wait)
                is_dmem:  cpu_ready = 1'b1;         // DMEM is 1-cycle (Zero wait)
                is_uart:  cpu_ready = uart_ready;   // Stalls CPU until UART is ready
                is_timer: cpu_ready = timer_ready;  // Stalls CPU until Timer is ready
                default:  cpu_ready = 1'b1;         // Default ready to prevent hang
            endcase
        end
    end

endmodule