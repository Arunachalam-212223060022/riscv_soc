module imem (
    input  wire [31:0] addr,
    output wire [31:0] data
);
    reg [31:0] mem [0:2047];
    initial begin
        $readmemh("program.mem", mem);
    end
    assign data = mem[addr[12:2]];
endmodule
