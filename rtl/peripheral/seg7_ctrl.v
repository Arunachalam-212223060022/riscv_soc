// seg7_ctrl.v — 8-digit scanning 7-segment controller for Boolean board
// Boolean board: two independent 4-digit displays (D0=digits3..0, D1=digits7..4)
// All signals active LOW. SEG[7]=DP, SEG[6:0]=CG,CF,CE,CD,CC,CB,CA
// Memory-mapped at 0x20000100: write 32-bit value → displayed as 8 hex digits
// Scans at ~1kHz (100MHz / 100000 = 1000 Hz per full cycle, 125Hz per digit)

module seg7_ctrl (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] display_val,   // value from CPU memory-mapped register
    // Display 0 (right 4 digits: 3..0)
    output reg  [3:0]  D0_AN,
    output reg  [7:0]  D0_SEG,
    // Display 1 (left 4 digits: 7..4)
    output reg  [3:0]  D1_AN,
    output reg  [7:0]  D1_SEG
);

// Divide 100MHz down to ~1kHz scan tick (100000 cycles per digit)
reg [16:0] div_cnt;
reg        tick;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        div_cnt <= 0; tick <= 0;
    end else if (div_cnt == 17'd99999) begin
        div_cnt <= 0; tick <= 1;
    end else begin
        div_cnt <= div_cnt + 1; tick <= 0;
    end
end

// 3-bit digit counter (0..7)
reg [2:0] digit_sel;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) digit_sel <= 0;
    else if (tick) digit_sel <= digit_sel + 1;
end

// Select the nibble to display
reg [3:0] nibble;
always @(*) begin
    case (digit_sel)
        3'd0: nibble = display_val[3:0];
        3'd1: nibble = display_val[7:4];
        3'd2: nibble = display_val[11:8];
        3'd3: nibble = display_val[15:12];
        3'd4: nibble = display_val[19:16];
        3'd5: nibble = display_val[23:20];
        3'd6: nibble = display_val[27:24];
        3'd7: nibble = display_val[31:28];
        default: nibble = 4'hF;
    endcase
end

// Hex to 7-segment decoder (active LOW, SEG[6:0] = CG,CF,CE,CD,CC,CB,CA)
// SEG[7] = DP (decimal point) — always off
reg [6:0] seg_pattern;
always @(*) begin
    case (nibble)
        4'h0: seg_pattern = 7'b1000000; // 0
        4'h1: seg_pattern = 7'b1111001; // 1
        4'h2: seg_pattern = 7'b0100100; // 2
        4'h3: seg_pattern = 7'b0110000; // 3
        4'h4: seg_pattern = 7'b0011001; // 4
        4'h5: seg_pattern = 7'b0010010; // 5
        4'h6: seg_pattern = 7'b0000010; // 6
        4'h7: seg_pattern = 7'b1111000; // 7
        4'h8: seg_pattern = 7'b0000000; // 8
        4'h9: seg_pattern = 7'b0010000; // 9
        4'hA: seg_pattern = 7'b0001000; // A
        4'hB: seg_pattern = 7'b0000011; // b
        4'hC: seg_pattern = 7'b1000110; // C
        4'hD: seg_pattern = 7'b0100001; // d
        4'hE: seg_pattern = 7'b0000110; // E
        4'hF: seg_pattern = 7'b0001110; // F
        default: seg_pattern = 7'b1111111; // blank
    endcase
end

// Drive anode and cathode signals
// D0 = digits 0..3 (right side), D1 = digits 4..7 (left side)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        D0_AN  <= 4'b1111;
        D1_AN  <= 4'b1111;
        D0_SEG <= 8'hFF;
        D1_SEG <= 8'hFF;
    end else if (tick) begin
        // Default: all off
        D0_AN <= 4'b1111;
        D1_AN <= 4'b1111;
        case (digit_sel)
            3'd0: begin D0_AN <= 4'b1110; D0_SEG <= {1'b1, seg_pattern}; end
            3'd1: begin D0_AN <= 4'b1101; D0_SEG <= {1'b1, seg_pattern}; end
            3'd2: begin D0_AN <= 4'b1011; D0_SEG <= {1'b1, seg_pattern}; end
            3'd3: begin D0_AN <= 4'b0111; D0_SEG <= {1'b1, seg_pattern}; end
            3'd4: begin D1_AN <= 4'b1110; D1_SEG <= {1'b1, seg_pattern}; end
            3'd5: begin D1_AN <= 4'b1101; D1_SEG <= {1'b1, seg_pattern}; end
            3'd6: begin D1_AN <= 4'b1011; D1_SEG <= {1'b1, seg_pattern}; end
            3'd7: begin D1_AN <= 4'b0111; D1_SEG <= {1'b1, seg_pattern}; end
        endcase
    end
end

endmodule
