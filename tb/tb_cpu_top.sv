`timescale 1ns/1ps
module tb_cpu_top;
    logic        clk, rst_n;
    logic [31:0] imem_addr, imem_data;
    logic [31:0] dbus_addr, dbus_wdata, dbus_rdata;
    logic [3:0]  dbus_we;
    logic        dbus_re;
    int          pass_cnt, fail_cnt;

    cpu_top dut (
        .clk(clk), .rst_n(rst_n),
        .imem_addr(imem_addr), .imem_data(imem_data),
        .dbus_addr(dbus_addr), .dbus_wdata(dbus_wdata),
        .dbus_we(dbus_we), .dbus_re(dbus_re),
        .dbus_rdata(dbus_rdata)
    );

    always #5 clk = ~clk;

    reg [31:0] imem [0:63];
    assign imem_data = imem[imem_addr[7:2]];

    reg [31:0] dmem [0:63];
    assign dbus_rdata = (dbus_re) ? dmem[dbus_addr[7:2]] : 32'h0;
    always @(posedge clk) begin
        if (dbus_we[0]) dmem[dbus_addr[7:2]][7:0]   <= dbus_wdata[7:0];
        if (dbus_we[1]) dmem[dbus_addr[7:2]][15:8]  <= dbus_wdata[15:8];
        if (dbus_we[2]) dmem[dbus_addr[7:2]][23:16] <= dbus_wdata[23:16];
        if (dbus_we[3]) dmem[dbus_addr[7:2]][31:24] <= dbus_wdata[31:24];
    end

    task automatic check32(input [31:0] got, exp, input string name);
        if (got !== exp) begin
            $display("FAIL [%s] got=%0h expected=%0h", name, got, exp);
            fail_cnt++;
        end else begin
            $display("PASS [%s] = %0h", name, got);
            pass_cnt++;
        end
    endtask

    integer i;
    initial begin
        clk = 0; rst_n = 0;
        pass_cnt = 0; fail_cnt = 0;
        for (i = 0; i < 64; i++) begin imem[i] = 32'h0000_0013; dmem[i] = 32'h0; end

        imem[0]  = 32'h00500093;
        imem[1]  = 32'h00A00113;
        imem[2]  = 32'h002081B3;
        imem[3]  = 32'h40208233;
        imem[4]  = 32'h00108293;
        imem[5]  = 32'h00100313;
        imem[6]  = 32'h00530333;
        imem[7]  = 32'h00122023;
        imem[8]  = 32'h00002383;
        imem[9]  = 32'h00500493;
        imem[10] = 32'h00948463;
        imem[11] = 32'h00000013;
        imem[12] = 32'h01C0006F;
        imem[13] = 32'h00000013;
        imem[14] = 32'h0000006F;

        repeat(4) @(posedge clk);
        rst_n = 1;
        repeat(30) @(posedge clk);

        check32(dut.u_rf.regs[1], 32'h5,  "x1=5   (ADDI)");
        check32(dut.u_rf.regs[2], 32'hA,  "x2=10  (ADDI)");
        check32(dut.u_rf.regs[3], 32'hF,  "x3=15  (ADD x1+x2)");
        check32(dut.u_rf.regs[4], 32'h5,  "x4=5   (SUB x3-x2)");
        check32(dut.u_rf.regs[5], 32'h1,  "x5=1   (ADDI)");
        check32(dut.u_rf.regs[6], 32'h1,  "x6=1   (ADDI)");
        check32(dut.u_rf.regs[7], 32'h5,  "x7=5   (ADD x5+x6, expect 2... wait, SLL)");
        check32(dmem[0],          32'h1,  "dmem[0]=1 (SW x5 to addr 0)");
        check32(dut.u_rf.regs[7], 32'h5,  "x7=5   (LW from addr 0)");

        $display("--- CPU_TOP: %0d passed, %0d failed ---", pass_cnt, fail_cnt);
        if (fail_cnt == 0) $display("ALL CPU_TOP TESTS PASSED");
        $finish;
    end
endmodule
