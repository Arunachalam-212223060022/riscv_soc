`timescale 1ns/1ps
module tb_regfile;
    logic        clk, we;
    logic [4:0]  rs1, rs2, rd;
    logic [31:0] wdata, rs1_data, rs2_data;
    int          pass_cnt, fail_cnt;

    regfile dut (.clk(clk), .we(we), .rs1(rs1), .rs2(rs2), .rd(rd),
                 .wdata(wdata), .rs1_data(rs1_data), .rs2_data(rs2_data));

    always #5 clk = ~clk;

    task automatic write_reg(input [4:0] r, input [31:0] val);
        we = 1; rd = r; wdata = val; @(posedge clk); #1; we = 0;
    endtask

    task automatic check_read(input [4:0] r, input [31:0] exp, input string name);
        rs1 = r; #1;
        if (rs1_data !== exp) begin
            $display("FAIL [%s] x%0d => got %0h expected %0h", name, r, rs1_data, exp);
            fail_cnt++;
        end else begin
            $display("PASS [%s] x%0d = %0h", name, r, rs1_data);
            pass_cnt++;
        end
    endtask

    initial begin
        clk = 0; we = 0; pass_cnt = 0; fail_cnt = 0;
        rs1 = 0; rs2 = 0; rd = 0; wdata = 0;
        @(posedge clk); #1;

        write_reg(5'd1,  32'hDEAD_BEEF);
        write_reg(5'd2,  32'hCAFE_BABE);
        write_reg(5'd15, 32'h1234_5678);
        write_reg(5'd31, 32'hFFFF_FFFF);
        write_reg(5'd0,  32'hAAAA_AAAA);

        check_read(5'd1,  32'hDEAD_BEEF, "x1");
        check_read(5'd2,  32'hCAFE_BABE, "x2");
        check_read(5'd15, 32'h1234_5678, "x15");
        check_read(5'd31, 32'hFFFF_FFFF, "x31");
        check_read(5'd0,  32'h0,         "x0_hardwired");

        rs2 = 5'd2; #1;
        if (rs2_data !== 32'hCAFE_BABE) begin
            $display("FAIL [PORT2] x2 port2 => got %0h", rs2_data);
            fail_cnt++;
        end else begin
            $display("PASS [PORT2] simultaneous read x2 = %0h", rs2_data);
            pass_cnt++;
        end

        $display("--- REGFILE: %0d passed, %0d failed ---", pass_cnt, fail_cnt);
        if (fail_cnt == 0) $display("ALL REGFILE TESTS PASSED");
        $finish;
    end
endmodule
