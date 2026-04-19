`timescale 1ns / 1ps

module extend(
    input logic [31:7] instr,
    input logic [1:0] immsrc,
    output logic [31:0] immext
    );
    
    always_comb
        case(immsrc)
                2'b00: begin
                        immext = {{20{instr[31]}}, instr[31:20]};
                end
                2'b01: begin
                        immext = {{20{instr[31]}}, instr[31:25], instr[11:7]};
                end
                2'b10: begin
                        immext = {{20{instr[31]}},instr[7], instr[30:25],instr[11:8], 1'b0};
                end
                2'b11: begin
                        immext = { {12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0 };
                end
                default: immext = 32'bx;
        endcase
endmodule
