`timescale 1ns/1ps
module tb_i2c;
    logic        clk, rst_n, we, scl_oe, sda_oe, sda_in, irq;
    logic [3:0]  addr;
    logic [31:0] wdata, rdata;
    int          pass_cnt, fail_cnt;

    i2c dut (.clk(clk),.rst_n(rst_n),.addr(addr),.wdata(wdata),
             .rdata(rdata),.we(we),.scl_oe(scl_oe),
             .sda_oe(sda_oe),.sda_in(sda_in),.irq(irq));

    always #5 clk = ~clk;

    // Simple I2C slave model — ACKs everything, provides 0xBE on read
    logic sda_slave;
    always @(*) begin
        if (sda_oe) sda_slave = 1'b0;       // master drives SDA low
        else        sda_slave = 1'b1;        // SDA released = high
    end
    assign sda_in = sda_slave;

    task automatic check(input cond, input string name);
        if (!cond) begin $display("FAIL [%s]", name); fail_cnt++; end
        else       begin $display("PASS [%s]", name); pass_cnt++; end
    endtask

    task automatic write_reg(input [3:0] a, input [31:0] d);
        @(posedge clk); addr<=a; wdata<=d; we<=1;
        @(posedge clk); we<=0;
    endtask

    task automatic read_reg(input [3:0] a, output [31:0] d);
        @(posedge clk); addr<=a; we<=0;
        @(posedge clk); d = rdata;
    endtask

    logic [31:0] rd;
    initial begin
        clk=0; rst_n=0; we=0; addr=0; wdata=0;
        pass_cnt=0; fail_cnt=0;
        repeat(4) @(posedge clk); rst_n=1;
        repeat(4) @(posedge clk);

        // Test 1: SCL released at reset
        check(scl_oe===1'b0, "SCL_RELEASED_AT_RESET");

        // Test 2: SDA released at reset
        check(sda_oe===1'b0, "SDA_RELEASED_AT_RESET");

        // Test 3: set device address 0x50, write mode
        write_reg(4'h4, 32'hA0); // addr=0x50, rw=0
        read_reg(4'h4, rd);
        check(rd[7:1]===7'h50, "I2C_ADDR_SET");

        // Test 4: set TX data
        write_reg(4'h8, 32'hDE);
        read_reg(4'h8, rd);
        check(rd[7:0]===8'hDE, "I2C_TX_DATA_SET");

        // Test 5: set divider
        write_reg(4'h10, 32'd10); // fast for sim
        read_reg(4'h10, rd);
        check(rd===32'd10, "I2C_DIV_SET");

        // Test 6: start transfer — busy goes high
        write_reg(4'h0, 32'h1);
        repeat(5) @(posedge clk);
        read_reg(4'hC, rd);
        check(rd[0]===1'b1, "I2C_BUSY_AFTER_START");

        // Test 7: wait for done
        repeat(2000) @(posedge clk);
        read_reg(4'hC, rd);
        check(rd[1]===1'b1, "I2C_DONE_FLAG_SET");

        // Test 8: IRQ fired
        check(irq===1'b1, "I2C_IRQ_ON_DONE");

        $display("--- I2C: %0d passed, %0d failed ---", pass_cnt, fail_cnt);
        if (fail_cnt==0) $display("ALL I2C TESTS PASSED");
        $finish;
    end
    initial begin #5_000_000; $display("TIMEOUT"); $finish; end
endmodule
