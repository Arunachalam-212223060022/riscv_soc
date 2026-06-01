`timescale 1ns/1ps
module tb_immgen;
    logic [31:0] instr, imm_out;
    int          pass_cnt, fail_cnt;

    immgen dut (.instr(instr), .imm_out(imm_out));

    task automatic check(input [31:0] i, input [31:0] exp, input string name);
        instr = i; #1;
        if (imm_out !== exp) begin
            $display("FAIL [%s] instr=%0h => got %0h expected %0h", name, i, imm_out, exp);
            fail_cnt++;
        end else begin
            $display("PASS [%s] imm=%0h", name, imm_out);
            pass_cnt++;
        end
    endtask

    initial begin
        pass_cnt = 0; fail_cnt = 0;

        check(32'h00A00093, 32'h0000000A, "I_pos");
        check(32'hFFF00093, 32'hFFFFFFFF, "I_neg_m1");

        check(32'h00A12223, 32'h00000004, "S_pos");
        check(32'hFEA12E23, 32'hFFFFFFFC, "S_neg");

        check(32'h00208463, 32'h00000008, "B_pos");
        check(32'hFE208EE3, 32'hFFFFFFFC, "B_neg");

        check(32'hDEADB537, 32'hDEADB000, "U_LUI");
        check(32'hDEADB517, 32'hDEADB000, "U_AUIPC");

        check(32'h004000EF, 32'h00000004, "J_pos");
        check(32'hFFDFF0EF, 32'hFFFFFFFE, "J_neg");

        $display("--- IMMGEN: %0d passed, %0d failed ---", pass_cnt, fail_cnt);
        if (fail_cnt == 0) $display("ALL IMMGEN TESTS PASSED");
        $finish;
    end
endmodule
