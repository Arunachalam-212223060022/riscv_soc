`timescale 1ns/1ps
module tb_timer;
    logic        clk, rst_n, we, irq;
    logic [3:0]  addr;
    logic [31:0] wdata, rdata;
    int          pass_cnt, fail_cnt;

    timer dut (.clk(clk), .rst_n(rst_n), .addr(addr), .wdata(wdata),
               .rdata(rdata), .we(we), .irq(irq));

    always #5 clk = ~clk;

    task automatic write_reg(input [3:0] a, input [31:0] d);
        addr = a; wdata = d; we = 1; @(posedge clk); #1; we = 0;
    endtask

    task automatic read_reg(input [3:0] a, output [31:0] d);
        addr = a; #1; d = rdata;
    endtask

    initial begin
        clk = 0; rst_n = 0; we = 0; addr = 0; wdata = 0;
        pass_cnt = 0; fail_cnt = 0;
        repeat(4) @(posedge clk);
        rst_n = 1; @(posedge clk); #1;

        if (irq !== 1'b0) begin
            $display("FAIL [IRQ_RST] irq should be 0 after reset");
            fail_cnt++;
        end else begin
            $display("PASS [IRQ_RST] irq=0 after reset");
            pass_cnt++;
        end

        write_reg(4'h0, 32'd5);
        write_reg(4'h8, 32'h1);

        repeat(10) @(posedge clk);

        begin
            logic [31:0] stat;
            read_reg(4'hC, stat);
            if (stat[0] !== 1'b1) begin
                $display("FAIL [TIMEOUT] timeout flag not set after countdown");
                fail_cnt++;
            end else begin
                $display("PASS [TIMEOUT] timeout flag set");
                pass_cnt++;
            end
        end

        if (irq !== 1'b1) begin
            $display("FAIL [IRQ_HIGH] irq should be 1 on timeout");
            fail_cnt++;
        end else begin
            $display("PASS [IRQ_HIGH] irq=1 on timeout");
            pass_cnt++;
        end

        write_reg(4'hC, 32'h1);
        begin
            logic [31:0] stat;
            read_reg(4'hC, stat);
            if (stat[0] !== 1'b0) begin
                $display("FAIL [W1C] timeout flag not cleared by W1C");
                fail_cnt++;
            end else begin
                $display("PASS [W1C] timeout flag cleared");
                pass_cnt++;
            end
        end

        write_reg(4'h0, 32'd3);
        write_reg(4'h8, 32'h3);
        repeat(20) @(posedge clk);
        begin
            logic [31:0] stat, val;
            read_reg(4'hC, stat);
            read_reg(4'h4, val);
            if (stat[0] !== 1'b1) begin
                $display("FAIL [AUTORELOAD_IRQ] timeout not set with auto-reload");
                fail_cnt++;
            end else begin
                $display("PASS [AUTORELOAD_IRQ] auto-reload timeout set, counter=%0d", val);
                pass_cnt++;
            end
        end

        $display("--- TIMER: %0d passed, %0d failed ---", pass_cnt, fail_cnt);
        if (fail_cnt == 0) $display("ALL TIMER TESTS PASSED");
        $finish;
    end
endmodule
