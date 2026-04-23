`timescale 1ns / 1ps

module extend(
    input logic [31:7] instr,
    input logic [2:0] immsrc,
    output logic [31:0] immext
    );
    
        always_comb begin
                case(immsrc)
                        3'b000: begin // I-type
                                immext = {{20{instr[31]}}, instr[31:20]};
                        end
                        3'b001: begin // S-type
                                immext = {{20{instr[31]}}, instr[31:25], instr[11:7]};
                        end
                        3'b010: begin // B-type
                                immext = {{20{instr[31]}},instr[7], instr[30:25],instr[11:8], 1'b0};
                        end
                        3'b011: begin // ✅ U-type (LUI)
                                immext = {instr[31:12], 12'b0};
                        end
                        3'b100: begin // J-type (JAL)
                                immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
                        end
                        default: immext = 32'bx;
                endcase
        end
endmodule
