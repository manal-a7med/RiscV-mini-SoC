`include "soc_param.vh"

module simple_interconnect (
    input  wire        clk,
    input  wire        reset_n,

    // CPU
    input  wire [31:0] cpu_addr,
    input  wire [31:0] cpu_wdata,
    input  wire [3:0]  cpu_wstrb,
    input  wire        cpu_valid,
    output reg  [31:0] cpu_rdata,
    output reg         cpu_ready,

    // Instruction memory
    output wire [31:0] imem_addr,
    output reg       imem_cs,
    input  wire [31:0] imem_rdata,

    // Data memory
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    output reg [3:0]  dmem_wstrb,
    output reg        dmem_cs,
    input  wire [31:0] dmem_rdata,

    // UART
    output wire [31:0] uart_addr,
    output wire [31:0] uart_wdata,
    output reg        uart_we,
    input  wire [31:0] uart_rdata,
    input  wire        uart_ready,

    // Timer
    output wire [31:0] timer_addr,
    output wire [31:0] timer_wdata,
    output reg        timer_we,
    input  wire [31:0] timer_rdata,
    input  wire        timer_ready
);

    // ------------------------------------------------------------
    // Address decode
    // ------------------------------------------------------------
    wire is_imem  = (cpu_addr >= `MEM_INST_BASE) &&
                    (cpu_addr <  `MEM_INST_BASE + 32'h400);

    wire is_dmem  = (cpu_addr >= `MEM_DATA_BASE) &&
                    (cpu_addr <  `MEM_DATA_BASE + 32'h400);

    wire is_uart  = (cpu_addr >= `UART_BASE) &&
                    (cpu_addr <  `UART_BASE + 32'h10);

    wire is_timer = (cpu_addr >= `TIMER_BASE) &&
                    (cpu_addr <  `TIMER_BASE + 32'h10);
    
    // Allow the CPU to read data from the IMEM range (for strings/constants)
    wire is_imem_access = (cpu_addr >= 32'h0000_0000) && (cpu_addr < 32'h0000_0400);
    wire is_dmem_access = (cpu_addr >= 32'h0001_0000) && (cpu_addr < 32'h0001_0400);

    // ------------------------------------------------------------
    // Forward buses (always driven)
    // ------------------------------------------------------------
    assign imem_addr   = cpu_addr;
    assign dmem_addr   = cpu_addr;
    assign dmem_wdata  = cpu_wdata;
    assign uart_addr   = cpu_addr;
    assign uart_wdata  = cpu_wdata;
    assign timer_addr  = cpu_addr;
    assign timer_wdata = cpu_wdata;

    //assign dmem_wstrb = (cpu_valid && is_dmem) ? cpu_wstrb : 4'b0000;
    //assign uart_we    = (cpu_valid && is_uart) && (|cpu_wstrb);
    //assign timer_we   = (cpu_valid && is_timer)&& (|cpu_wstrb);

    // Chip Selects: Only enable memory when the address matches and CPU is valid
    //assign imem_cs = cpu_valid && is_imem;
    //assign dmem_cs = cpu_valid && is_dmem;

    // ------------------------------------------------------------
    // PIPELINED MEMORY ACCESS (1-cycle latency)
    // ------------------------------------------------------------
    reg pending_imem;
    reg pending_dmem;
    reg pending_uart;
    reg pending_timer;

    always @(*) begin
        // --- DEFAULT VALUES (Crucial for Synthesis) ---
        imem_cs    = 1'b0;
        dmem_cs    = 1'b0;
        dmem_wstrb = 4'b0000;
        uart_we    = 1'b0;
        timer_we   = 1'b0;

        // --- ACTUAL LOGIC ---
        imem_cs = cpu_valid && is_imem;
        dmem_cs = cpu_valid && is_dmem;
        
        if (cpu_valid && is_dmem)  dmem_wstrb = cpu_wstrb;
        if (cpu_valid && is_uart)  uart_we    = (|cpu_wstrb);
        if (cpu_valid && is_timer) timer_we   = (|cpu_wstrb);
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            pending_imem  <= 1'b0;
            pending_dmem  <= 1'b0;
            pending_uart  <= 1'b0;
            pending_timer <= 1'b0;
        end else begin
            pending_imem  <= cpu_valid && is_imem;
            pending_dmem  <= cpu_valid && is_dmem;
            pending_uart  <= cpu_valid && is_uart;
            pending_timer <= cpu_valid && is_timer;
        end
    end

    // ------------------------------------------------------------
    // READ DATA MUX (uses pending selects)
    // ------------------------------------------------------------
    always @(*) begin
        cpu_rdata = 32'h0;
        if (pending_imem)
            cpu_rdata = imem_rdata;
        else if (pending_dmem)
            cpu_rdata = dmem_rdata;
        // CHANGE: Use immediate decode for peripherals, not pending
        else if (is_uart)
            cpu_rdata = uart_rdata;
        else if (is_timer)
            cpu_rdata = timer_rdata;
    end

    // ------------------------------------------------------------
    // READY logic (asserted only when data is valid)
    // ------------------------------------------------------------
    always @(*) begin
        cpu_ready = 1'b0;

        if (pending_imem || pending_dmem)
            cpu_ready = 1'b1;          // synchronous memory response
        else if (cpu_valid && is_uart) // Peripheral is ready IMMEDIATELY
            cpu_ready = 1'b1;
        else if (cpu_valid && is_timer)
            cpu_ready = 1'b1;
    end

`ifndef SYNTHESIS
    always @(posedge clk) begin
        if (cpu_valid && cpu_ready) begin
            $display("TIME: %t | ADDR: %h | DATA: %h", $time, cpu_addr, cpu_rdata);
            if (cpu_valid && is_uart)
            $display("BUS_LOG: CPU Accessing UART at ADDR %h (Ready: %b)", cpu_addr, cpu_ready);
            if (cpu_valid && is_timer)
            $display("BUS_LOG: CPU Accessing TIMER at ADDR %h (Ready: %b)", cpu_addr, cpu_ready);
        end
    end
`endif 

endmodule
