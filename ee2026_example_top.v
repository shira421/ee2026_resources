`timescale 1ns / 1ps

//=============================================================================
// EE2026 PRACTICAL EVALUATION - TOP MODULE
// Student ID: A0308961X
// Parameters: LB=10, RB=2, EX=7 (SW7 controls display)
//=============================================================================

module ee2026_top(
    input clk,                      // 100MHz system clock
    input [15:0] sw,                // 16 switches
    input btnC,                     // Center button
    input btnU,                     // Up button
    input btnL,                     // Left button
    input btnR,                     // Right button
    input btnD,                     // Down button
    output reg [15:0] led,          // 16 LEDs
    output reg [6:0] seg,           // 7-segment segments
    output reg [3:0] an             // 7-segment anodes (active-low)
);

    //=========================================================================
    // PARAMETERS - Based on Student ID A0308961X
    //=========================================================================
    localparam DIGIT_1ST = 4'd1;    // 1st rightmost digit
    localparam DIGIT_2ND = 4'd6;    // 2nd rightmost digit  
    localparam DIGIT_3RD = 4'd9;    // 3rd rightmost digit
    localparam DIGIT_4TH = 4'd8;    // 4th rightmost digit
    
    // Derived parameters
    localparam LB = 10;             // Left boundary (from Table 1)
    localparam RB = 2;              // Right boundary (from Table 1)
    localparam EX = 7;              // EX position - SW7 controls it (from Table 2)
    
    // Timing parameters (in 10ms units)
    localparam T_HIGHER = 160;      // 1.60s when moving to higher LED (from Table 6)
    localparam T_LOWER = 50;        // 0.50s when moving to lower LED (from Table 6)
    
    // Blinking frequencies (from Table 7)
    localparam LEFT_BLINK_FREQ = 5;     // 5 Hz for left region
    localparam RIGHT_BLINK_FREQ = 15;   // 15 Hz for right region
    
    // Direction and button (from Tables 4 & 5)
    localparam DIR_INITIAL = 1'b0;  // 0 = moves to lower LED initially
    // PB_INITIAL = btnU (Up button)
    
    // Anodes for SUBTASK A (from Table 3)
    // AN3, AN2, AN0 are ON (active-low: 0=ON, 1=OFF)
    localparam [3:0] ANODE_TASK_A = 4'b0010;  // AN[3]=0, AN[2]=0, AN[1]=1, AN[0]=0
    
    //=========================================================================
    // INTERNAL SIGNALS
    //=========================================================================
    
    // Frequency dividers
    wire clk_10ms;          // 100 Hz for movement timing
    wire clk_5hz;           // 5 Hz for left region blinking
    wire clk_15hz;          // 15 Hz for right region blinking
    wire clk_refresh;       // 1 kHz for 7-segment refresh
    
    // Instantiate frequency dividers
    freq_divider #(.TARGET_FREQ(100), .COUNTER_WIDTH(20)) div_10ms (
        .clk(clk),
        .slow_clk(clk_10ms)
    );
    
    freq_divider #(.TARGET_FREQ(5), .COUNTER_WIDTH(24)) div_5hz (
        .clk(clk),
        .slow_clk(clk_5hz)
    );
    
    freq_divider #(.TARGET_FREQ(15), .COUNTER_WIDTH(23)) div_15hz (
        .clk(clk),
        .slow_clk(clk_15hz)
    );
    
    freq_divider #(.TARGET_FREQ(1000), .COUNTER_WIDTH(17)) div_refresh (
        .clk(clk),
        .slow_clk(clk_refresh)
    );
    
    //=========================================================================
    // STATE MACHINE
    //=========================================================================
    reg [1:0] state;
    localparam ST_TASK_A = 2'd0;
    localparam ST_TASK_B = 2'd1;
    localparam ST_TASK_C = 2'd2;
    
    // Initialize state
    initial begin
        state = ST_TASK_A;
    end
    
    //=========================================================================
    // BUTTON DEBOUNCING
    //=========================================================================
    reg btnU_prev, btnC_prev;
    reg btnU_sync, btnC_sync;
    wire btnU_pressed, btnC_pressed;
    
    // Simple synchronization
    always @(posedge clk) begin
        btnU_sync <= btnU;
        btnC_sync <= btnC;
        btnU_prev <= btnU_sync;
        btnC_prev <= btnC_sync;
    end
    
    // Edge detection
    assign btnU_pressed = btnU_sync && !btnU_prev;
    assign btnC_pressed = btnC_sync && !btnC_prev;
    
    //=========================================================================
    // EX POSITION AND MOVEMENT CONTROL
    //=========================================================================
    reg [3:0] ex_position;          // Current position of EX (0-15)
    reg ex_direction;               // 0=moving down, 1=moving up
    reg [7:0] move_counter;         // Counter for movement timing
    reg [7:0] move_target;          // Target count before next move
    
    initial begin
        ex_position = 0;
        ex_direction = 0;
        move_counter = 0;
    end
    
    // State machine transitions
    always @(posedge clk) begin
        case (state)
            ST_TASK_A: begin
                if (btnU_pressed && !btnC_sync) begin
                    // Only btnU pressed - start TASK B
                    state <= ST_TASK_B;
                    ex_position <= EX;              // Start at EX position
                    ex_direction <= DIR_INITIAL;    // Start moving down
                    move_counter <= 0;
                end
            end
            
            ST_TASK_B: begin
                if (btnU_pressed && btnC_sync) begin
                    // Both buttons pressed - enter TASK C
                    state <= ST_TASK_C;
                end
            end
            
            ST_TASK_C: begin
                // Stay in TASK C - ending state
            end
            
            default: state <= ST_TASK_A;
        endcase
    end
    
    // Movement timing target based on direction
    always @(*) begin
        if (ex_direction == 1'b1) begin
            move_target = T_HIGHER;     // Moving up: 1.6s
        end else begin
            move_target = T_LOWER;      // Moving down: 0.5s
        end
    end
    
    // EX movement logic (10ms tick)
    always @(posedge clk_10ms) begin
        if (state == ST_TASK_B || state == ST_TASK_C) begin
            if (move_counter >= move_target - 1) begin
                // Time to move
                move_counter <= 0;
                
                if (ex_direction == 1'b1) begin
                    // Moving UP (towards LED15)
                    if (ex_position >= 15) begin
                        // Reached top, reverse direction
                        ex_direction <= 1'b0;
                        ex_position <= 14;
                    end else begin
                        ex_position <= ex_position + 1;
                    end
                end else begin
                    // Moving DOWN (towards LED0)
                    if (ex_position == 0) begin
                        // Reached bottom, reverse direction
                        ex_direction <= 1'b1;
                        ex_position <= 1;
                    end else begin
                        ex_position <= ex_position - 1;
                    end
                end
            end else begin
                move_counter <= move_counter + 1;
            end
        end
    end
    
    //=========================================================================
    // LED CONTROL
    //=========================================================================
    always @(*) begin
        led = 16'h0000;  // Default all OFF
        
        case (state)
            ST_TASK_A: begin
                // Show LEDs from LD(8) to LD(RB)=LD(2)
                // LD(EX)=LD(7) only ON when SW7 is ON
                led[8] = 1'b1;
                led[7] = sw[7];     // LED7 controlled by SW7
                led[6] = 1'b1;
                led[5] = 1'b1;
                led[4] = 1'b1;
                led[3] = 1'b1;
                led[2] = 1'b1;
            end
            
            ST_TASK_B, ST_TASK_C: begin
                // Show moving EX with blinking in edge regions
                if (ex_position >= (LB + 1)) begin
                    // Left region: LD15 to LD11 - blink at 5Hz
                    led[ex_position] = clk_5hz;
                end 
                else if (ex_position <= (RB - 1)) begin
                    // Right region: LD1 to LD0 - blink at 15Hz
                    led[ex_position] = clk_15hz;
                end 
                else begin
                    // Middle region: LD10 to LD2 - solid ON
                    led[ex_position] = 1'b1;
                end
            end
            
            default: led = 16'h0000;
        endcase
    end
    
    //=========================================================================
    // 7-SEGMENT DISPLAY CONTROL
    //=========================================================================
    reg [3:0] digit_to_display;
    wire [6:0] seg_pattern;
    
    // Instantiate 7-segment decoder
    hex_to_7seg decoder (
        .hex(digit_to_display),
        .seg(seg_pattern)
    );
    
    // Anode counter for multiplexing
    reg [1:0] anode_counter;
    
    initial begin
        anode_counter = 0;
    end
    
    always @(posedge clk_refresh) begin
        anode_counter <= anode_counter + 1;
    end
    
    // Display logic based on state
    always @(*) begin
        case (state)
            ST_TASK_A: begin
                // SUBTASK A: Display EX value when SW7 is ON
                if (sw[7]) begin
                    digit_to_display = EX;              // Show "7"
                    an = ANODE_TASK_A;                  // AN0, AN2, AN3 active
                end else begin
                    digit_to_display = 4'hF;            // Blank
                    an = 4'b1111;                       // All OFF
                end
                seg = seg_pattern;
            end
            
            ST_TASK_B: begin
                // SUBTASK B: Display OFF
                digit_to_display = 4'hF;
                an = 4'b1111;
                seg = 7'b1111111;
            end
            
            ST_TASK_C: begin
                // SUBTASK C: Alternating display patterns
                if (ex_position >= (LB + 1) || ex_position <= (RB - 1)) begin
                    // Edge regions (LD15-LD11 or LD1-LD0): Show "E." alternating
                    digit_to_display = 4'hE;  // Show "E"
                    
                    if (anode_counter[1] == 0) begin
                        an = 4'b1110;  // AN0 active (right side)
                    end else begin
                        an = 4'b0111;  // AN3 active (left side)
                    end
                    
                    seg = seg_pattern;
                end else begin
                    // Middle region (LD10-LD2): Show "- -" alternating
                    digit_to_display = 4'hA;  // Dash
                    
                    if (anode_counter[1] == 0) begin
                        an = 4'b1100;  // AN0, AN1 active (right side)
                    end else begin
                        an = 4'b0011;  // AN2, AN3 active (left side)
                    end
                    
                    seg = seg_pattern;
                end
            end
            
            default: begin
                digit_to_display = 4'hF;
                an = 4'b1111;
                seg = 7'b1111111;
            end
        endcase
    end

endmodule
