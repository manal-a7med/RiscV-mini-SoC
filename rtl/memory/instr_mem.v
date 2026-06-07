module instr_mem (
    input  wire        clk,
    input  wire [31:0] addr,
    input  wire        cs,     // From interconnect (Active High)
    output wire [31:0] rdata
);

    // 1KB SRAM macro: 256 entries x 32-bit words.
    // Word address = byte address >> 2  (bits [9:2])
    wire [7:0] word_addr = addr[9:2];

    // Instantiate the Sky130 SRAM Macro
    sky130_sram_1kbyte_1rw1r_32x256_8 sram_macro (
        .clk0   (clk),
        .csb0   (!cs),        // Active-Low chip select
        .web0   (1'b1),       // Always 1 = read-only port
        .wmask0 (4'b0000),
        .addr0  (word_addr),
        .din0   (32'h0),
        .dout0  (rdata),
        // Port 1 unused — tie off
        .clk1   (1'b0), .csb1(1'b1), .addr1(8'h0), .dout1()
    );

    // ----------------------------------------------------------------
    // Simulation initialisation
    //
    // program.hex is produced by:
    //   riscv64-unknown-elf-objcopy -O verilog --verilog-data-width 4 \
    //       program.elf program.hex
    //   sed -i '/@/d' program.hex          ← strips @address markers
    //
    // Result: one 32-bit hex word per line, no address markers.
    // $readmemh fills sram_macro.mem[0], mem[1], ... in order,
    // which matches word_addr = byte_addr >> 2 used above.
    // ----------------------------------------------------------------
    `ifdef SIM
    initial begin
        $readmemh("sw/build/program.hex", sram_macro.mem);
        $display("SIM: IMEM loaded from sw/build/program.hex");
        $display("SIM: IMEM[0] = %h  (expect first instruction)", sram_macro.mem[0]);
        $display("SIM: IMEM[1] = %h", sram_macro.mem[1]);
    end
    `endif

endmodule