module cpu_top (
    input  wire        clk,
    input  wire        rst_n,
    output wire [31:0] imem_addr,
    input  wire [31:0] imem_data,
    output wire [31:0] dbus_addr,
    output wire [31:0] dbus_wdata,
    output wire [3:0]  dbus_we,
    output wire        dbus_re,
    input  wire [31:0] dbus_rdata
);
    wire [31:0] pc, pc_next, pc_plus4;

    pc u_pc (
        .clk(clk), .rst_n(rst_n),
        .pc_next(pc_next), .pc_out(pc)
    );

    assign imem_addr = pc;
    assign pc_plus4  = pc + 32'd4;

    wire [31:0] instr   = imem_data;
    wire [6:0]  opcode  = instr[6:0];
    wire [4:0]  rd_addr = instr[11:7];
    wire [2:0]  funct3  = instr[14:12];
    wire [4:0]  rs1_a   = instr[19:15];
    wire [4:0]  rs2_a   = instr[24:20];
    wire [6:0]  funct7  = instr[31:25];

    wire reg_write, alu_src, mem_read, mem_write;
    wire mem_to_reg, branch, jal, jalr, lui, auipc;
    wire [1:0] alu_op;

    control u_ctrl (
        .opcode(opcode),
        .reg_write(reg_write), .alu_src(alu_src),
        .mem_read(mem_read),   .mem_write(mem_write),
        .mem_to_reg(mem_to_reg), .branch(branch),
        .jal(jal), .jalr(jalr), .lui(lui), .auipc(auipc),
        .alu_op(alu_op)
    );

    wire [31:0] rs1_data, rs2_data, rd_wdata;

    regfile u_rf (
        .clk(clk), .rst_n(rst_n), .we(reg_write),
        .rs1(rs1_a), .rs2(rs2_a), .rd(rd_addr),
        .wdata(rd_wdata),
        .rs1_data(rs1_data), .rs2_data(rs2_data)
    );

    wire [31:0] imm;
    immgen u_imm (.instr(instr), .imm_out(imm));

    wire [3:0]  alu_sel;
    wire [31:0] alu_result;
    wire        zero_flag;
    wire [31:0] alu_b = alu_src ? imm : rs2_data;

    alu_ctrl u_ac (
        .alu_op(alu_op), .funct3(funct3), .funct7(funct7),
        .alu_sel(alu_sel)
    );

    alu u_alu (
        .a(rs1_data), .b(alu_b),
        .alu_sel(alu_sel), .result(alu_result), .zero(zero_flag)
    );

    reg branch_taken;
    always @(*) begin
        case (funct3)
            3'b000: branch_taken = branch & zero_flag;
            3'b001: branch_taken = branch & ~zero_flag;
            3'b100: branch_taken = branch & ($signed(rs1_data) <  $signed(rs2_data));
            3'b101: branch_taken = branch & ($signed(rs1_data) >= $signed(rs2_data));
            3'b110: branch_taken = branch & (rs1_data <  rs2_data);
            3'b111: branch_taken = branch & (rs1_data >= rs2_data);
            default: branch_taken = 1'b0;
        endcase
    end

    wire [31:0] pc_branch = pc + imm;
    wire [31:0] pc_jal    = pc + imm;
    wire [31:0] pc_jalr   = (rs1_data + imm) & ~32'h1;

    assign pc_next = jalr         ? pc_jalr  :
                     jal          ? pc_jal   :
                     branch_taken ? pc_branch :
                                    pc_plus4;

    assign dbus_addr  = alu_result;
    assign dbus_wdata = rs2_data;
    assign dbus_re    = mem_read;

    assign dbus_we = mem_write ? (
        (funct3 == 3'b000) ? (4'b0001 << alu_result[1:0]) :
        (funct3 == 3'b001) ? (4'b0011 << alu_result[1:0]) :
                              4'b1111
    ) : 4'b0000;

    reg [31:0] load_data;
    always @(*) begin
        case (funct3)
            3'b000: load_data = {{24{dbus_rdata[7]}},  dbus_rdata[7:0]};
            3'b001: load_data = {{16{dbus_rdata[15]}}, dbus_rdata[15:0]};
            3'b010: load_data = dbus_rdata;
            3'b100: load_data = {24'h0, dbus_rdata[7:0]};
            3'b101: load_data = {16'h0, dbus_rdata[15:0]};
            default: load_data = dbus_rdata;
        endcase
    end

    assign rd_wdata = lui        ? imm         :
                      auipc      ? (pc + imm)  :
                      (jal|jalr) ? pc_plus4    :
                      mem_to_reg ? load_data   :
                                   alu_result;
endmodule
