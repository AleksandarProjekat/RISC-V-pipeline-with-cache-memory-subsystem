`timescale 1ns / 1ps

module datapath(
    input logic clk,reset,
    output logic [31:0] PC_out,
    input logic [31:0] Instr,
    output logic [31:0] ALUResult,
    output logic [31:0] WriteData,
    input logic [31:0] ReadData,
    input logic RegWrite,
    input logic [1:0] ResultSrc,
    input logic Jump,
    input logic Branch,
    input logic [2:0] ALUControl,
    input logic ALUSrcB, 
    input logic [1:0] ImmSrc,
    //input hazard control signals
    input logic [1:0] ForwardA_E,
    input logic [1:0] ForwardB_E,
    input logic Flush_E,
    input logic Flush_D,
    input logic Stall_D,
    input logic Stall_F,
    input logic cache_write,
    input logic load_operation,
    //outputs to hazard unit
    output logic [11:7] rdest_W_out,
    output logic [11:7] rdest_M_out,
    output logic PCSrc_E_out,
    output logic[19:15] rs1_E_out,
    output logic[24:20] rs2_E_out,
    output logic[11:7] rdest_E_out,
    output logic[19:15] rs1_D_out,
    output logic[24:20] rs2_D_out
    );


logic [31:0] PC_out_s, PC_in_s, PCPlus4_s;
logic [31:0] ImmExt_s;


//Fetch signals
logic PCSelect_s;

//Decode signals
logic [31:0] RD1_out_s, RD2_out_s;

//Execute signals
logic [31:0] SrcA_E_s, SrcB_E_s,ALUResult_E_s,PCTarget_E_s;
logic Zero_s;
logic [31:0] SrcB_E_forward_s;

//Memory signals

//WRITE-BACK signals
logic [31:0] ResultW_s;





//PIPELINE REG SIGNALS F/D
logic [31:0] Instr_D, PCPlus4_D, PC_D;
logic [19:15] rs1_D;
logic [24:20] rs2_D;
logic [11:7] rdest_D;
//PIPELINE REG SIGNALS D/E
logic [31:0] rd1_E, rd2_E, PC_E, rs1_E, rs2_E, rdest_E, ImmExt_E, PCPlus4_E;

//PIPELINE REG SIGNALS E/M
logic [31:0] ALUResult_M, WriteData_M, rdest_M, PCPlus4_M;

//PIPELINE REG SIGNALS M/W
logic [31:0] ReadData_W, rdest_W, PCPlus4_W,ALUResult_W;

logic [31:0] ReadData_s;


///////////////////////////////////////////////////////
//
// FETCH STAGE
//
///////////////////////////////////////////////////////

//instance of PC reg
always_ff @(posedge clk, posedge reset)
            if(reset) 
                PC_out_s<=0;
            else if (Stall_F)
                PC_out_s <= PC_out_s;
            else 
                PC_out_s<=PC_in_s;
//instance of MUX, pc select logic (just signal)
assign PC_in_s = PCSelect_s ?   PCTarget_E_s : PCPlus4_s;

assign PCSelect_s = (Zero_s && Branch) || Jump;

//instance of ADDER
adder adder_pc_next_0(.a(PC_out_s), .b(32'd4), .y(PCPlus4_s));

// FETCH/DECODE PIPELINE REGISTER
always_ff @(posedge clk)
            if(reset || Flush_D) //should go flush
            begin 
                Instr_D <= 'b0;
                PCPlus4_D <= 'b0;
                PC_D <= 'b0;
            end
            else if(Stall_D) begin
                Instr_D <= Instr_D;
                PCPlus4_D <= PCPlus4_D;
                PC_D <= PC_D;       
            
            end
            else begin
                Instr_D <= Instr;
                PCPlus4_D <= PCPlus4_s;
                PC_D <= PC_out_s;
            end

///////////////////////////////////////////////////////
//
// DECODE STAGE
//
///////////////////////////////////////////////////////
assign rs1_D = Instr_D[19:15];
assign rs2_D =Instr_D[24:20];
assign rdest_D = Instr_D[11:7];
//instance of REG FILE
regfile registerfile(
            .clk(clk),
            .rst(reset),
            .we3(RegWrite) ,
            .a1(rs1_D), 
            .a2(rs2_D),
            .a3(rdest_W),
            .wd3(ResultW_s),
            .rd1(RD1_out_s),
            .rd2(RD2_out_s));

//instance of EXTEND
extend extend_module(.instr(Instr_D[31:7]), .immsrc(ImmSrc), .immext(ImmExt_s));

// DECODE/EXECUTE PIPELINE REGISTER
always_ff @(posedge clk)
            if(reset || Flush_E) //should go flush
            begin 
                rd1_E <= 'b0;
                rd2_E <= 'b0; 
                PC_E <=  'b0;
                rs1_E <= 'b0;
                rs2_E <= 'b0;
                rdest_E <= 'b0;
                ImmExt_E <= 'b0;
                PCPlus4_E <= 'b0;
            end
                 
            else 
            begin
                rd1_E <= RD1_out_s;
                rd2_E <= RD2_out_s; 
                PC_E <=  PC_D;
                rs1_E <= rs1_D;
                rs2_E <= rs2_D;
                rdest_E <= rdest_D;
                ImmExt_E <= ImmExt_s;
                PCPlus4_E <= PCPlus4_D;
            end
///////////////////////////////////////////////////////
//
// EXECUTE STAGE
//
///////////////////////////////////////////////////////


//mux 3 in - forwarding for SrcA
always_comb 
begin
    case(ForwardA_E)
        'b00: SrcA_E_s = rd1_E; 
        'b01: SrcA_E_s = ResultW_s;
        'b10: SrcA_E_s = ALUResult_M;
        default: SrcA_E_s = 'bx;
     endcase
end

//mux 3 in - forwarding for SrcB
always_comb 
begin
    case(ForwardB_E)
        'b00: SrcB_E_forward_s = rd2_E; 
        'b01: SrcB_E_forward_s = ResultW_s;
        'b10: SrcB_E_forward_s = ALUResult_M;
        default: SrcB_E_forward_s = 'bx;
     endcase
end

//instance of mux 
assign SrcB_E_s = ALUSrcB ? ImmExt_E : SrcB_E_forward_s;




//instance of ALU
alu aluinst(.SrcA(SrcA_E_s), .SrcB(SrcB_E_s), .ALUControl(ALUControl), .ALUResult(ALUResult_E_s), .Zero(Zero_s));



//instance of ADDER
adder adder_pc_target(.a(PC_E), .b(ImmExt_E), .y(PCTarget_E_s));

// EXECUTE/MEMORY PIPELINE REGISTER
always_ff @(posedge clk)
            if(reset) //should go flush
            begin 
                ALUResult_M <= 'b0;
                WriteData_M <= 'b0; 
                rdest_M <=  'b0;
                PCPlus4_M <= 'b0;
            end  
            else 
            begin
                ALUResult_M <=ALUResult_E_s ;
                WriteData_M <= SrcB_E_forward_s; 
                rdest_M <=  rdest_E;
                PCPlus4_M <=PCPlus4_E;
            end

L1_cache l1_data_cache(
    .clk(clk), 
    .rst(reset), 
    .address(ALUResult_M), 
    .load_operation(load_operation), 
    .we(cache_write), 
    .wd(WriteData_M), 
    .rd(ReadData_s)
    );

///////////////////////////////////////////////////////
//
// MEMORY STAGE
//
///////////////////////////////////////////////////////

// MEMORY/WRITE_BACK PIPELINE REGISTER
always_ff @(posedge clk)
            if(reset) //should go flush
            begin 
                ReadData_W <= 'b0;
                rdest_W <= 'b0; 
                PCPlus4_W <=  'b0;
                ALUResult_W <= 'b0;
            end  
            else 
            begin
                ReadData_W <= ReadData_s;
                rdest_W <= rdest_M; 
                PCPlus4_W <=  PCPlus4_M;
                ALUResult_W <= ALUResult_M;
            end


///////////////////////////////////////////////////////
//
// WRITE BACK STAGE
//
///////////////////////////////////////////////////////

//mux 3 in - just signals
always_comb 
begin
    case(ResultSrc)
        'b00: ResultW_s = ALUResult_W; 
        'b01: ResultW_s = ReadData_W;
        default: ResultW_s = PCPlus4_W;
     endcase
end



//output logic
assign PC_out = PC_out_s;
assign ALUResult = ALUResult_M;
assign WriteData = 0;
assign rdest_W_out = rdest_W;
assign rdest_M_out = rdest_M;
assign PCSrc_E_out =PCSelect_s;
assign rs1_E_out = rs1_E;
assign rs2_E_out = rs2_E;
assign rdest_E_out =rdest_E;
assign rs1_D_out = rs1_D;
assign rs2_D_out = rs2_D;

endmodule