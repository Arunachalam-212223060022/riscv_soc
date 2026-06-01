module uart (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    input  wire        we,
    output wire        tx,
    input  wire        rx,
    output wire        irq
);
    // ── TX ────────────────────────────────────────────────
    reg [31:0] baud_div;
    reg [7:0]  tx_data_reg;
    reg        tx_busy;
    reg [31:0] baud_cnt;
    reg [3:0]  bit_cnt;
    reg [9:0]  shift_reg;

    // ── RX ────────────────────────────────────────────────
    reg [1:0]  rx_sync;
    wire       rx_clean = rx_sync[1];
    reg [31:0] rx_baud_cnt;
    reg [3:0]  rx_bit_cnt;
    reg [8:0]  rx_shift;
    reg [7:0]  rx_data_reg;
    reg        rx_ready;
    reg        rx_busy;

    // RX state machine
    localparam RX_IDLE  = 2'd0,
               RX_START = 2'd1,
               RX_DATA  = 2'd2,
               RX_STOP  = 2'd3;
    reg [1:0] rx_state;

    // ── Synchronise RX input ──────────────────────────────
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) rx_sync <= 2'b11;
        else        rx_sync <= {rx_sync[0], rx};
    end

    // ── TX logic ──────────────────────────────────────────
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_div  <= 32'd868;
            tx_busy   <= 1'b0;
            baud_cnt  <= 32'h0;
            bit_cnt   <= 4'h0;
            shift_reg <= 10'h3FF;
        end else begin
            if (we) begin
                case (addr)
                    4'h0: begin
                        if (!tx_busy) begin
                            tx_data_reg <= wdata[7:0];
                            tx_busy     <= 1'b1;
                            shift_reg   <= {1'b1, wdata[7:0], 1'b0};
                            baud_cnt    <= 32'h0;
                            bit_cnt     <= 4'd0;
                        end
                    end
                    4'hC: baud_div <= wdata;
                    default: begin end
                endcase
            end
            if (tx_busy) begin
                if (baud_cnt == baud_div) begin
                    baud_cnt  <= 32'h0;
                    shift_reg <= {1'b1, shift_reg[9:1]};
                    bit_cnt   <= bit_cnt + 1;
                    if (bit_cnt == 4'd9) tx_busy <= 1'b0;
                end else begin
                    baud_cnt <= baud_cnt + 1;
                end
            end
        end
    end

    // ── RX logic ──────────────────────────────────────────
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_state    <= RX_IDLE;
            rx_baud_cnt <= 32'h0;
            rx_bit_cnt  <= 4'h0;
            rx_shift    <= 9'h0;
            rx_data_reg <= 8'h0;
            rx_ready    <= 1'b0;
            rx_busy     <= 1'b0;
        end else begin
            rx_ready <= 1'b0;
            case (rx_state)
                RX_IDLE: begin
                    if (!rx_clean) begin          // start bit detected
                        rx_state    <= RX_START;
                        rx_baud_cnt <= baud_div >> 1; // sample mid-bit
                    end
                end
                RX_START: begin
                    if (rx_baud_cnt == 32'h0) begin
                        if (!rx_clean) begin      // valid start bit
                            rx_state    <= RX_DATA;
                            rx_baud_cnt <= baud_div;
                            rx_bit_cnt  <= 4'd0;
                            rx_busy     <= 1'b1;
                        end else begin
                            rx_state <= RX_IDLE;  // glitch
                        end
                    end else begin
                        rx_baud_cnt <= rx_baud_cnt - 1;
                    end
                end
                RX_DATA: begin
                    if (rx_baud_cnt == 32'h0) begin
                        rx_shift    <= {rx_clean, rx_shift[8:1]};
                        rx_baud_cnt <= baud_div;
                        rx_bit_cnt  <= rx_bit_cnt + 1;
                        if (rx_bit_cnt == 4'd7) rx_state <= RX_STOP;
                    end else begin
                        rx_baud_cnt <= rx_baud_cnt - 1;
                    end
                end
                RX_STOP: begin
                    if (rx_baud_cnt == 32'h0) begin
                        rx_data_reg <= rx_shift[8:1];
                        rx_ready    <= 1'b1;
                        rx_busy     <= 1'b0;
                        rx_state    <= RX_IDLE;
                    end else begin
                        rx_baud_cnt <= rx_baud_cnt - 1;
                    end
                end
            endcase
            // clear ready on CPU read
            if (!we && addr == 4'h8) rx_ready <= 1'b0;
        end
    end

    // ── Register read ─────────────────────────────────────
    always @(*) begin
        case (addr)
            4'h4:    rdata = {31'h0, tx_busy};
            4'h8:    rdata = {23'h0, rx_ready, rx_data_reg};
            4'hC:    rdata = baud_div;
            default: rdata = 32'h0;
        endcase
    end

    assign tx  = tx_busy ? shift_reg[0] : 1'b1;
    assign irq = rx_ready | ~tx_busy;
endmodule
