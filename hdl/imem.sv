`timescale 1ns / 1ps

module imem(
    input logic [31:0] a,
    output logic [31:0] rd
    );
    
    logic [31:0] RAM[63:0];
    initial
        begin
            RAM[6'd0]  = 32'h10000093;
            RAM[6'd1]  = 32'h20000113;
            RAM[6'd2]  = 32'h40000193;
            RAM[6'd3]  = 32'h00318233;
            RAM[6'd4]  = 32'h004202b3;
            RAM[6'd5]  = 32'h00002337;
            RAM[6'd6]  = 32'h000043b7;
            RAM[6'd7]  = 32'h00008437;
            RAM[6'd8]  = 32'h00102023;
            RAM[6'd9]  = 32'h0020a023;
            RAM[6'd10] = 32'h00312023;
            RAM[6'd11] = 32'h0041a023;
            RAM[6'd12] = 32'h00522023;
            RAM[6'd13] = 32'h0062a023;
            RAM[6'd14] = 32'h00732023;
            RAM[6'd15] = 32'h00002103;
        end
    
    assign rd = RAM[a[31:2]];
    
endmodule