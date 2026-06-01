module intc (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    input  wire        we,
    input  wire        irq_uart,
    input  wire        irq_timer,
    input  wire        irq_spi,
    input  wire        irq_i2c,
    output wire        irq_to_cpu
);
    reg [3:0] enable_reg;
    reg [3:0] pending;
    reg [3:0] priority_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_reg   <= 4'h0;
            pending      <= 4'h0;
            priority_reg <= 4'hF;
        end else begin
            pending[0] <= (pending[0] | irq_uart)  & ~(we && addr == 4'h8 && wdata[0]);
            pending[1] <= (pending[1] | irq_timer) & ~(we && addr == 4'h8 && wdata[1]);
            pending[2] <= (pending[2] | irq_spi)   & ~(we && addr == 4'h8 && wdata[2]);
            pending[3] <= (pending[3] | irq_i2c)   & ~(we && addr == 4'h8 && wdata[3]);
            if (we) begin
                case (addr)
                    4'h4: enable_reg   <= wdata[3:0];
                    4'hC: priority_reg <= wdata[3:0];
                    default: begin end
                endcase
            end
        end
    end

    always @(*) begin
        case (addr)
            4'h0:    rdata = {28'h0, pending};
            4'h4:    rdata = {28'h0, enable_reg};
            4'hC:    rdata = {28'h0, priority_reg};
            default: rdata = 32'h0;
        endcase
    end

    wire [3:0] active    = pending & enable_reg;
    wire [3:0] high_pri  = active & priority_reg;
    assign irq_to_cpu = |high_pri | |active;
endmodule
