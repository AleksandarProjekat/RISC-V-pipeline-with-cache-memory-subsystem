`timescale 1ns / 1ps

module controller(
        input logic clk,
        input logic reset, 
        input logic [6:0] op,
        input logic [2:0] funct3,
        input logic funct7b5,
        output logic RegWrite,
        output logic [1:0] ResultSrc,
        output logic MemWrite,
        output logic ALUSrcB,
        output logic Jump,
        output logic Branch,
        output logic [2:0] ImmSrc,
        output logic [2:0] ALUControl,
        
        //output of hazard
        output logic [1:0] ForwardA_E,
        output logic [1:0] ForwardB_E,
        output logic Flush_E,
        output logic Flush_D,
        output logic Stall_D,
        output logic Stall_F,
        output logic load_operation,
        
        //input to hazard unit
        input logic [11:7] rdest_W,
        input logic [11:7] rdest_M,
        input logic PCSrc_E,
        input logic[19:15] rs1_E,
        input logic[24:20] rs2_E,
        input logic[11:7] rdest_E,
        input logic[19:15] rs1_D,
        input logic[24:20] rs2_D,
        input logic stall
    );
    logic [1:0] ALUOp_s;
    
    //FETCH stage signals
    logic [6:0] op_F;
    logic [2:0] funct3_F;
    logic funct7b5_F;
    
    //DECODE stage signals
    logic [6:0] op_D;
    logic [2:0] funct3_D;
    logic funct7b5_D;
    
    logic RegWrite_D, MemWrite_D, Jump_D, Branch_D, ALUSrcB_D;
    logic [1:0] ResultSrc_D; 
    logic [2:0] ImmSrc_D;
    logic [2:0] ALUControl_D;
    
    assign op_F = op;
    assign funct3_F = funct3;
    assign funct7b5_F= funct7b5;
    
    //EXECUTE stage signals
    logic RegWrite_E,MemWrite_E, Jump_E, Branch_E, ALUSrcB_E;
    logic [1:0] ResultSrc_E;
    logic [2:0] ALUControl_E;
    
    //MEMORY stage signlas
    
    logic RegWrite_M, MemWrite_M;
    logic [1:0]ResultSrc_M;
    
    //WRITE/BACK stage signals
    logic RegWrite_W;
    logic [1:0]ResultSrc_W;

    logic stall_total;
    
maindec main_decoder(.op(op_D),.RegWrite(RegWrite_D), .ResultSrc(ResultSrc_D), .MemWrite(MemWrite_D), .Jump(Jump_D), .Branch(Branch_D),  .ImmSrc(ImmSrc_D), .ALUSrcB(ALUSrcB_D), .ALUOp(ALUOp_s));
aludec alu_decoder(.opb5(op_D[5]), .funct3(funct3_D), .funct7b5(funct7b5_D), .ALUOp(ALUOp_s), .ALUControl(ALUControl_D));
hazard_unit hazard_unit_inst(.RegWrite_W(RegWrite_W), .rdest_W(rdest_W),.RegWrite_M(RegWrite_M),.rdest_M(rdest_M),.ResultSrc_E(ResultSrc_E),.PCSrc_E(PCSrc_E),.rs1_E(rs1_E),.rs2_E(rs2_E),.rdest_E(rdest_E),.rs1_D(rs1_D),.rs2_D(rs2_D),.ForwardB_E(ForwardB_E),.ForwardA_E(ForwardA_E),.Flush_E(Flush_E),.Flush_D(Flush_D),.Stall_D(Stall_D),.Stall_F(Stall_F));


assign RegWrite = RegWrite_W;
assign ResultSrc = ResultSrc_W ;
assign MemWrite = MemWrite_M; ;
assign ALUSrcB = ALUSrcB_E;
assign Jump = Jump_E;
assign Branch = Branch_E ;
assign ImmSrc =  ImmSrc_D;
assign ALUControl = ALUControl_E ;
//FLUSH_E , Flush_D Stall_D Stall_F
///////////////////////////////////////////////////////
//
// FETCH/DECOTE STAGE
//
///////////////////////////////////////////////////////

assign stall_total = Stall_D || stall;
always_ff @(posedge clk) begin
            if (reset || Flush_D)begin
                op_D <= 'b0;
                funct3_D <= 'b0;
                funct7b5_D <= 'b0;
            end
            else if (stall_total) begin
                op_D <= op_D;
                funct3_D <= funct3_D;
                funct7b5_D <= funct7b5_D;
            end
            else
            begin
                op_D <= op_F;
                funct3_D <= funct3_F;
                funct7b5_D <= funct7b5_F;
            end
end          
///////////////////////////////////////////////////////
//
// DECODE/EXECUTE STAGE
//
///////////////////////////////////////////////////////

always_ff @(posedge clk) begin
            if(reset || Flush_E) begin
                RegWrite_E <= 'b0;
                MemWrite_E <= 'b0;
                Jump_E <= 'b0;
                Branch_E <= 'b0;
                ALUSrcB_E <= 'b0;
                ResultSrc_E <= 'b0;
                ALUControl_E <= 'b0;
            
            end 
            else begin
                if(stall) begin
                    RegWrite_E <= RegWrite_E;
                    MemWrite_E <= MemWrite_E;
                    Jump_E <= Jump_E;
                    Branch_E <= Branch_E;
                    ALUSrcB_E <= ALUSrcB_E;
                    ResultSrc_E <= ResultSrc_E;
                    ALUControl_E <= ALUControl_E;
                end 
                else begin
                    RegWrite_E <= RegWrite_D;
                    MemWrite_E <= MemWrite_D;
                    Jump_E <= Jump_D;
                    Branch_E <= Branch_D;
                    ALUSrcB_E <= ALUSrcB_D;
                    ResultSrc_E <= ResultSrc_D;
                    ALUControl_E <= ALUControl_D;
                end
            end
end

///////////////////////////////////////////////////////
//
// EXECUTE/MEMORY STAGE
//
///////////////////////////////////////////////////////
always_ff @(posedge clk) begin
            if(reset) begin
                RegWrite_M <= 'b0;
                MemWrite_M <= 'b0;
                ResultSrc_M <= 'b0;
            end
            else begin
                if(stall) begin
                    RegWrite_M <= RegWrite_M;
                    MemWrite_M <= MemWrite_M;
                    ResultSrc_M <= ResultSrc_M;
                end
                else begin
                    RegWrite_M <= RegWrite_E;
                    MemWrite_M <= MemWrite_E;
                    ResultSrc_M <= ResultSrc_E;
                end   

            end
end

assign load_operation = (ResultSrc_M == 2'b01);

///////////////////////////////////////////////////////
//
// MEMORY/WRITE-BACK STAGE
//
///////////////////////////////////////////////////////

always_ff @(posedge clk) begin
            if(reset) 
            begin
                RegWrite_W <= 'b0;
                ResultSrc_W <= 'b0;
            end
            else begin
                if(stall) begin
                    RegWrite_W <= RegWrite_W;
                    ResultSrc_W <= ResultSrc_W;
                end
                else begin
                    RegWrite_W <= RegWrite_M;
                    ResultSrc_W <= ResultSrc_M;
                end
            end
end
endmodule
