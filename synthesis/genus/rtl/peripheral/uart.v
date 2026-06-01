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
    reg [31:0] baud_div;
    reg        tx_busy;
    reg [31:0] baud_cnt;
    reg [3:0]  bit_cnt;
    reg [9:0]  tx_shift;

    reg [1:0]  rx_sync;
    wire       rx_s = rx_sync[1];
    reg [31:0] rx_baud_cnt;
    reg [3:0]  rx_bit_cnt;
    reg [7:0]  rx_shift;
    reg [7:0]  rx_data;
    reg        rx_ready;

    localparam RX_IDLE  = 2'd0,
               RX_START = 2'd1,
               RX_DATA  = 2'd2,
               RX_STOP  = 2'd3;
    reg [1:0] rx_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) rx_sync <= 2'b11;
        else        rx_sync <= {rx_sync[0], rx};
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_div <= 32'd868;
            tx_busy  <= 1'b0;
            baud_cnt <= 32'h0;
            bit_cnt  <= 4'h0;
            tx_shift <= 10'h3FF;
        end else begin
            if (we) begin
                case (addr)
                    4'h0: begin
                        if (!tx_busy) begin
                            tx_busy  <= 1'b1;
                            tx_shift <= {1'b1, wdata[7:0], 1'b0};
                            baud_cnt <= 32'h0;
                            bit_cnt  <= 4'd0;
                        end
                    end
                    4'hC: baud_div <= wdata;
                    default: begin end
                endcase
            end
            if (tx_busy) begin
                if (baud_cnt == baud_div) begin
                    baud_cnt <= 32'h0;
                    tx_shift <= {1'b1, tx_shift[9:1]};
                    bit_cnt  <= bit_cnt + 1;
                    if (bit_cnt == 4'd9) tx_busy <= 1'b0;
                end else begin
                    baud_cnt <= baud_cnt + 1;
                end
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_state    <= RX_IDLE;
            rx_baud_cnt <= 32'h0;
            rx_bit_cnt  <= 4'h0;
            rx_shift    <= 8'h0;
            rx_data     <= 8'h0;
            rx_ready    <= 1'b0;
        end else begin
            if (we && addr == 4'h8) rx_ready <= 1'b0;
            case (rx_state)
                RX_IDLE: begin
                    if (!rx_s) begin
                        rx_state    <= RX_START;
                        rx_baud_cnt <= baud_div >> 1;
                    end
                end
                RX_START: begin
                    if (rx_baud_cnt == 32'h0) begin
                        if (!rx_s) begin
                            rx_state    <= RX_DATA;
                            rx_baud_cnt <= baud_div;
                            rx_bit_cnt  <= 4'd0;
                        end else begin
                            rx_state <= RX_IDLE;
                        end
                    end else begin
                        rx_baud_cnt <= rx_baud_cnt - 1;
                    end
                end
                RX_DATA: begin
                    if (rx_baud_cnt == 32'h0) begin
                        rx_shift    <= {rx_s, rx_shift[7:1]};
                        rx_baud_cnt <= baud_div;
                        rx_bit_cnt  <= rx_bit_cnt + 1;
                        if (rx_bit_cnt == 4'd7) rx_state <= RX_STOP;
                    end else begin
                        rx_baud_cnt <= rx_baud_cnt - 1;
                    end
                end
                RX_STOP: begin
                    if (rx_baud_cnt == 32'h0) begin
                        rx_data  <= rx_shift;
                        rx_ready <= 1'b1;
                        rx_state <= RX_IDLE;
                    end else begin
                        rx_baud_cnt <= rx_baud_cnt - 1;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        case (addr)
            4'h4:    rdata = {31'h0, tx_busy};
            4'h8:    rdata = {23'h0, rx_ready, rx_data};
            4'hC:    rdata = baud_div;
            default: rdata = 32'h0;
        endcase
    end

    assign tx  = tx_busy ? tx_shift[0] : 1'b1;
    assign irq = rx_ready;
endmodule
