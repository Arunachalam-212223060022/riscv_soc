module gpio (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    input  wire        we,
    output reg  [7:0]  gpio_out,
    input  wire [7:0]  gpio_in
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) gpio_out <= 8'h0;
        else if (we && addr == 4'h0) gpio_out <= wdata[7:0];
    end

    always @(*) begin
        case (addr)
            4'h0: rdata = {24'h0, gpio_out};
            4'h4: rdata = {24'h0, gpio_in};
            default: rdata = 32'h0;
        endcase
    end
endmodule
