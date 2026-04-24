`timescale 1ns / 1ps

module dmem(
    input logic clk,we, rst,
    input logic [31:0]a, wd, 
    output logic [31:0]rd,

    input logic load_operation,
    output logic valid_mem_data
    );
    
    logic [31:0] RAM[63:0];
    
    always_comb begin
        if(load_operation) begin
            rd = RAM[a[31:2]];
            valid_mem_data = 1;
        end
        else begin
            rd = 32'hx;
            valid_mem_data = 1'bx;
        end
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            for(integer i = 0; i< 64; i++) begin
                RAM[i] <= i+1;
            end
        end
        else begin
            if(we) begin
                RAM[a[31:2]] <= wd;
            end
        end
    end
endmodule
