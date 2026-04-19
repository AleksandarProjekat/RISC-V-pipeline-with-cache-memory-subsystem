`timescale 1ns / 1ps

module regfile(
    input logic clk,
    input logic rst,
    input logic we3,
    input logic [4:0] a1, a2, a3,
    input logic [31:0] wd3,
    output logic [31:0] rd1, rd2);
    
logic [31:0] rf[31:0];

assign rf[0] = 'b0;

always_ff @(negedge clk or posedge rst) begin
    if(rst) begin
        for (integer i = 0; i<32; i++) begin
            rf[i] <= 0;    
        end
    end
    else begin
        if (we3) begin   
            rf[a3] <= wd3;
        end
    end
end

      
assign rd1 = (a1 != 0) ? rf[a1] : 0;
assign rd2 = (a2 != 0) ? rf[a2] : 0;

    
endmodule