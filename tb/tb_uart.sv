`timescale 1ns/1ps
module tb_uart;
    logic        clk, rst_n, we, tx, rx, irq;
    logic [3:0]  addr;
    logic [31:0] wdata, rdata;
    int          pass_cnt, fail_cnt;

    uart dut (.clk(clk),.rst_n(rst_n),.addr(addr),.wdata(wdata),
              .rdata(rdata),.we(we),.tx(tx),.rx(rx),.irq(irq));

    always #5 clk = ~clk;

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

    // Loopback: connect tx → rx through baud-rate delay
    logic [9:0] loopback_shift;
    integer     lb_cnt;
    initial begin
        loopback_shift = 10'h3FF;
        lb_cnt = 0;
        forever begin
            @(posedge clk);
            lb_cnt = lb_cnt + 1;
            if (lb_cnt == 868) begin
                lb_cnt = 0;
                loopback_shift = {tx, loopback_shift[9:1]};
            end
        end
    end
    assign rx = loopback_shift[0];

    logic [31:0] rd;
    initial begin
        clk=0; rst_n=0; we=0; addr=0; wdata=0;
        pass_cnt=0; fail_cnt=0;
        repeat(4) @(posedge clk); rst_n=1;
        repeat(4) @(posedge clk);

        // Test 1: TX idle high
        check(tx===1'b1, "TX_IDLE_HIGH");

        // Test 2: baud_div default 868
        read_reg(4'hC, rd);
        check(rd===32'd868, "BAUD_DIV_DEFAULT_868");

        // Test 3: write new baud div
        write_reg(4'hC, 32'd434);
        read_reg(4'hC, rd);
        check(rd===32'd434, "BAUD_DIV_WRITE");
        write_reg(4'hC, 32'd868); // restore

        // Test 4: send byte 0x55 — check TX goes busy
        write_reg(4'h0, 32'h55);
        read_reg(4'h4, rd);
        check(rd[0]===1'b1, "TX_BUSY_AFTER_SEND");

        // Test 5: wait TX done
        repeat(9*870) @(posedge clk);
        read_reg(4'h4, rd);
        check(rd[0]===1'b0, "TX_NOT_BUSY_AFTER_DONE");

        // Test 6: RX received via loopback
        repeat(100) @(posedge clk);
        read_reg(4'h8, rd);
        check(rd[8]===1'b1, "RX_READY_SET");
        check(rd[7:0]===8'h55, "RX_DATA_CORRECT_0x55");

        $display("--- UART: %0d passed, %0d failed ---", pass_cnt, fail_cnt);
        if (fail_cnt==0) $display("ALL UART TESTS PASSED");
        $finish;
    end
    initial begin #50_000_000; $display("TIMEOUT"); $finish; end
endmodule
