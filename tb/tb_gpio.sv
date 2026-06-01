`timescale 1ns/1ps
module tb_gpio;
    logic        clk, rst_n, we;
    logic [3:0]  addr;
    logic [31:0] wdata, rdata;
    logic [7:0]  gpio_out, gpio_in;
    int          pass_cnt, fail_cnt;

    gpio dut (.clk(clk), .rst_n(rst_n), .addr(addr), .wdata(wdata),
              .rdata(rdata), .we(we), .gpio_out(gpio_out), .gpio_in(gpio_in));

    always #5 clk = ~clk;

    task automatic write_reg(input [3:0] a, input [31:0] d);
        addr = a; wdata = d; we = 1; @(posedge clk); #1; we = 0;
    endtask

    initial begin
        clk = 0; rst_n = 0; we = 0; addr = 0; wdata = 0; gpio_in = 8'h00;
        pass_cnt = 0; fail_cnt = 0;
        repeat(4) @(posedge clk);
        rst_n = 1; @(posedge clk); #1;

        if (gpio_out !== 8'h00) begin
            $display("FAIL [RST] gpio_out should be 0 after reset");
            fail_cnt++;
        end else begin
            $display("PASS [RST] gpio_out=0 after reset");
            pass_cnt++;
        end

        write_reg(4'h0, 32'hAA);
        if (gpio_out !== 8'hAA) begin
            $display("FAIL [OUT_AA] gpio_out=%0h expected AA", gpio_out);
            fail_cnt++;
        end else begin
            $display("PASS [OUT_AA] gpio_out=AA");
            pass_cnt++;
        end

        write_reg(4'h0, 32'hFF);
        if (gpio_out !== 8'hFF) begin
            $display("FAIL [OUT_FF] gpio_out=%0h expected FF", gpio_out);
            fail_cnt++;
        end else begin
            $display("PASS [OUT_FF] gpio_out=FF");
            pass_cnt++;
        end

        gpio_in = 8'hB7;
        addr = 4'h4; #1;
        if (rdata[7:0] !== 8'hB7) begin
            $display("FAIL [IN_READ] gpio_in readback %0h expected B7", rdata[7:0]);
            fail_cnt++;
        end else begin
            $display("PASS [IN_READ] gpio_in=B7");
            pass_cnt++;
        end

        addr = 4'h0; #1;
        if (rdata[7:0] !== 8'hFF) begin
            $display("FAIL [OUT_READ] gpio_out readback %0h expected FF", rdata[7:0]);
            fail_cnt++;
        end else begin
            $display("PASS [OUT_READ] gpio_out readback=FF");
            pass_cnt++;
        end

        $display("--- GPIO: %0d passed, %0d failed ---", pass_cnt, fail_cnt);
        if (fail_cnt == 0) $display("ALL GPIO TESTS PASSED");
        $finish;
    end
endmodule
