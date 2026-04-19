`timescale 1ns / 1ps

module dmem(
    input logic clk,we,
    input logic [31:0]a, wd, 
    output logic [31:0]rd
    );

    typedef struct packed {
        logic valid;
        logic lru;
        logic [22:0] tag;
        logic [31:0] data;
    } cache_line_t;

    cache_line_t cache_memory_L1[63:0][2:0]; // 64 sets with 2 ways each
    
    logic [31:0] RAM[63:0];
    
    assign rd = RAM[a[31:2]];
    
    always_ff @(posedge clk)
        if(we) RAM[a[31:2]] <= wd;
        
endmodule
