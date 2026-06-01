`timescale 1ns/1ps
module tb_control;
    logic [6:0] opcode;
    logic       reg_write, alu_src, mem_read, mem_write, mem_to_reg;
    logic       branch, jal, jalr, lui, auipc;
    logic [1:0] alu_op;
    int         pass_cnt, fail_cnt;

    control dut (.*);

    task automatic check(
        input [6:0] op,
        input rw, asrc, mrd, mwr, m2r, br, j, jr, l, au,
        input [1:0] aop,
        input string name
    );
        opcode = op; #1;
        if (reg_write!==rw || alu_src!==asrc || mem_read!==mrd || mem_write!==mwr ||
            mem_to_reg!==m2r || branch!==br || jal!==j || jalr!==jr ||
            lui!==l || auipc!==au || alu_op!==aop) begin
            $display("FAIL [%s] op=%07b", name, op);
            $display("  got:  rw=%b asrc=%b mrd=%b mwr=%b m2r=%b br=%b jal=%b jalr=%b lui=%b auipc=%b aop=%b",
                     reg_write,alu_src,mem_read,mem_write,mem_to_reg,branch,jal,jalr,lui,auipc,alu_op);
            $display("  exp:  rw=%b asrc=%b mrd=%b mwr=%b m2r=%b br=%b jal=%b jalr=%b lui=%b auipc=%b aop=%b",
                     rw,asrc,mrd,mwr,m2r,br,j,jr,l,au,aop);
            fail_cnt++;
        end else begin
            $display("PASS [%s]", name);
            pass_cnt++;
        end
    endtask

    initial begin
        pass_cnt = 0; fail_cnt = 0;
        check(7'b0110011, 1,0,0,0,0,0,0,0,0,0, 2'b10, "R-type");
        check(7'b0010011, 1,1,0,0,0,0,0,0,0,0, 2'b10, "I-ALU");
        check(7'b0000011, 1,1,1,0,1,0,0,0,0,0, 2'b00, "LOAD");
        check(7'b0100011, 0,1,0,1,0,0,0,0,0,0, 2'b00, "STORE");
        check(7'b1100011, 0,0,0,0,0,1,0,0,0,0, 2'b01, "BRANCH");
        check(7'b1101111, 1,0,0,0,0,0,1,0,0,0, 2'b00, "JAL");
        check(7'b1100111, 1,1,0,0,0,0,0,1,0,0, 2'b00, "JALR");
        check(7'b0110111, 1,0,0,0,0,0,0,0,1,0, 2'b00, "LUI");
        check(7'b0010111, 1,0,0,0,0,0,0,0,0,1, 2'b00, "AUIPC");
        $display("--- CONTROL: %0d passed, %0d failed ---", pass_cnt, fail_cnt);
        if (fail_cnt == 0) $display("ALL CONTROL TESTS PASSED");
        $finish;
    end
endmodule
