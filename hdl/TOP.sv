`timescale 1ns / 1ps

module TOP(
    input logic clk, reset,
    output logic [31:0] WriteData, DataAdr,
    output logic MemWrite
    );
    
 logic [31:0] Instr_s,ReadData_s, DataAdr_s,WriteData_s;
 logic MemWrite_s;
 logic [31:0] PC_out_s;
 
 riscVpipeline rv_pipeline(.clk(clk),.reset(reset),.Instr(Instr_s),.MemWrite(MemWrite_s), .DataAdr(DataAdr_s), .WriteData(WriteData_s), .PC_out(PC_out_s), .ReadData(ReadData_s));
 
 dmem dmem(.clk(clk), .we(MemWrite_s), .a(DataAdr_s), .wd(WriteData_s), .rd(ReadData_s));
 
 imem imem(.a(PC_out_s), .rd(Instr_s));
  
 assign WriteData = WriteData_s;
 assign DataAdr = DataAdr_s;
 assign MemWrite = MemWrite_s;
endmodule
