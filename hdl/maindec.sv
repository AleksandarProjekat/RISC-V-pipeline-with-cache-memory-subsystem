`timescale 1ns / 1ps

module maindec(
    input logic [6:0] op,
    output logic [1:0] ResultSrc,
    output logic MemWrite,
    output logic Branch,
    output logic RegWrite, Jump,
    output logic [1:0] ALUOp,
    output logic ALUSrcB,
    output logic [2:0] ImmSrc   // promenjeno na 3 bita
    );
    
    logic [11:0] controls;
    
    assign {RegWrite, ImmSrc, ALUSrcB, MemWrite, ResultSrc, Branch, ALUOp, Jump} = controls;
    
    always_comb
        case(op)
        //RegWrite_ImmSrc_ALUSrcB_MemWrite_ResultSrc_Branch_ALUOp_Jump
            7'b0000011: controls = 12'b1_000_1_0_01_0_00_0; // lw
            7'b0100011: controls = 12'b0_001_1_1_00_0_00_0; // sw
            7'b0110011: controls = 12'b1_000_0_0_00_0_10_0; // R-type
            7'b1100011: controls = 12'b0_010_0_0_00_1_01_0; // beq
            7'b0010011: controls = 12'b1_000_1_0_00_0_10_0; // I-type
            7'b1101111: controls = 12'b1_100_0_0_10_0_00_1; // jal
            7'b0110111: controls = 12'b1_011_1_0_11_0_00_0; // lui
            default:    controls = 12'b0_000_0_0_00_0_00_0;
        endcase
endmodule