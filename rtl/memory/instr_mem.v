module instr_mem (
    input  wire        clk,
    input  wire [31:0] addr,
    input  wire        cs,     // From interconnect (Active High)
    output wire [31:0] rdata
);

    // 1KB SRAM uses 8-bit word address (addr[9:2])
    wire [7:0] word_addr = addr[9:2];

    // Instantiate the Sky130 SRAM Macro
    sky130_sram_1kbyte_1rw1r_32x256_8 sram_macro(
        .clk0   (clk),
        .csb0   (!cs),         // Invert Active-High 'cs' to Active-Low 'csb'
        .web0   (1'b1),        // Always 1 (Read Only for IMEM)
        .wmask0 (4'b0000),     // No masking needed for read
        .addr0  (word_addr),
        .din0   (32'h0),       // No data input
        .dout0  (rdata),
        // Port 1 unused
        .clk1   (1'b0), .csb1(1'b1), .addr1(8'h0), .dout1() 
    );

    // --- Simulation Hook ---
    `ifdef SIM
    initial begin
        // We reference 'mem' inside the 'sram_macro' instance
        $readmemh("sw/build/program.hex", sram_macro.mem);
        $display("SIM: Instruction SRAM loaded with program.hex");
        // Debug: Print the first two instructions actually inside the RAM
        $display("DEBUG: RAM[0] = %h", sram_macro.mem[0]);
        $display("DEBUG: RAM[1] = %h", sram_macro.mem[1]);
    end
    `endif
endmodule