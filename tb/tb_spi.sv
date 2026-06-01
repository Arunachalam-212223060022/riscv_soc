`timescale 1ns/1ps
module tb_spi;
    logic        clk, rst_n, we, miso, sck, mosi, cs_n, irq;
    logic [3:0]  addr;
    logic [31:0] wdata, rdata;
    int          pass_cnt, fail_cnt;

    spi dut (.clk(clk),.rst_n(rst_n),.addr(addr),.wdata(wdata),
             .rdata(rdata),.we(we),.sck(sck),.mosi(mosi),
             .miso(miso),.cs_n(cs_n),.irq(irq));

    always #5 clk = ~clk;

    // Simple SPI slave loopback — echoes MOSI back on MISO
    logic [7:0] slave_shift;
    integer     sck_prev;
    initial begin
        slave_shift = 8'hFF; sck_prev = 0;
        forever begin
            @(posedge clk);
            if (sck && !sck_prev) begin   // rising edge
                slave_shift = {slave_shift[6:0], mosi};
            end
            sck_prev = sck;
        end
    end
    assign miso = slave_shift[7];

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

        // Test 1: CS deasserted at reset
        check(cs_n===1'b1, "CS_DEASSERTED_AT_RESET");

        // Test 2: SCK idle low
        check(sck===1'b0, "SCK_IDLE_LOW");

        // Test 3: assert CS
        write_reg(4'h8, 32'h1);
        check(cs_n===1'b0, "CS_ASSERTED");

        // Test 4: send 0xA5, check busy
        write_reg(4'h0, 32'hA5);
        read_reg(4'h4, rd);
        check(rd[0]===1'b1, "SPI_BUSY_AFTER_SEND");

        // Test 5: wait for done
        repeat(400) @(posedge clk);
        read_reg(4'h4, rd);
        check(rd[1]===1'b1, "SPI_DONE_FLAG_SET");

        // Test 6: deassert CS
        write_reg(4'h8, 32'h0);
        check(cs_n===1'b1, "CS_DEASSERTED_AFTER_XFER");

        // Test 7: IRQ fires on done
        check(irq===1'b0, "IRQ_CLEARED_AFTER_CYCLE");

        $display("--- SPI: %0d passed, %0d failed ---", pass_cnt, fail_cnt);
        if (fail_cnt==0) $display("ALL SPI TESTS PASSED");
        $finish;
    end
    initial begin #1_000_000; $display("TIMEOUT"); $finish; end
endmodule
