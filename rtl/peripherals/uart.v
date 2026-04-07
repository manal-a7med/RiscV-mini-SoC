module uart_periph (
    input wire clk,
    input wire reset_n,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire        we,
    output reg  [31:0] rdata,
    output wire        ready,
    output reg         tx,
    input  wire        rx
);

    parameter CLK_FREQ = 50000000;
    parameter BAUD     = 115200;
    localparam DIVIDER = CLK_FREQ / BAUD;
    reg baud_restart;
    reg [15:0] baud_counter;
    // Tick should trigger at DIVIDER-1 to maintain correct period
    wire baud_tick = (baud_counter == DIVIDER - 1);

    always @(posedge clk) begin
        if (!reset_n || baud_tick || baud_restart) baud_counter <= 0;
        else                       baud_counter <= baud_counter + 1'b1;
    end

    reg [3:0] tx_state;
    reg [7:0] tx_data;
    reg [3:0] bit_idx;
    wire tx_busy = (tx_state != 0);

    assign ready = !tx_busy; // Ready when not busy
    
    always @(posedge clk) begin
        baud_restart <= 1'b0; // Default to no restart, set to 1 when we start a new transmission
        if (!reset_n) begin
            tx <= 1'b1;
            tx_state <= 0;
            bit_idx <= 0;
            tx_data <= 8'h0;
        end else begin
            // Start sending ONLY on a baud_tick or use a divider for the start bit too
            if (we && !tx_busy) begin
                tx_data  <= wdata[7:0];
                tx_state <= 1; 
                tx <= 0;       // Start bit
                bit_idx <= 0;
                baud_restart <= 1'b1; // Signal restart to reset the counter
            end else if (tx_busy && baud_tick) begin
                case (tx_state)
                    1: begin 
                        tx <= tx_data[bit_idx];
                        if (bit_idx == 7) begin
                            tx_state <= 2;
                        end else begin
                            bit_idx  <= bit_idx + 1'b1;
                        end
                    end
                    2: begin 
                        tx <= 1'b1; // Stop bit
                        tx_state <= 0;
                    end
                    default: tx_state <= 0;
                endcase
            end
        end
    end

    // --- 3. Bus Read Logic (Safety Update) ---
    // Use the top bits to ensure we only drive rdata if we are being addressed
    // This removes "No Driver" or "Multiple Driver" warnings in the top module
    wire uart_sel = (addr[31:12] == 20'h10000); 
    //wire uart_sel = (addr >= UART_BASE) && (addr <= UART_BASE + 32'hF);

    // ... inside always @(*) ...
    always @(*) begin
        rdata = 32'h0; 
        if (uart_sel) begin
            case (addr[3:0])
                4'h0: rdata = {24'b0, tx_data}; 
                // bit 0 is 1 when BUSY is 0 (Ready)
                4'h4: rdata = {31'b0, (tx_state == 0)}; 
                default: rdata = 32'h0;
            endcase
        end
    end

endmodule