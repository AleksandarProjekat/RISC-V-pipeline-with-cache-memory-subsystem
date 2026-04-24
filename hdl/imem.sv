`timescale 1ns / 1ps

module imem(
    input logic [31:0] a,
    output logic [31:0] rd
    );
    
    logic [31:0] RAM[63:0];
    initial
        begin
            RAM[6'd0] = 32'h00002103;
            RAM[6'd1] = 32'h00000013;
            /*
            RAM[6'd0] = 32'h00500113;
            RAM[6'd1] = 32'h00C00193;
            RAM[6'd2] = 32'hFF718393;
            RAM[6'd3] = 32'h0023E233;
            RAM[6'd4] = 32'h0041F2B3;
            RAM[6'd5] = 32'h004282B3;
            RAM[6'd6] = 32'h02728863;
            RAM[6'd7] = 32'h0041A233;
            RAM[6'd8] = 32'h00020463;
            RAM[6'd9] = 32'h00000293;
            RAM[6'd10] = 32'h0023A233;
            RAM[6'd11] = 32'h005203B3;
            RAM[6'd12] = 32'h402383B3;
            RAM[6'd13] = 32'h0471AA23;
            RAM[6'd14] = 32'h06002103;
            RAM[6'd15] = 32'h005104B3;
            RAM[6'd16] = 32'h008001EF;
            RAM[6'd17] = 32'h00100113;
            RAM[6'd18] = 32'h00910133;
            RAM[6'd19] = 32'h0221A023;
            RAM[6'd20] = 32'h00000013;
            */
        end
    
    assign rd = RAM[a[31:2]];
    
endmodule