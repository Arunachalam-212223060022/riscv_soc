module regfile (
    input  wire        clk,
    input  wire        we,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] wdata,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data
);
    reg [31:0] regs [31:0];
    integer i;
    initial for (i = 0; i < 32; i = i+1) regs[i] = 32'h0;

    always @(posedge clk) begin
        if (we && rd != 5'b0)
            regs[rd] <= wdata;
    end

    assign rs1_data = (rs1 == 5'b0) ? 32'h0 : regs[rs1];
    assign rs2_data = (rs2 == 5'b0) ? 32'h0 : regs[rs2];
endmodule
