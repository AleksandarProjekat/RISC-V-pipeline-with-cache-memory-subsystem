`timescale 1ns / 1ps

module alu(
        input logic [31:0] SrcA,SrcB,
        input logic [2:0] ALUControl,
        output logic [31:0] ALUResult,
        output logic Zero
    );
    
    logic signed [31:0]arithmetic_shift_right;
    
    assign arithmetic_shift_right = $signed(SrcA) >>>  SrcB[4:0];
    always_comb
        case(ALUControl)
            3'b000:ALUResult = signed'(SrcA) + signed'(SrcB);
            3'b001:ALUResult = signed'(SrcA)-signed'(SrcB);
            3'b010:ALUResult = SrcA & SrcB;
            3'b011:ALUResult = SrcA | SrcB;
            3'b100:ALUResult = SrcA ^ SrcB;
            //2'b100:
            3'b101:if(signed'(SrcA) < signed'(SrcB))
                        ALUResult = 32'd1;
                    else
                        ALUResult = 32'd0;
            3'b110: ALUResult = SrcA >> SrcB[4:0];
            3'b111: ALUResult = SrcA << SrcB[4:0];
            default : ALUResult = 32'bx;
        endcase
        
     always_comb begin
        if(ALUResult === 32'd0) begin
            Zero = 1'b1;
        end
        else begin
            Zero = 1'b0;
        end
     end
endmodule
