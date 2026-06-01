`timescale 1ns/1ps
module tb_alu;
    logic [31:0] a, b, result;
    logic [3:0]  alu_sel;
    logic        zero;
    int          pass_cnt, fail_cnt;

    alu dut (.a(a), .b(b), .alu_sel(alu_sel), .result(result), .zero(zero));

    task automatic check(input [31:0] exp, input [31:0] a_in, b_in, input [3:0] sel, input string name);
        a = a_in; b = b_in; alu_sel = sel; #1;
        if (result !== exp) begin
            $display("FAIL [%s] a=%0h b=%0h sel=%b => got %0h expected %0h", name, a_in, b_in, sel, result, exp);
            fail_cnt++;
        end else begin
            $display("PASS [%s] result=%0h", name, result);
            pass_cnt++;
        end
    endtask

    initial begin
        pass_cnt = 0; fail_cnt = 0;
        check(32'h5,        32'h3,        32'h2,        4'b0000, "ADD");
        check(32'h1,        32'h3,        32'h2,        4'b0001, "SUB");
        check(32'h2,        32'h3,        32'h6,        4'b0010, "AND");
        check(32'h7,        32'h3,        32'h6,        4'b0011, "OR");
        check(32'h5,        32'h3,        32'h6,        4'b0100, "XOR");
        check(32'hC,        32'h3,        32'h2,        4'b0101, "SLL");
        check(32'h1,        32'h4,        32'h2,        4'b0110, "SRL");
        check(32'hFFFFFFFE, 32'hFFFFFFFC, 32'h1,        4'b0111, "SRA");
        check(32'h1,        32'h1,        32'h2,        4'b1000, "SLT");
        check(32'h0,        32'h2,        32'h1,        4'b1000, "SLT_false");
        check(32'h1,        32'h1,        32'h2,        4'b1001, "SLTU");
        check(32'h0,        32'h2,        32'h1,        4'b1001, "SLTU_false");
        a = 32'h5; b = 32'h5; alu_sel = 4'b0001; #1;
        if (zero !== 1'b1) begin
            $display("FAIL [ZERO_FLAG] expected zero=1 when result=0");
            fail_cnt++;
        end else begin
            $display("PASS [ZERO_FLAG] zero=1 correct");
            pass_cnt++;
        end
        $display("--- ALU: %0d passed, %0d failed ---", pass_cnt, fail_cnt);
        if (fail_cnt == 0) $display("ALL ALU TESTS PASSED");
        $finish;
    end
endmodule
