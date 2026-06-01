module regfile (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        we,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] wdata,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data
);
    reg [31:0] regs [1:31];
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 1; i < 32; i = i + 1)
                regs[i] <= 32'h0;
        end else if (we && rd != 5'h0) begin
            regs[rd] <= wdata;
        end
    end

    assign rs1_data = (rs1 == 5'h0) ? 32'h0 : regs[rs1];
    assign rs2_data = (rs2 == 5'h0) ? 32'h0 : regs[rs2];
endmodule
