`timescale 1ns / 1ps

module tb_mini_soc();

    // 1. Signals
    reg clk;
    reg reset_n;
    wire uart_tx;
    wire uart_rx = 1'b1; // Keep RX idle high
    wire trap;

    // 2. Instantiate SoC
    mini_soc_top uut (
        .clk(clk),
        .reset_n(reset_n),
        .uart_tx(uart_tx),
        .uart_rx(uart_rx),
        .trap(trap)
    );

    // 3. Clock Generation (50MHz = 20ns period)
    always #10 clk = ~clk;

    // 4. Test Sequence
    initial begin
        // Initialize
        clk = 0;
        reset_n = 0;
        
        $display("Starting SoC Simulation...");
        $dumpfile("sim_out.vcd");
        $dumpvars(0, tb_mini_soc);

        // Hold reset for 100ns
        #100;
        reset_n = 1;
        $display("Reset released. CPU should be booting...");

        // Monitor for 'Trap' or Timeout
        // If the CPU hits an illegal instruction, trap goes high.
        fork
            begin
                wait(trap);
                $display("ERROR: CPU TRAPPED at time %t", $time);
                $finish;
            end
            begin
                // Run for 1ms simulated time (adjust as needed)
                #1000000; 
                $display("Simulation Timeout reached.");
                $finish;
            end
        join_any
    end

    // 5. UART Monitor (Helpful for terminal debugging)
    // This looks for the start bit and displays the byte
    // Note: This is a simplified monitor for visual check
    always @(negedge uart_tx) begin
        if (reset_n) begin
            // Wait for half-bit to middle of start bit, then sample bits
            // This is just a 'placeholder' - for true terminal output,
            // we usually rely on the waveform or a dedicated UART-to-Console BFMs.
        end
    end
    // Simplified UART Monitor to print to Linux console
    // Based on 115200 baud @ 50MHz (approx 434 cycles per bit)
    // --- UART Monitor to Print to Terminal ---
    parameter CLK_FREQ = 50000000;
    parameter BAUD_RATE = 115200;
    localparam BIT_PERIOD = 1000000000 / BAUD_RATE; // Bit period in nanoseconds

    reg[7:0] char;
    integer i;

    initial begin
        forever begin
            @(negedge uart_tx); // Wait for Start Bit
            #(BIT_PERIOD / 2);  // Move to middle of start bit
        
            if (uart_tx == 0) begin
                char = 0;
                // Sample 8 data bits
                for (i = 0; i < 8; i = i + 1) begin
                    #(BIT_PERIOD);
                    char[i] = uart_tx;
                end
                // Print the character to console
                $write("%c", char);
                $fflush(); // Force update to terminal
        end
    end
end

// Simple UART logger: Captures writes to the UART_DATA register
    always @(posedge clk) begin
        if (uut.bus_inst.is_uart && uut.bus_inst.cpu_ready && (|uut.bus_inst.cpu_wstrb)) begin
            if (uut.bus_inst.cpu_addr == 32'h1000_0000) begin
                $write("%c", uut.bus_inst.cpu_wdata[7:0]);
                $fflush();
            end
        end
    end
    
endmodule