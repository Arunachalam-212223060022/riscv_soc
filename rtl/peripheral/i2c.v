module i2c (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    input  wire        we,
    // I2C pins (open-drain — drive low or tristate)
    output reg         scl_oe,   // 1=drive SCL low
    output reg         sda_oe,   // 1=drive SDA low
    input  wire        sda_in,
    output wire        irq
);
    // Registers
    // 0x0 CTRL   — bit0=start_xfer, bit1=read_mode
    // 0x4 ADDR   — 7-bit device address [7:1], rw [0]
    // 0x8 DATA   — write data / read result
    // 0xC STATUS — bit0=busy, bit1=done, bit2=ack_err
    // 0x10 DIV   — SCL divider (default 250 → 100kHz @ 50MHz)

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

    // States
    localparam  IDLE      = 5'd0,
                START1    = 5'd1,
                START2    = 5'd2,
                ADDR_DATA = 5'd3,
                ACK       = 5'd4,
                RD_DATA   = 5'd5,
                RD_ACK    = 5'd6,
                STOP1     = 5'd7,
                STOP2     = 5'd8,
                DONE_ST   = 5'd9;

    wire clk_en;
    assign clk_en = (div_cnt == div_reg);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) div_cnt <= 32'h0;
        else if (clk_en) div_cnt <= 32'h0;
        else div_cnt <= div_cnt + 1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_reg  <= 32'd250;
            dev_addr <= 7'h0;
            rw_bit   <= 1'b0;
            tx_data  <= 8'h0;
            rx_data  <= 8'h0;
            busy     <= 1'b0;
            done     <= 1'b0;
            ack_err  <= 1'b0;
            state    <= IDLE;
            bit_cnt  <= 4'd0;
            scl_r    <= 1'b1;
            scl_oe   <= 1'b0;
            sda_oe   <= 1'b0;
            shift_reg<= 8'h0;
        end else begin
            done <= 1'b0;
            if (we) begin
                case (addr)
                    4'h4:  begin dev_addr <= wdata[7:1]; rw_bit <= wdata[0]; end
                    4'h8:  tx_data  <= wdata[7:0];
                    4'h10: div_reg  <= wdata;
                    4'h0: begin
                        if (wdata[0] && !busy) begin
                            busy    <= 1'b1;
                            ack_err <= 1'b0;
                            state   <= START1;
                        end
                    end
                    default: begin end
                endcase
            end

            if (busy && clk_en) begin
                case (state)
                    START1: begin   // SDA high, SCL high
                        sda_oe <= 1'b0; scl_oe <= 1'b0;
                        state  <= START2;
                    end
                    START2: begin   // SDA falls while SCL high = START
                        sda_oe  <= 1'b1;
                        shift_reg <= {dev_addr, rw_bit};
                        bit_cnt <= 4'd7;
                        state   <= ADDR_DATA;
                    end
                    ADDR_DATA: begin
                        scl_oe  <= ~scl_r;
                        scl_r   <= ~scl_r;
                        if (!scl_r) begin   // SCL going high — data must be stable
                            sda_oe <= ~shift_reg[7];
                        end else begin      // SCL going low — shift next bit
                            shift_reg <= {shift_reg[6:0], 1'b0};
                            if (bit_cnt == 4'd0) state <= ACK;
                            else bit_cnt <= bit_cnt - 1;
                        end
                    end
                    ACK: begin
                        scl_oe <= ~scl_r; scl_r <= ~scl_r;
                        sda_oe <= 1'b0;   // release SDA for slave ACK
                        if (scl_r) begin
                            ack_err <= sda_in; // SDA should be 0 (ACK)
                            if (!rw_bit) begin
                                shift_reg <= tx_data;
                                bit_cnt   <= 4'd7;
                                state     <= ADDR_DATA; // reuse for data byte
                                rw_bit    <= 1'b1;      // flag: now sending data
                            end else begin
                                bit_cnt <= 4'd7;
                                state   <= RD_DATA;
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
                    RD_ACK: begin   // send NACK (master done reading)
                        scl_oe <= ~scl_r; scl_r <= ~scl_r;
                        sda_oe <= 1'b1;
                        if (scl_r) begin
                            rx_data <= shift_reg;
                            state   <= STOP1;
                        end
                    end
                    STOP1: begin    // SCL high, SDA still low
                        scl_oe <= 1'b0; sda_oe <= 1'b1;
                        state  <= STOP2;
                    end
                    STOP2: begin    // SDA rises while SCL high = STOP
                        sda_oe <= 1'b0;
                        state  <= DONE_ST;
                    end
                    DONE_ST: begin
                        busy   <= 1'b0;
                        done   <= 1'b1;
                        state  <= IDLE;
                    end
                    default: state <= IDLE;
                endcase
            end
        end
    end

    always @(*) begin
        case (addr)
            4'h8:    rdata = {24'h0, rx_data};
            4'hC:    rdata = {29'h0, ack_err, done, busy};
            4'h10:   rdata = div_reg;
            default: rdata = 32'h0;
        endcase
    end

    assign irq = done;
endmodule
