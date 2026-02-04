module data_mem (
    input  wire        clk,
    input  wire        we,     // Write Enable
    input  wire [3:0]  wstrb,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire        cs,     // From interconnect
    output wire [31:0] rdata
);

    wire [7:0] index = addr[9:2];

    sky130_sram_1kbyte_1rw1r_32x256_8 sram_macro(
        .clk0   (clk),
        .csb0   (!cs),
        .web0   (!we),         // Invert 'we' to Active-Low 'web'
        .wmask0 (wstrb),       // Connect byte strobes directly
        .addr0  (index),
        .din0   (wdata),
        .dout0  (rdata),
        // Port 1 unused
        .clk1   (1'b0), .csb1(1'b1), .addr1(8'h0), .dout1()
    );

endmodule