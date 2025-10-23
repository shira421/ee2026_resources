module freq_divider #(
    parameter TARGET_FREQ = 1,      // Target frequency in Hz (default 1 Hz)
    parameter COUNTER_WIDTH = 26    // Counter width in bits (default supports down to 1.49 Hz)
)(
    input clk,                      // 100 MHz input clock
    output reg slow_clk             // Divided clock output
);

    // Calculate the counter limit
    // For 100 MHz input and target frequency F:
    // Counter limit = (100,000,000 / (2 * F)) - 1
    localparam INPUT_FREQ = 100_000_000;
    localparam COUNTER_LIMIT = (INPUT_FREQ / (2 * TARGET_FREQ)) - 1;
    
    // Counter register
    reg [COUNTER_WIDTH-1:0] ctr;
    
    // Initialize registers
    initial begin
        slow_clk = 0;
        ctr = 0;
    end
    
    // Clock divider logic
    always @(posedge clk) begin
        if (ctr == COUNTER_LIMIT) begin
            slow_clk <= ~slow_clk;
            ctr <= 0;
        end else begin
            ctr <= ctr + 1;
        end
    end

endmodule

// Quick reference for counter widths:
// 1 Hz: 26 bits (count to 49,999,999)
// 5 Hz: 24 bits (count to 9,999,999)
// 10 Hz: 23 bits (count to 4,999,999)
// 20 Hz: 22 bits (count to 2,499,999)
// 100 Hz: 20 bits (count to 499,999)
// 1 kHz: 17 bits (count to 49,999)
// 10 kHz: 13 bits (count to 4,999)
// 100 kHz: 10 bits (count to 499)
// 1 MHz: 7 bits (count to 49)
// 10 MHz: 3 bits (count to 4)
// 25 MHz: 2 bits (count to 1)
// 50 MHz: 1 bit (count to 0)
/* 
freq_divider #(.TARGET_FREQ(5), .COUNTER_WIDTH(24)) div_5hz (
        .clk(clk),
        .slow_clk(clk_5hz)
    );
*/
