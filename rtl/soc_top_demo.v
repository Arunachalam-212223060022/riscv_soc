// ============================================================
//  soc_top_demo.v  —  Boolean Board Hardware Demo
//  Pure hardware — no CPU/program.mem needed
//  Features:
//    LED[0]      — blinks on every UART TX byte
//    LED[7:1]    — mirror sw[7:1]
//    LED[15:8]   — knight-rider at 4 Hz (pauses on btn[1])
//    D1 (left)   — 32-bit counter upper 16 bits in hex
//    D0 (right)  — live sw[15:0] value in hex
//    RGB0        — auto colour wheel (PWM rainbow)
//    RGB1        — sw[10]=R, sw[9]=G, sw[8]=B manual mix
//    UART        — sends "C:XXXXXXXX\r\n" every 1 second
//    btn[0]      — reset counter
//    btn[1]      — pause/resume
// ============================================================
module soc_top_demo (
    input  wire        clk,        // 100 MHz
    input  wire        rst_n,      // BTN0 active-low reset

    // UART
    output wire        uart_tx,
    input  wire        uart_rx,

    // LEDs [15:0]
    output wire [15:0] led,

    // Switches [15:0]
    input  wire [15:0] sw,

    // Buttons (btn[0]=reset, btn[1]=pause)
    input  wire [3:0]  btn,

    // RGB LEDs
    output wire        RGB0_R, RGB0_G, RGB0_B,
    output wire        RGB1_R, RGB1_G, RGB1_B,

    // 7-Segment
    output wire [3:0]  D0_AN,
    output wire [7:0]  D0_SEG,
    output wire [3:0]  D1_AN,
    output wire [7:0]  D1_SEG
);

// ── Power-on reset (256 cycles) ─────────────────────────────
reg [7:0] por = 0;
wire rst = por[7] & rst_n & ~btn[0];
always @(posedge clk) if (!por[7]) por <= por + 1;

// ── 32-bit free counter ──────────────────────────────────────
reg [31:0] counter;
wire pause = btn[1];
always @(posedge clk or negedge rst)
    if (!rst) counter <= 0;
    else if (!pause) counter <= counter + 1;

