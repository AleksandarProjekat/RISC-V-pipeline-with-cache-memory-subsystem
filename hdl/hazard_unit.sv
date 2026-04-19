`timescale 1ns / 1ps

module hazard_unit(
    input logic RegWrite_W,
    input logic [11:7] rdest_W,
    input logic RegWrite_M,
    input logic [11:7] rdest_M,
    input logic [1:0] ResultSrc_E,
    input logic PCSrc_E,
    input logic[19:15] rs1_E,
    input logic[24:20] rs2_E,
    input logic[11:7] rdest_E,
    input logic[19:15] rs1_D,
    input logic[24:20] rs2_D,
    
    output logic [1:0] ForwardB_E,
    output logic [1:0] ForwardA_E,
    output logic Flush_E,
    output logic Flush_D,
    output logic Stall_D,
    output logic Stall_F
    
    );
    
logic lwStall;
assign lwStall = ResultSrc_E[0] && ((rs1_D == rdest_E) || (rs2_D == rdest_E)); // ako je u EXE stage (lw instrukcija) destinacioni registar jednak nekom od
//ulaznih registara naredne instrukcije, potrebno je zamrznuti FETCH i DECODE registre, a EXE treba izbrisati(ne validni podaci za source operande)

//Forwarding is implemented for Mem and WB stage
assign ForwardA_E = ((rs1_E == rdest_M) && (RegWrite_M == 1'b1) && (rs1_E != 1'b0)) ? 2'b10 :
                   ((rs1_E == rdest_W) && (RegWrite_W == 1'b1) && (rs1_E != 1'b0)) ? 2'b01 :
                   2'b00; 
assign ForwardB_E = ((rs2_E == rdest_M) && (RegWrite_M == 1'b1) && (rs2_E != 1'b0)) ? 2'b10 :
                   ((rs2_E == rdest_W) && (RegWrite_W == 1'b1) && (rs2_E != 1'b0)) ? 2'b01 :
                   2'b00;
                   
assign Stall_F = lwStall;
assign Stall_D = lwStall;
assign Flush_E = lwStall | PCSrc_E;
assign Flush_D = PCSrc_E;

endmodule
