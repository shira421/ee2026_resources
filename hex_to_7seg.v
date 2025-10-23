`timescale 1ns / 1ps

//=============================================================================
// HEX TO 7-SEGMENT DECODER
// Converts 4-bit hex value to 7-segment display pattern
// Note: Basys3 uses COMMON ANODE (active-low segments)
//=============================================================================

module hex_to_7seg(
    input [3:0] hex,                // 4-bit hex input (0-F)
    output reg [6:0] seg            // 7-segment output (active-low)
);

    // Segment mapping:
    //      a
    //     ---
    //  f |   | b
    //     -g-
    //  e |   | c
    //     ---
    //      d
    //
    // seg = {g, f, e, d, c, b, a}
    // Active-LOW: 0 = segment ON, 1 = segment OFF
    
    always @(*) begin
        case (hex)
            4'h0: seg = 7'b1000000;  // Display "0"
            4'h1: seg = 7'b1111001;  // Display "1"
            4'h2: seg = 7'b0100100;  // Display "2"
            4'h3: seg = 7'b0110000;  // Display "3"
            4'h4: seg = 7'b0011001;  // Display "4"
            4'h5: seg = 7'b0010010;  // Display "5"
            4'h6: seg = 7'b0000010;  // Display "6"
            4'h7: seg = 7'b1111000;  // Display "7"
            4'h8: seg = 7'b0000000;  // Display "8"
            4'h9: seg = 7'b0010000;  // Display "9"
            4'hA: seg = 7'b0001000;  // Display "A"
            4'hB: seg = 7'b0000011;  // Display "b"
            4'hC: seg = 7'b0100111;  // Display "c"
            4'hD: seg = 7'b0100001;  // Display "d"
            4'hE: seg = 7'b0000110;  // Display "E"
            4'hF: seg = 7'b0001110;  // Blank (all segments OFF)
            default: seg = 7'b1111111;
        endcase
    end

endmodule
