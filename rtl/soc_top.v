module soc_top (
    input  wire       clk,
    input  wire       rst_n,
    // UART
    output wire       uart_tx,
    input  wire       uart_rx,
    // GPIO
    output wire [7:0] gpio_out,
    input  wire [7:0] gpio_in,
    // SPI
    output wire       spi_sck,
    output wire       spi_mosi,
    input  wire       spi_miso,
    output wire       spi_cs_n,
    // I2C
    output wire       i2c_scl_oe,
    output wire       i2c_sda_oe,
    input  wire       i2c_sda_in,
    // 7-Segment Display 0 (right 4 digits)
    output wire [3:0]  D0_AN,
    output wire [7:0]  D0_SEG,
    // 7-Segment Display 1 (left 4 digits)
    output wire [3:0]  D1_AN,
    output wire [7:0]  D1_SEG
);

    // Power-on reset — holds reset for 256 cycles
    reg [7:0] por_cnt = 8'h0;
    wire rst_n_int = por_cnt[7] & rst_n;
    always @(posedge clk)
        if (!por_cnt[7]) por_cnt <= por_cnt + 1;
    wire [31:0] imem_addr, imem_data;
    wire [31:0] dbus_addr, dbus_wdata, dbus_rdata;
    wire [3:0]  dbus_we;
    wire        dbus_re;

    cpu_top u_cpu (
        .clk(clk), .rst_n(rst_n),
        .imem_addr(imem_addr), .imem_data(imem_data),
        .dbus_addr(dbus_addr), .dbus_wdata(dbus_wdata),
        .dbus_we(dbus_we),     .dbus_re(dbus_re),
        .dbus_rdata(dbus_rdata)
    );

    imem u_imem (.addr(imem_addr), .data(imem_data));

    // ── Address Map ──────────────────────────────────────
    // 0x00002000 - 0x00003FFF  DMEM
    // 0x10000000 - 0x1000000F  UART
    // 0x20000000 - 0x2000000F  GPIO
    // 0x30000000 - 0x3000000F  TIMER
    // 0x40000000 - 0x4000000F  INTC
    // 0x50000000 - 0x5000000F  SPI
    // 0x60000000 - 0x6000000F  I2C

    wire dmem_sel  = (dbus_addr[31:14] == 18'h0) && (dbus_addr[13] == 1'b1);
    wire uart_sel  = (dbus_addr[31:4]  == 28'h1000000);
    wire gpio_sel  = (dbus_addr[31:4]  == 28'h2000000);
    wire timer_sel = (dbus_addr[31:4]  == 28'h3000000);
    wire intc_sel  = (dbus_addr[31:4]  == 28'h4000000);
    wire spi_sel   = (dbus_addr[31:4]  == 28'h5000000);
    wire i2c_sel   = (dbus_addr[31:4]  == 28'h6000000);

    // ── DMEM ─────────────────────────────────────────────
    wire [31:0] dmem_rdata;
    dmem u_dmem (
        .clk(clk), .addr(dbus_addr), .wdata(dbus_wdata),
        .we(dmem_sel ? dbus_we : 4'b0),
        .re(dmem_sel & dbus_re),
        .rdata(dmem_rdata)
    );

    // ── UART ─────────────────────────────────────────────
    wire [31:0] uart_rdata;
    wire        irq_uart;
    uart u_uart (
        .clk(clk), .rst_n(rst_n),
        .addr(dbus_addr[3:0]), .wdata(dbus_wdata),
        .rdata(uart_rdata),
        .we(uart_sel & (|dbus_we)),
        .tx(uart_tx), .rx(uart_rx), .irq(irq_uart)
    );

    // ── GPIO ─────────────────────────────────────────────
    wire [31:0] gpio_rdata;
    wire [7:0]  gpio_out_w;
    gpio u_gpio (
        .clk(clk), .rst_n(rst_n),
        .addr(dbus_addr[3:0]), .wdata(dbus_wdata),
        .rdata(gpio_rdata),
        .we(gpio_sel & (|dbus_we)),
        .gpio_out(gpio_out_w), .gpio_in(gpio_in)
    );
    assign gpio_out = gpio_out_w;

    // ── TIMER ────────────────────────────────────────────
    wire [31:0] timer_rdata;
    wire        irq_timer;
    timer u_timer (
        .clk(clk), .rst_n(rst_n),
        .addr(dbus_addr[3:0]), .wdata(dbus_wdata),
        .rdata(timer_rdata),
        .we(timer_sel & (|dbus_we)),
        .irq(irq_timer)
    );

    // ── INTC ─────────────────────────────────────────────
    wire [31:0] intc_rdata;
    wire        irq_to_cpu;
    wire        irq_spi, irq_i2c;
    intc u_intc (
        .clk(clk), .rst_n(rst_n),
        .addr(dbus_addr[3:0]), .wdata(dbus_wdata),
        .rdata(intc_rdata),
        .we(intc_sel & (|dbus_we)),
        .irq_uart(irq_uart), .irq_timer(irq_timer),
        .irq_spi(irq_spi),   .irq_i2c(irq_i2c),
        .irq_to_cpu(irq_to_cpu)
    );

    // ── SPI ──────────────────────────────────────────────
    wire [31:0] spi_rdata;
    spi u_spi (
        .clk(clk), .rst_n(rst_n),
        .addr(dbus_addr[3:0]), .wdata(dbus_wdata),
        .rdata(spi_rdata),
        .we(spi_sel & (|dbus_we)),
        .sck(spi_sck), .mosi(spi_mosi),
        .miso(spi_miso), .cs_n(spi_cs_n),
        .irq(irq_spi)
    );

    // ── I2C ──────────────────────────────────────────────
    wire [31:0] i2c_rdata;
    i2c u_i2c (
        .clk(clk), .rst_n(rst_n),
        .addr(dbus_addr[3:0]), .wdata(dbus_wdata),
        .rdata(i2c_rdata),
        .we(i2c_sel & (|dbus_we)),
        .scl_oe(i2c_scl_oe), .sda_oe(i2c_sda_oe),
        .sda_in(i2c_sda_in), .irq(irq_i2c)
    );

    // ── Bus read mux ─────────────────────────────────────
    assign dbus_rdata = dmem_sel  ? dmem_rdata  :
                        uart_sel  ? uart_rdata  :
                        gpio_sel  ? gpio_rdata  :
                        timer_sel ? timer_rdata :
                        intc_sel  ? intc_rdata  :
                        spi_sel   ? spi_rdata   :
                        i2c_sel   ? i2c_rdata   :
                                    32'h0;
    // =========================================================
    // 7-Segment — memory-mapped at 0x20000100
    // Follows same pattern as gpio/uart/timer sel decodes above
    // =========================================================
    wire        seg7_sel = (dbus_addr == 32'h20000100);
    reg  [31:0] seg7_reg;
    always @(posedge clk or negedge rst_n_int)
        if (!rst_n_int) seg7_reg <= 32'h0;
        else if (seg7_sel && (|dbus_we)) seg7_reg <= dbus_wdata;

    seg7_ctrl u_seg7 (
        .clk         (clk),
        .rst_n       (rst_n_int),
        .display_val (seg7_reg),
        .D0_AN       (D0_AN),
        .D0_SEG      (D0_SEG),
        .D1_AN       (D1_AN),
        .D1_SEG      (D1_SEG)
    );

endmodule
