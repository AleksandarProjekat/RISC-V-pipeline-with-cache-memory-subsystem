`timescale 1ns / 1ps

module TOP(
    input logic clk, reset,
    output logic [31:0] WriteData, DataAdr,
    output logic MemWrite
    );
    
logic [31:0] Instr_s,ReadData_s, DataAdr_s,WriteData_s;
logic MemWrite_s;
logic [31:0] PC_out_s;

logic [31:0] data_from_mem_in_s;
logic valid_mem_in_s;
logic [31:0] data_to_mem_out_s;
logic [31:0] address_to_mem_out_s;
logic we_dmem_out_s;
logic [1:0] cache_hit_out_s;
logic stall_out_s;
 
 riscVpipeline rv_pipeline(
    .clk(clk),
    .reset(reset),
    .Instr(Instr_s),
    .MemWrite(MemWrite_s), 
    .DataAdr(DataAdr_s), 
    .WriteData(WriteData_s), 
    .PC_out(PC_out_s), 
    .ReadData(ReadData_s),
    
    .data_from_mem_in(data_from_mem_in_s),
    .valid_mem_in(valid_mem_in_s),
    .data_to_mem_out(data_to_mem_out_s),
    .address_to_mem_out(address_to_mem_out_s),
    .we_dmem_out(we_dmem_out_s),
    .cache_hit_out(cache_hit_out_s),
    .stall_out(stall_out_s)
    );
 
dmem dmem(
    .clk(clk), 
    .we(we_dmem_out_s), 
    .rst(reset),
    .a(address_to_mem_out_s), 
    .wd(data_to_mem_out_s), 
    .rd(data_from_mem_in_s),
    .load_operation((cache_hit_out_s == 2'b01)),
    .valid_mem_data(valid_mem_in_s)
);
 
 imem imem(.a(PC_out_s), .rd(Instr_s));
  
 assign WriteData = WriteData_s;
 assign DataAdr = DataAdr_s;
 assign MemWrite = MemWrite_s;
endmodule
