module soc_top (
    input  wire        clk,
    input  wire        rst_n,
    output wire        uart_tx,
    input  wire        uart_rx,
    output wire [7:0]  gpio_out,
    input  wire [7:0]  gpio_in,
    output wire        spi_sck,
    output wire        spi_mosi,
    input  wire        spi_miso,
    output wire        spi_cs_n,
    output wire        i2c_scl_oe,
    output wire        i2c_sda_oe,
    input  wire        i2c_sda_in,
    output wire [3:0]  D0_AN,
    output wire [7:0]  D0_SEG,
    output wire [3:0]  D1_AN,
    output wire [7:0]  D1_SEG
);
    reg [7:0] por_cnt;
    reg       rst_n_int;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            por_cnt  <= 8'h0;
            rst_n_int <= 1'b0;
        end else begin
            if (!por_cnt[7]) por_cnt <= por_cnt + 1;
            rst_n_int <= por_cnt[7] & rst_n;
        end
    end

    wire [31:0] imem_addr, imem_data;
    wire [31:0] dbus_addr, dbus_wdata, dbus_rdata;
    wire [3:0]  dbus_we;
    wire        dbus_re;

    cpu_top u_cpu (
        .clk(clk),          .rst_n(rst_n_int),
        .imem_addr(imem_addr), .imem_data(imem_data),
        .dbus_addr(dbus_addr), .dbus_wdata(dbus_wdata),
        .dbus_we(dbus_we),     .dbus_re(dbus_re),
        .dbus_rdata(dbus_rdata)
    );

    imem u_imem (
        .addr(imem_addr),
        .data(imem_data)
    );

    wire dmem_sel  = (dbus_addr[31:14] == 18'h0) && (dbus_addr[13] == 1'b1);
    wire uart_sel  = (dbus_addr[31:4]  == 28'h1000000);
    wire gpio_sel  = (dbus_addr[31:4]  == 28'h2000000);
    wire timer_sel = (dbus_addr[31:4]  == 28'h3000000);
    wire intc_sel  = (dbus_addr[31:4]  == 28'h4000000);
    wire spi_sel   = (dbus_addr[31:4]  == 28'h5000000);
    wire i2c_sel   = (dbus_addr[31:5]  == 27'h3000000);
    wire seg7_sel  = (dbus_addr        == 32'h20000100);

    wire [31:0] dmem_rdata;
    dmem u_dmem (
        .clk(clk),             .rst_n(rst_n_int),
        .addr(dbus_addr),      .wdata(dbus_wdata),
        .we(dmem_sel ? dbus_we : 4'b0),
        .re(dmem_sel & dbus_re),
        .rdata(dmem_rdata)
    );

    wire [31:0] uart_rdata;
    wire        irq_uart;
    uart u_uart (
        .clk(clk),             .rst_n(rst_n_int),
        .addr(dbus_addr[3:0]), .wdata(dbus_wdata),
        .rdata(uart_rdata),
        .we(uart_sel & (|dbus_we)),
        .tx(uart_tx),          .rx(uart_rx),
        .irq(irq_uart)
    );

    wire [31:0] gpio_rdata;
    gpio u_gpio (
        .clk(clk),             .rst_n(rst_n_int),
        .addr(dbus_addr[3:0]), .wdata(dbus_wdata),
        .rdata(gpio_rdata),
        .we(gpio_sel & (|dbus_we)),
        .gpio_out(gpio_out),   .gpio_in(gpio_in)
    );

    wire [31:0] timer_rdata;
    wire        irq_timer;
    timer u_timer (
        .clk(clk),             .rst_n(rst_n_int),
        .addr(dbus_addr[3:0]), .wdata(dbus_wdata),
        .rdata(timer_rdata),
        .we(timer_sel & (|dbus_we)),
        .irq(irq_timer)
    );

    wire [31:0] spi_rdata;
    wire        irq_spi;
    spi u_spi (
        .clk(clk),             .rst_n(rst_n_int),
        .addr(dbus_addr[3:0]), .wdata(dbus_wdata),
        .rdata(spi_rdata),
        .we(spi_sel & (|dbus_we)),
        .sck(spi_sck),         .mosi(spi_mosi),
        .miso(spi_miso),       .cs_n(spi_cs_n),
        .irq(irq_spi)
    );

    wire [31:0] i2c_rdata;
    wire        irq_i2c;
    i2c u_i2c (
        .clk(clk),             .rst_n(rst_n_int),
        .addr(dbus_addr[4:0]), .wdata(dbus_wdata),
        .rdata(i2c_rdata),
        .we(i2c_sel & (|dbus_we)),
        .scl_oe(i2c_scl_oe),   .sda_oe(i2c_sda_oe),
        .sda_in(i2c_sda_in),   .irq(irq_i2c)
    );

    wire [31:0] intc_rdata;
    wire        irq_to_cpu;
    intc u_intc (
        .clk(clk),             .rst_n(rst_n_int),
        .addr(dbus_addr[3:0]), .wdata(dbus_wdata),
        .rdata(intc_rdata),
        .we(intc_sel & (|dbus_we)),
        .irq_uart(irq_uart),   .irq_timer(irq_timer),
        .irq_spi(irq_spi),     .irq_i2c(irq_i2c),
        .irq_to_cpu(irq_to_cpu)
    );

    reg [31:0] seg7_reg;
    always @(posedge clk or negedge rst_n_int) begin
        if (!rst_n_int) seg7_reg <= 32'h0;
        else if (seg7_sel && (|dbus_we)) seg7_reg <= dbus_wdata;
    end

    wire [31:0] seg7_rdata = seg7_reg;

    seg7_ctrl u_seg7 (
        .clk(clk),           .rst_n(rst_n_int),
        .display_val(seg7_reg),
        .D0_AN(D0_AN),       .D0_SEG(D0_SEG),
        .D1_AN(D1_AN),       .D1_SEG(D1_SEG)
    );

    assign dbus_rdata = dmem_sel  ? dmem_rdata  :
                        uart_sel  ? uart_rdata  :
                        gpio_sel  ? gpio_rdata  :
                        timer_sel ? timer_rdata :
                        intc_sel  ? intc_rdata  :
                        spi_sel   ? spi_rdata   :
                        i2c_sel   ? i2c_rdata   :
                        seg7_sel  ? seg7_rdata  :
                                    32'h0;
endmodule
