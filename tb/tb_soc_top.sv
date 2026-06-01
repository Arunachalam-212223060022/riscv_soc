`timescale 1ns/1ps
module tb_soc_top;
    logic        clk, rst_n;
    logic        uart_tx, uart_rx;
    logic [7:0]  gpio_out, gpio_in;
    logic        spi_sck, spi_mosi, spi_miso, spi_cs_n;
    logic        i2c_scl_oe, i2c_sda_oe, i2c_sda_in;
    int          pass_cnt, fail_cnt;

    soc_top dut (
        .clk(clk), .rst_n(rst_n),
        .uart_tx(uart_tx), .uart_rx(uart_rx),
        .gpio_out(gpio_out), .gpio_in(gpio_in),
        .spi_sck(spi_sck), .spi_mosi(spi_mosi),
        .spi_miso(spi_miso), .spi_cs_n(spi_cs_n),
        .i2c_scl_oe(i2c_scl_oe), .i2c_sda_oe(i2c_sda_oe),
        .i2c_sda_in(i2c_sda_in)
    );

    always #5 clk = ~clk;
    assign uart_rx  = uart_tx;   // UART loopback
    assign spi_miso = spi_mosi;  // SPI loopback
    assign i2c_sda_in = ~i2c_sda_oe; // I2C slave ACK

    task automatic check(input cond, input string name);
        if (!cond) begin $display("FAIL [%s]", name); fail_cnt++; end
        else       begin $display("PASS [%s]", name); pass_cnt++; end
    endtask

    integer i;
    initial begin
        clk=0; rst_n=0; gpio_in=8'hA5;
        pass_cnt=0; fail_cnt=0;

        for (i=0; i<2048; i++) dut.u_imem.mem[i] = 32'h0000_0013; // NOP

        // LUI  x10, 0x20000  → GPIO base 0x20000000
        dut.u_imem.mem[0] = 32'h20000537;
        // ADDI x11, x0, 0xA5
        dut.u_imem.mem[1] = 32'h0A500593;
        // SW   x11, 0(x10)   → GPIO_OUT = 0xA5
        dut.u_imem.mem[2] = 32'h00B52023;
        // LUI  x10, 0x30000  → TIMER base
        dut.u_imem.mem[3] = 32'h30000537;
        // ADDI x11, x0, 10
        dut.u_imem.mem[4] = 32'h00A00593;
        // SW   x11, 0(x10)   → TIMER_LOAD = 10
        dut.u_imem.mem[5] = 32'h00B52023;
        // ADDI x11, x0, 3
        dut.u_imem.mem[6] = 32'h00300593;
        // SW   x11, 8(x10)   → TIMER_CTRL = 3
        dut.u_imem.mem[7] = 32'h00B52423;
        // JAL  x0, 0         → infinite loop
        dut.u_imem.mem[8] = 32'h0000006F;

        repeat(4) @(posedge clk); rst_n=1;
        repeat(200) @(posedge clk);

        // ── Original tests ─────────────────────────────
        check(uart_tx===1'b1,          "UART_TX_IDLE");
        check(gpio_out===8'hA5,        "GPIO_OUT_0xA5");
        check(dut.u_gpio.gpio_in===8'hA5, "GPIO_IN_REFLECT");
        check(dut.u_timer.load_val===32'hA, "TIMER_LOAD_10");
        check(dut.u_timer.ctrl===32'h3,    "TIMER_CTRL_3");
        check(dut.u_uart.baud_div===32'd868,"UART_BAUD_868");

        // ── New peripheral tests ────────────────────────
        check(spi_cs_n===1'b1,         "SPI_CS_IDLE_HIGH");
        check(spi_sck===1'b0,          "SPI_SCK_IDLE_LOW");
        check(i2c_scl_oe===1'b0,       "I2C_SCL_RELEASED");
        check(i2c_sda_oe===1'b0,       "I2C_SDA_RELEASED");

        // ── INTC has 4 sources ──────────────────────────
        check(dut.u_intc.pending!==32'hx, "INTC_PENDING_VALID");

        $display("--- SOC_TOP: %0d passed, %0d failed ---", pass_cnt, fail_cnt);
        if (fail_cnt==0) $display("ALL SOC_TOP TESTS PASSED");
        $finish;
    end
    initial begin #2_000_000; $display("TIMEOUT"); $finish; end
endmodule
