`include "soc_param.vh"

module timer_periph (
    input wire clk,
    input wire reset_n,
    
    // Bus Interface
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire        we,
    output reg  [31:0] rdata,
    output wire        ready,
    
    // Interrupt Output
    output reg         irq
);

    wire timer_sel = (addr[31:12] == 20'h10001); // TIMER_BASE = 0x10001000
    
    // Register offsets
    // 0x0: COUNT (Read only or Read/Write)
    // 0x4: COMPARE (Read/Write)
    // 0x8: CTRL (Write 1 to clear IRQ)

    reg [31:0] count_reg;
    reg [31:0] compare_reg;
    
    // Timer is always ready (zero wait states)
    assign ready = 1'b1;
    //assign rdata = count_reg;

    // --- 1. Counter Logic ---
    always @(posedge clk) begin
        if (!reset_n) begin
            count_reg <= 32'h0;
        end else begin
            count_reg <= count_reg + 1'b1;
        end
    end

 // --- 2. Register Write/IRQ Logic ---
    always @(posedge clk) begin
        if (!reset_n) begin
            compare_reg <= 32'hFFFF_FFFF;
            irq         <= 1'b0;
        end else begin
            // 1. Check for Register Writes
            if (we && timer_sel) begin
                if (addr[3:0] == 4'h4) compare_reg <= wdata;
                if (addr[3:0] == 4'h8) irq         <= 1'b0; // Software Clear
            end 
            // 2. Check for Match (Set IRQ) 
            // We use 'else if' or a specific priority to prevent logic loops
            else if (count_reg == compare_reg) begin
                irq <= 1'b1;
            end
        end
    end
    // --- 3. Register Read Logic ---
    always @(*) begin
        rdata = 32'h0; 
        if (timer_sel) begin
            case (addr[3:0])
                4'h0: rdata = count_reg;
                4'h4: rdata = compare_reg;
                4'h8: rdata = {30'b0, irq, 1'b0}; // Explicitly drive all 32 bits
                default: rdata = 32'h0;
            endcase
        end
    end
endmodule