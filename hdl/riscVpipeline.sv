`timescale 1ns / 1ps

module riscVpipeline(
    input logic clk, reset,
    input logic [31:0] Instr,
    input logic [31:0] ReadData,

    input  logic [31:0] data_from_mem_in,
    input  logic valid_mem_in,

    output logic [31:0] data_to_mem_out,
    output logic [31:0] address_to_mem_out,
    output logic we_dmem_out,
    output logic [1:0] cache_hit_out,
    output logic stall_out,

    output logic MemWrite,
    output logic [31:0] DataAdr,
    output logic [31:0]WriteData,
    output logic [31:0]PC_out


    );
    //Control signals
    logic RegWrite_s, MemWrite_s, Jump_s, Branch_s, ALUSrcB_s;
    logic [1:0] ResultSrc_s; 
    logic [2:0] ImmSrc_s;
    logic [2:0] ALUControl_s; 
    
    //Memory signals
    logic [31:0] PC_out_s, ALURes_s, WriteData_s;
    
    //hazaard signals
    logic [11:7] rdest_W_s;
    logic [11:7] rdest_M_s;
    logic PCSrc_E_s;
    logic[19:15] rs1_E_s;
    logic[24:20] rs2_E_s;
    logic[11:7] rdest_E_s;
    logic[19:15] rs1_D_s;
    logic[24:20] rs2_D_s;
    logic[1:0] ForwardA_E_s, ForwardB_E_s;
    logic Flush_E_s, Flush_D_s,Stall_D_s,Stall_F_s, load_operation_s;

    logic stall_out_s;
    
controller controller_module(
            .clk(clk),
            .reset(reset),
            .op(Instr[6:0]), 
            .funct3(Instr[14:12]), 
            .funct7b5(Instr[30]), 
            .RegWrite(RegWrite_s), 
            .ResultSrc(ResultSrc_s), 
            .MemWrite(MemWrite_s), 
            .Jump(Jump_s), 
            .Branch(Branch_s), 
            .ALUControl(ALUControl_s), 
            .ALUSrcB(ALUSrcB_s), 
            .ImmSrc(ImmSrc_s),
            //hazard input signals
            .rdest_W(rdest_W_s),
            .rdest_M(rdest_M_s),
            .PCSrc_E(PCSrc_E_s),
            .rs1_E(rs1_E_s),
            .rs2_E(rs2_E_s),
            .rdest_E(rdest_E_s),
            .rs1_D(rs1_D_s),
            .rs2_D(rs2_D_s),
            //hazard input contorl signals
            .ForwardA_E(ForwardA_E_s),
            .ForwardB_E(ForwardB_E_s),
            .Flush_E(Flush_E_s),
            .Flush_D(Flush_D_s),
            .Stall_D(Stall_D_s),
            .Stall_F(Stall_F_s),
            .load_operation(load_operation_s),
            .stall(stall_out_s)
            );

datapath datapath_module(
            .clk(clk), 
            .reset(reset), 
            //to memory 
            .PC_out(PC_out_s), 
            .Instr(Instr), 
            .ALUResult(ALURes_s), 
            .WriteData(WriteData_s), 
            .ReadData(ReadData),
            //from datapath 
            .RegWrite(RegWrite_s),
            .ResultSrc(ResultSrc_s), 
            .Jump(Jump_s), 
            .Branch(Branch_s), 
            .ALUControl(ALUControl_s), 
            .ALUSrcB(ALUSrcB_s), 
            .ImmSrc(ImmSrc_s),
            //hazard output signals
            .rdest_W_out(rdest_W_s),
            .rdest_M_out(rdest_M_s),
            .PCSrc_E_out(PCSrc_E_s),
            .rs1_E_out(rs1_E_s),
            .rs2_E_out(rs2_E_s),
            .rdest_E_out(rdest_E_s),
            .rs1_D_out(rs1_D_s),
            .rs2_D_out(rs2_D_s),
            //hazard input contorl signals
            .ForwardA_E(ForwardA_E_s),
            .ForwardB_E(ForwardB_E_s),
            .Flush_E(Flush_E_s),
            .Flush_D(Flush_D_s),
            .Stall_D(Stall_D_s),
            .Stall_F(Stall_F_s),
            .cache_write(MemWrite_s),
            .load_operation(load_operation_s),

            .data_from_mem_in(data_from_mem_in),
            .valid_mem_in(valid_mem_in),
            .data_to_mem_out(data_to_mem_out),
            .address_to_mem_out(address_to_mem_out),
            .we_dmem_out(we_dmem_out),
            .cache_hit_out(cache_hit_out),
            .stall_out(stall_out_s)
            );
            
assign MemWrite = MemWrite_s;
assign DataAdr = ALURes_s;
assign WriteData = WriteData_s;
assign PC_out = PC_out_s;
assign stall_out = stall_out_s;
endmodule
