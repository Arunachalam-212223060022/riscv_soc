module spi (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    input  wire        we,
    output wire        sck,
    output wire        mosi,
    input  wire        miso,
    output reg         cs_n,
    output wire        irq
);
    reg [31:0] div_reg;
    reg [7:0]  rx_reg;
    reg        busy, done;
    reg [31:0] div_cnt;
    reg [3:0]  bit_cnt;
    reg        sck_r;
    reg [7:0]  shift_tx;
    reg [7:0]  shift_rx;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_reg  <= 32'd4;
            rx_reg   <= 8'h0;
            busy     <= 1'b0;
            done     <= 1'b0;
            div_cnt  <= 32'h0;
            bit_cnt  <= 4'd0;
            sck_r    <= 1'b0;
            cs_n     <= 1'b1;
            shift_tx <= 8'h0;
            shift_rx <= 8'h0;
        end else begin
            done <= 1'b0;
            if (we) begin
                case (addr)
                    4'h0: begin
                        if (!busy) begin
                            shift_tx <= wdata[7:0];
                            busy     <= 1'b1;
                            bit_cnt  <= 4'd0;
                            div_cnt  <= 32'h0;
                            sck_r    <= 1'b0;
                        end
                    end
                    4'h8: cs_n <= ~wdata[0];
                    4'hC: div_reg <= wdata;
                    default: begin end
                endcase
            end
            if (busy) begin
                if (div_cnt == div_reg) begin
                    div_cnt <= 32'h0;
                    sck_r   <= ~sck_r;
                    if (!sck_r) begin
                        shift_rx <= {shift_rx[6:0], miso};
                    end else begin
                        shift_tx <= {shift_tx[6:0], 1'b0};
                        bit_cnt  <= bit_cnt + 1;
                        if (bit_cnt == 4'd7) begin
                            busy    <= 1'b0;
                            done    <= 1'b1;
                            rx_reg  <= {shift_rx[6:0], miso};
                            sck_r   <= 1'b0;
                        end
                    end
                end else begin
                    div_cnt <= div_cnt + 1;
                end
            end
        end
    end

    reg done_latch;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) done_latch <= 1'b0;
        else if (done) done_latch <= 1'b1;
        else if (!we && addr == 4'h4) done_latch <= 1'b0;
    end

    always @(*) begin
        case (addr)
            4'h0:    rdata = {24'h0, rx_reg};
            4'h4:    rdata = {30'h0, done_latch, busy};
            4'hC:    rdata = div_reg;
            default: rdata = 32'h0;
        endcase
    end

    assign sck  = sck_r;
    assign mosi = shift_tx[7];
    assign irq  = done;
endmodule
