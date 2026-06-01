module timer (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    input  wire        we,
    output wire        irq
);
    reg [31:0] load_val;
    reg [31:0] counter;
    reg        enable;
    reg        auto_reload;
    reg        timeout;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            load_val    <= 32'h0;
            counter     <= 32'h0;
            enable      <= 1'b0;
            auto_reload <= 1'b0;
            timeout     <= 1'b0;
        end else begin
            if (we) begin
                case (addr)
                    4'h0: begin load_val <= wdata; counter <= wdata; end
                    4'h8: begin enable <= wdata[0]; auto_reload <= wdata[1]; end
                    4'hC: if (wdata[0]) timeout <= 1'b0;
                    default: begin end
                endcase
            end
            if (enable) begin
                if (counter == 32'h0) begin
                    timeout <= 1'b1;
                    if (auto_reload) counter <= load_val;
                    else             enable  <= 1'b0;
                end else begin
                    counter <= counter - 1;
                end
            end
        end
    end

    always @(*) begin
        case (addr)
            4'h0:    rdata = load_val;
            4'h4:    rdata = counter;
            4'h8:    rdata = {30'h0, auto_reload, enable};
            4'hC:    rdata = {31'h0, timeout};
            default: rdata = 32'h0;
        endcase
    end

    assign irq = timeout;
endmodule
