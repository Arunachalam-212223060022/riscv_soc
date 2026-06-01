module alu_ctrl (
    input  wire [1:0] alu_op,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg  [3:0] alu_sel
);
    always @(*) begin
        case (alu_op)
            2'b00: alu_sel = 4'b0000;
            2'b01: alu_sel = 4'b0001;
            2'b10: begin
                case (funct3)
                    3'b000: alu_sel = funct7[5] ? 4'b0001 : 4'b0000;
                    3'b001: alu_sel = 4'b0101;
                    3'b010: alu_sel = 4'b1000;
                    3'b011: alu_sel = 4'b1001;
                    3'b100: alu_sel = 4'b0100;
                    3'b101: alu_sel = funct7[5] ? 4'b0111 : 4'b0110;
                    3'b110: alu_sel = 4'b0011;
                    3'b111: alu_sel = 4'b0010;
                    default: alu_sel = 4'b0000;
                endcase
            end
            default: alu_sel = 4'b0000;
        endcase
    end
endmodule
