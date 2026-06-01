module spi (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    input  wire        we,
    // SPI pins
    output wire        sck,
    output wire        mosi,
    input  wire        miso,
    output reg         cs_n,
    output wire        irq
);
    // Registers
    // 0x0 DATA  — write to send, read last received
    // 0x4 STATUS— bit0=busy, bit1=done
    // 0x8 CTRL  — bit0=cs_en (assert CS), bit1=cpol, bit2=cpha
    // 0xC DIV   — clock divider (default 4)

    reg [31:0] div_reg;
    reg [7:0]  tx_reg, rx_reg;
    reg        busy, done;
    reg [31:0] div_cnt;
    reg [3:0]  bit_cnt;
    reg        sck_r;
    reg [7:0]  shift_tx;
    reg [7:0]  shift_rx;
    reg        ctrl_cs;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_reg  <= 32'd4;
            tx_reg   <= 8'h0;
            rx_reg   <= 8'h0;
            busy     <= 1'b0;
            done     <= 1'b0;
            div_cnt  <= 32'h0;
            bit_cnt  <= 4'd0;
            sck_r    <= 1'b0;
            cs_n     <= 1'b1;
            ctrl_cs  <= 1'b0;
            shift_tx <= 8'h0;
            shift_rx <= 8'h0;
        end else begin
            done <= 1'b0;
            if (we) begin
                case (addr)
                    4'h0: begin
                        if (!busy) begin
                            tx_reg   <= wdata[7:0];
                            shift_tx <= wdata[7:0];
                            busy     <= 1'b1;
                            bit_cnt  <= 4'd0;
                            div_cnt  <= 32'h0;
                            sck_r    <= 1'b0;
                        end
                    end
                    4'h8: begin ctrl_cs <= wdata[0]; cs_n <= ~wdata[0]; end
                    4'hC: div_reg <= wdata;
                    default: begin end
                endcase
            end
            if (busy) begin
                if (div_cnt == div_reg) begin
                    div_cnt <= 32'h0;
                    sck_r   <= ~sck_r;
                    if (!sck_r) begin              // rising edge — sample MISO
                        shift_rx <= {shift_rx[6:0], miso};
                    end else begin                 // falling edge — shift MOSI
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

    always @(*) begin
        case (addr)
            4'h0:    rdata = {24'h0, rx_reg};
            4'h4:    rdata = {30'h0, done, busy};
            4'hC:    rdata = div_reg;
            default: rdata = 32'h0;
        endcase
    end

    assign sck  = sck_r;
    assign mosi = shift_tx[7];
    assign irq  = done;
endmodule
