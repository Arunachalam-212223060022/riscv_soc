module i2c (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [4:0]  addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    input  wire        we,
    output reg         scl_oe,
    output reg         sda_oe,
    input  wire        sda_in,
    output wire        irq
);
    localparam IDLE      = 5'd0,
               START1    = 5'd1,
               START2    = 5'd2,
               ADDR_DATA = 5'd3,
               ACK       = 5'd4,
               RD_DATA   = 5'd5,
               RD_ACK    = 5'd6,
               STOP1     = 5'd7,
               STOP2     = 5'd8,
               DONE_ST   = 5'd9;

    reg [31:0] div_reg;
    reg [6:0]  dev_addr;
    reg        rw_bit;
    reg [7:0]  tx_data, rx_data;
    reg        busy, done, ack_err;
    reg [31:0] div_cnt;
    reg [4:0]  state;
    reg [3:0]  bit_cnt;
    reg [7:0]  shift_reg;
    reg        scl_r;
    reg        data_phase;

    wire clk_en = (div_cnt == div_reg);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) div_cnt <= 32'h0;
        else if (clk_en) div_cnt <= 32'h0;
        else div_cnt <= div_cnt + 1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_reg   <= 32'd250;
            dev_addr  <= 7'h0;
            rw_bit    <= 1'b0;
            tx_data   <= 8'h0;
            rx_data   <= 8'h0;
            busy      <= 1'b0;
            done      <= 1'b0;
            ack_err   <= 1'b0;
            state     <= IDLE;
            bit_cnt   <= 4'd0;
            scl_r     <= 1'b1;
            scl_oe    <= 1'b0;
            sda_oe    <= 1'b0;
            shift_reg <= 8'h0;
            data_phase<= 1'b0;
        end else begin
            done <= 1'b0;
            if (we) begin
                case (addr)
                    5'h04: begin dev_addr <= wdata[7:1]; rw_bit <= wdata[0]; end
                    5'h08: tx_data  <= wdata[7:0];
                    5'h10: div_reg  <= wdata;
                    5'h00: begin
                        if (wdata[0] && !busy) begin
                            busy       <= 1'b1;
                            ack_err    <= 1'b0;
                            data_phase <= 1'b0;
                            state      <= START1;
                        end
                    end
                    default: begin end
                endcase
            end

            if (busy && clk_en) begin
                case (state)
                    START1: begin
                        sda_oe <= 1'b0; scl_oe <= 1'b0;
                        state  <= START2;
                    end
                    START2: begin
                        sda_oe    <= 1'b1;
                        shift_reg <= {dev_addr, rw_bit};
                        bit_cnt   <= 4'd7;
                        state     <= ADDR_DATA;
                    end
                    ADDR_DATA: begin
                        scl_oe <= ~scl_r;
                        scl_r  <= ~scl_r;
                        if (!scl_r) begin
                            sda_oe <= ~shift_reg[7];
                        end else begin
                            shift_reg <= {shift_reg[6:0], 1'b0};
                            if (bit_cnt == 4'd0) state <= ACK;
                            else bit_cnt <= bit_cnt - 1;
                        end
                    end
                    ACK: begin
                        scl_oe <= ~scl_r; scl_r <= ~scl_r;
                        sda_oe <= 1'b0;
                        if (scl_r) begin
                            ack_err <= sda_in;
                            if (!data_phase && !rw_bit) begin
                                shift_reg  <= tx_data;
                                bit_cnt    <= 4'd7;
                                data_phase <= 1'b1;
                                state      <= ADDR_DATA;
                            end else if (rw_bit) begin
                                bit_cnt <= 4'd7;
                                state   <= RD_DATA;
                            end else begin
                                state <= STOP1;
                            end
                        end
                    end
                    RD_DATA: begin
                        scl_oe <= ~scl_r; scl_r <= ~scl_r;
                        sda_oe <= 1'b0;
                        if (!scl_r) begin
                            shift_reg <= {shift_reg[6:0], sda_in};
                            if (bit_cnt == 4'd0) state <= RD_ACK;
                            else bit_cnt <= bit_cnt - 1;
                        end
                    end
                    RD_ACK: begin
                        scl_oe <= ~scl_r; scl_r <= ~scl_r;
                        sda_oe <= 1'b1;
                        if (scl_r) begin
                            rx_data <= shift_reg;
                            state   <= STOP1;
                        end
                    end
                    STOP1: begin
                        scl_oe <= 1'b0; sda_oe <= 1'b1;
                        state  <= STOP2;
                    end
                    STOP2: begin
                        sda_oe <= 1'b0;
                        state  <= DONE_ST;
                    end
                    DONE_ST: begin
                        busy  <= 1'b0;
                        done  <= 1'b1;
                        state <= IDLE;
                    end
                    default: state <= IDLE;
                endcase
            end
        end
    end

    always @(*) begin
        case (addr)
            5'h08: rdata = {24'h0, rx_data};
            5'h0C: rdata = {29'h0, ack_err, done, busy};
            5'h10: rdata = div_reg;
            default: rdata = 32'h0;
        endcase
    end

    assign irq = done;
endmodule
