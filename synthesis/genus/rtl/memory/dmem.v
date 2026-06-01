module dmem (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire [3:0]  we,
    input  wire        re,
    output reg  [31:0] rdata
);
    reg [31:0] mem [0:2047];
    wire [10:0] idx = addr[12:2];

    always @(posedge clk) begin
        if (we[0]) mem[idx][7:0]   <= wdata[7:0];
        if (we[1]) mem[idx][15:8]  <= wdata[15:8];
        if (we[2]) mem[idx][23:16] <= wdata[23:16];
        if (we[3]) mem[idx][31:24] <= wdata[31:24];
    end

    always @(*) begin
        if (re) rdata = mem[idx];
        else    rdata = 32'h0;
    end
endmodule
