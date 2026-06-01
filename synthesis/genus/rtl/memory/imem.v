module imem (
    input  wire [31:0] addr,
    output reg  [31:0] data
);
    always @(*) begin
        case (addr[12:2])
        11'd0: data = 32'h100002b7;
        11'd1: data = 32'h20000337;
        11'd2: data = 32'h200003b7;
        11'd3: data = 32'h10038393;
        11'd4: data = 32'h04400513;
        11'd5: data = 32'h00050583;
        11'd6: data = 32'h00058e63;
        11'd7: data = 32'h0042a603;
        11'd8: data = 32'h00167613;
        11'd9: data = 32'hfe061ce3;
        11'd10: data = 32'h00b2a023;
        11'd11: data = 32'h00150513;
        11'd12: data = 32'hfe5ff06f;
        11'd13: data = 32'h00432503;
        11'd14: data = 32'h00a32023;
        11'd15: data = 32'h00a3a023;
        11'd16: data = 32'hff5ff06f;
        11'd17: data = 32'h43534952;
        11'd18: data = 32'h4f532056;
        11'd19: data = 32'h4b4f2043;
        11'd20: data = 32'h00000a0d;
        default: data = 32'h00000013;
        endcase
    end
endmodule
