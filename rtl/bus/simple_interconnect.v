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
    output reg         imem_cs,
    input  wire [31:0] imem_rdata,

    // Data memory
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    output reg  [3:0]  dmem_wstrb,
    output reg         dmem_cs,
    input  wire [31:0] dmem_rdata,

    // UART
    output wire [31:0] uart_addr,
    output wire [31:0] uart_wdata,
    output reg         uart_we,
    input  wire [31:0] uart_rdata,
    input  wire        uart_ready,

    // Timer
    output wire [31:0] timer_addr,
    output wire [31:0] timer_wdata,
    output reg         timer_we,
    input  wire [31:0] timer_rdata,
    input  wire        timer_ready
);

    // ------------------------------------------------------------
    // Address decode (param-driven, single source of truth)
    // ------------------------------------------------------------
    wire is_imem  = (cpu_addr >= `MEM_INST_BASE) &&
                    (cpu_addr <  `MEM_INST_BASE + 32'h400);

    wire is_dmem  = (cpu_addr >= `MEM_DATA_BASE) &&
                    (cpu_addr <  `MEM_DATA_BASE + 32'h400);

    wire is_uart  = (cpu_addr >= `UART_BASE) &&
                    (cpu_addr <  `UART_BASE  + 32'h10);

    wire is_timer = (cpu_addr >= `TIMER_BASE) &&
                    (cpu_addr <  `TIMER_BASE + 32'h10);

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

    // ------------------------------------------------------------
    // Combinational chip-selects and write-enables
    // (synthesis-safe: defaults set before any conditional)
    // ------------------------------------------------------------
    always @(*) begin
        imem_cs    = 1'b0;
        dmem_cs    = 1'b0;
        dmem_wstrb = 4'b0000;
        uart_we    = 1'b0;
        timer_we   = 1'b0;

        imem_cs = cpu_valid && is_imem;
        dmem_cs = cpu_valid && is_dmem;

        if (cpu_valid && is_dmem)  dmem_wstrb = cpu_wstrb;
        if (cpu_valid && is_uart)  uart_we    = (|cpu_wstrb);
        if (cpu_valid && is_timer) timer_we   = (|cpu_wstrb);
    end

    // ------------------------------------------------------------
    // Registered pending signals — ALL four targets use the same
    // 1-cycle pipeline.  Eliminates the combinational ready glitch
    // that could cause PicoRV32 to double-advance the PC.
    // ------------------------------------------------------------
    reg pending_imem;
    reg pending_dmem;
    reg pending_uart;
    reg pending_timer;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            pending_imem  <= 1'b0;
            pending_dmem  <= 1'b0;
            pending_uart  <= 1'b0;
            pending_timer <= 1'b0;
        end else begin
            // Gate on cpu_valid so pending clears as soon as the CPU
            // deasserts valid (i.e. after ready was seen for one cycle).
            pending_imem  <= cpu_valid && is_imem;
            pending_dmem  <= cpu_valid && is_dmem;
            pending_uart  <= cpu_valid && is_uart;
            pending_timer <= cpu_valid && is_timer;
        end
    end

    // ------------------------------------------------------------
    // READ DATA MUX — entirely off registered pending signals.
    // Peripheral rdata is now stable one cycle after the request,
    // matching the memory pipeline.  uart_rdata / timer_rdata are
    // combinational in the peripheral itself (zero latency registers)
    // so they are valid on the cycle following the write-enable.
    // ------------------------------------------------------------
    always @(*) begin
        cpu_rdata = 32'h0;
        if      (pending_imem)  cpu_rdata = imem_rdata;
        else if (pending_dmem)  cpu_rdata = dmem_rdata;
        else if (pending_uart)  cpu_rdata = uart_rdata;
        else if (pending_timer) cpu_rdata = timer_rdata;
    end

    // ------------------------------------------------------------
    // READY — asserted exactly one cycle after a valid request,
    // for every target uniformly.  No combinational path back to
    // cpu_valid.
    // ------------------------------------------------------------
    always @(*) begin
        cpu_ready = pending_imem  ||
                    pending_dmem  ||
                    pending_uart  ||
                    pending_timer;
    end

`ifndef SYNTHESIS
    always @(posedge clk) begin
        if (cpu_valid && cpu_ready) begin
            $display("TIME: %0t | ADDR: %h | RDATA: %h", $time, cpu_addr, cpu_rdata);
            if (pending_uart)
                $display("BUS_LOG: UART  response  ADDR=%h DATA=%h", cpu_addr, cpu_rdata);
            if (pending_timer)
                $display("BUS_LOG: TIMER response  ADDR=%h DATA=%h", cpu_addr, cpu_rdata);
        end
    end
`endif

endmodule