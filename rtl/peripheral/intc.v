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
    reg [31:0] enable_reg;
    reg [31:0] pending;
    reg [31:0] priority_reg; // bit per source: 1=high, 0=low

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_reg   <= 32'h0;
            pending      <= 32'h0;
            priority_reg <= 32'hF; // all high priority by default
        end else begin
            if (irq_uart)  pending[0] <= 1'b1;
            if (irq_timer) pending[1] <= 1'b1;
            if (irq_spi)   pending[2] <= 1'b1;
            if (irq_i2c)   pending[3] <= 1'b1;
            if (we) begin
                case (addr)
                    4'h4: enable_reg   <= wdata;
                    4'h8: pending      <= pending & ~wdata; // write 1 to clear
                    4'hC: priority_reg <= wdata;
                    default: begin end
                endcase
            end
        end
    end

    always @(*) begin
        case (addr)
            4'h0:    rdata = pending;
            4'h4:    rdata = enable_reg;
            4'hC:    rdata = priority_reg;
            default: rdata = 32'h0;
        endcase
    end

    // Priority encoder — high priority sources fire first
    wire [31:0] active       = pending & enable_reg;
    wire [31:0] high_pri     = active & priority_reg;
    assign irq_to_cpu = |high_pri ? |high_pri : |active;
endmodule