// ── 1 Hz tick (100 MHz / 100_000_000) ───────────────────────
reg [26:0] sec_cnt;
reg        sec_tick;
always @(posedge clk or negedge rst) begin
    if (!rst) begin sec_cnt <= 0; sec_tick <= 0; end
    else if (sec_cnt == 27'd99_999_999) begin sec_cnt <= 0; sec_tick <= 1; end
    else begin sec_cnt <= sec_cnt + 1; sec_tick <= 0; end
end

// ── 4 Hz tick for knight-rider ───────────────────────────────
reg [24:0] kr_cnt;
reg        kr_tick;
always @(posedge clk or negedge rst) begin
    if (!rst) begin kr_cnt <= 0; kr_tick <= 0; end
    else if (kr_cnt == 25'd24_999_999) begin kr_cnt <= 0; kr_tick <= 1; end
    else begin kr_cnt <= kr_cnt + 1; kr_tick <= 0; end
end

// ── Knight-rider on LED[15:8] ────────────────────────────────
reg [7:0]  kr;
reg        kr_dir;
always @(posedge clk or negedge rst) begin
    if (!rst) begin kr <= 8'b00000001; kr_dir <= 1; end
    else if (pause) begin end  // freeze
    else if (kr_tick) begin
        if (kr_dir) begin
            kr <= kr << 1;
            if (kr == 8'b01000000) kr_dir <= 0;
        end else begin
            kr <= kr >> 1;
            if (kr == 8'b00000010) kr_dir <= 1;
        end
    end
end

// ── UART TX — sends "C:XXXXXXXX\r\n" every second ────────────
// Baud = 115200 → divisor = 100MHz/115200 = 868
localparam BAUD_DIV = 868;
localparam MSG_LEN  = 12; // "C:XXXXXXXX\r\n"

reg [7:0]  tx_msg [0:11];
reg [3:0]  tx_idx;
reg        tx_busy_byte;
reg [9:0]  tx_shift;
reg [31:0] tx_baud_cnt;
reg [3:0]  tx_bit_cnt;
reg        tx_sending;
reg        uart_blink;

// build message from counter
function [7:0] hex_digit;
    input [3:0] n;
    hex_digit = (n < 10) ? (8'h30 + n) : (8'h41 + n - 10);
endfunction

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        tx_idx <= 0; tx_busy_byte <= 0; tx_sending <= 0;
        tx_shift <= 10'h3FF; tx_baud_cnt <= 0; tx_bit_cnt <= 0;
        uart_blink <= 0;
    end else begin
        // load message on sec_tick
        if (sec_tick && !tx_sending) begin
            tx_msg[0]  <= 8'h43; // 'C'
            tx_msg[1]  <= 8'h3A; // ':'
            tx_msg[2]  <= hex_digit(counter[31:28]);
            tx_msg[3]  <= hex_digit(counter[27:24]);
            tx_msg[4]  <= hex_digit(counter[23:20]);
            tx_msg[5]  <= hex_digit(counter[19:16]);
            tx_msg[6]  <= hex_digit(counter[15:12]);
            tx_msg[7]  <= hex_digit(counter[11:8]);
            tx_msg[8]  <= hex_digit(counter[7:4]);
            tx_msg[9]  <= hex_digit(counter[3:0]);
            tx_msg[10] <= 8'h0D; // \r
            tx_msg[11] <= 8'h0A; // \n
            tx_sending <= 1;
            tx_idx     <= 0;
        end

        if (tx_sending && !tx_busy_byte) begin
            if (tx_idx < MSG_LEN) begin
                tx_shift    <= {1'b1, tx_msg[tx_idx], 1'b0};
                tx_baud_cnt <= 0;
                tx_bit_cnt  <= 0;
                tx_busy_byte<= 1;
                uart_blink  <= 1;
                tx_idx      <= tx_idx + 1;
            end else begin
                tx_sending <= 0;
                uart_blink <= 0;
            end
        end

        if (tx_busy_byte) begin
            uart_blink <= 1;
            if (tx_baud_cnt == BAUD_DIV) begin
                tx_baud_cnt <= 0;
                tx_shift    <= {1'b1, tx_shift[9:1]};
                tx_bit_cnt  <= tx_bit_cnt + 1;
                if (tx_bit_cnt == 9) begin
                    tx_busy_byte <= 0;
                    uart_blink   <= 0;
                end
            end else tx_baud_cnt <= tx_baud_cnt + 1;
        end
    end
end

assign uart_tx = tx_busy_byte ? tx_shift[0] : 1'b1;

// ── LEDs ─────────────────────────────────────────────────────
assign led[0]    = uart_blink;       // UART TX activity
assign led[7:1]  = sw[7:1];          // switch mirror
assign led[15:8] = pause ? 8'hFF : kr; // knight-rider or solid on pause

// ── RGB0 — colour wheel via PWM ──────────────────────────────
reg [7:0] hue;
reg [5:0] pwm_cnt;
always @(posedge clk or negedge rst)
    if (!rst) begin hue <= 0; pwm_cnt <= 0; end
    else begin
        pwm_cnt <= pwm_cnt + 1;
        if (sec_tick) hue <= hue + 8;  // advance hue every second
    end

// simple 3-phase hue → R,G,B
wire [7:0] r0 = (hue < 85)  ? (hue * 3)         :
                (hue < 170) ? ((170 - hue) * 3)  : 0;
wire [7:0] g0 = (hue < 85)  ? (85 - hue) * 3    :
                (hue < 170) ? 0                   : (hue - 170) * 3;
wire [7:0] b0 = (hue < 85)  ? 0                  :
                (hue < 170) ? (hue - 85) * 3      : (255 - hue) * 3;

assign RGB0_R = (pwm_cnt < r0[7:2]);  // PWM
assign RGB0_G = (pwm_cnt < g0[7:2]);
assign RGB0_B = (pwm_cnt < b0[7:2]);

// ── RGB1 — manual sw[10:8] ───────────────────────────────────
assign RGB1_R = sw[10];
assign RGB1_G = sw[9];
assign RGB1_B = sw[8];

// ── 7-Segment display ────────────────────────────────────────
// D1 left  = counter[31:16]
// D0 right = sw[15:0]
wire [31:0] seg_val = {counter[31:16], sw[15:0]};

seg7_ctrl u_seg7 (
    .clk        (clk),
    .rst_n      (rst),
    .display_val(seg_val),
    .D0_AN      (D0_AN), .D0_SEG(D0_SEG),
    .D1_AN      (D1_AN), .D1_SEG(D1_SEG)
);

endmodule
