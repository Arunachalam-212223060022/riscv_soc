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
    reg [31:0] ctrl;
    reg        timeout;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            load_val <= 32'h0;
            counter  <= 32'h0;
            ctrl     <= 32'h0;
            timeout  <= 1'b0;
        end else begin
            if (we) begin
                case (addr)
                    4'h0: begin load_val <= wdata; counter <= wdata; end
                    4'h8: ctrl <= wdata;
                    4'hC: if (wdata[0]) timeout <= 1'b0;
                    default: begin end
                endcase
            end
            if (ctrl[0]) begin
                if (counter == 32'h0) begin
                    timeout <= 1'b1;
                    if (ctrl[1]) counter <= load_val;
                    else         ctrl[0] <= 1'b0;
                end else begin
                    counter <= counter - 1;
                end
            end
        end
    end

    always @(*) begin
        case (addr)
            4'h0: rdata = load_val;
            4'h4: rdata = counter;
            4'h8: rdata = ctrl;
            4'hC: rdata = {31'h0, timeout};
            default: rdata = 32'h0;
        endcase
    end

    assign irq = timeout;
endmodule
