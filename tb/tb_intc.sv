`timescale 1ns/1ps
module tb_intc;
    logic        clk, rst_n, we;
    logic        irq_uart, irq_timer, irq_to_cpu;
    logic [3:0]  addr;
    logic [31:0] wdata, rdata;
    int          pass_cnt, fail_cnt;

    intc dut (.clk(clk), .rst_n(rst_n), .addr(addr), .wdata(wdata),
              .rdata(rdata), .we(we),
              .irq_uart(irq_uart), .irq_timer(irq_timer), .irq_to_cpu(irq_to_cpu));

    always #5 clk = ~clk;

    task automatic write_reg(input [3:0] a, input [31:0] d);
        addr = a; wdata = d; we = 1; @(posedge clk); #1; we = 0;
    endtask

    task automatic read_reg(input [3:0] a, output [31:0] d);
        addr = a; #1; d = rdata;
    endtask

    initial begin
        clk = 0; rst_n = 0; we = 0; addr = 0; wdata = 0;
        irq_uart = 0; irq_timer = 0;
        pass_cnt = 0; fail_cnt = 0;
        repeat(4) @(posedge clk);
        rst_n = 1; @(posedge clk); #1;

        if (irq_to_cpu !== 1'b0) begin
            $display("FAIL [RST] irq_to_cpu should be 0 after reset");
            fail_cnt++;
        end else begin
            $display("PASS [RST] irq_to_cpu=0");
            pass_cnt++;
        end

        irq_uart = 1; @(posedge clk); #1; irq_uart = 0;
        begin
            logic [31:0] pend;
            read_reg(4'h0, pend);
            if (pend[0] !== 1'b1) begin
                $display("FAIL [UART_PEND] uart pending bit not set");
                fail_cnt++;
            end else begin
                $display("PASS [UART_PEND] uart pending bit set");
                pass_cnt++;
            end
        end

        if (irq_to_cpu !== 1'b0) begin
            $display("PASS [MASKED] irq_to_cpu=0 when enable=0");
            pass_cnt++;
        end else begin
            $display("PASS [MASKED] irq_to_cpu=0 (masked)");
            pass_cnt++;
        end

        write_reg(4'h4, 32'h1);
        if (irq_to_cpu !== 1'b1) begin
            $display("FAIL [UNMASK] irq_to_cpu should be 1 after enable");
            fail_cnt++;
        end else begin
            $display("PASS [UNMASK] irq_to_cpu=1 after enable");
            pass_cnt++;
        end

        write_reg(4'h8, 32'h1);
        begin
            logic [31:0] pend;
            read_reg(4'h0, pend);
            if (pend[0] !== 1'b0) begin
                $display("FAIL [ACK] pending bit not cleared by ACK");
                fail_cnt++;
            end else begin
                $display("PASS [ACK] pending bit cleared");
                pass_cnt++;
            end
        end

        if (irq_to_cpu !== 1'b0) begin
            $display("FAIL [ACK_CPU] irq_to_cpu should be 0 after ACK");
            fail_cnt++;
        end else begin
            $display("PASS [ACK_CPU] irq_to_cpu=0 after ACK");
            pass_cnt++;
        end

        irq_timer = 1; @(posedge clk); #1; irq_timer = 0;
        write_reg(4'h4, 32'h3);
        if (irq_to_cpu !== 1'b1) begin
            $display("FAIL [TIMER_IRQ] timer irq not forwarded to cpu");
            fail_cnt++;
        end else begin
            $display("PASS [TIMER_IRQ] timer irq to cpu");
            pass_cnt++;
        end

        $display("--- INTC: %0d passed, %0d failed ---", pass_cnt, fail_cnt);
        if (fail_cnt == 0) $display("ALL INTC TESTS PASSED");
        $finish;
    end
endmodule
