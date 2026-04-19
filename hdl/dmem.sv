`timescale 1ns / 1ps

module dmem(
    input logic clk,we,
    input logic [31:0]a, wd, 
    output logic [31:0]rd
    );

    typedef struct packed 
    {
        logic [1:0]   mesi_state;  
        logic [23:0]  tag;
        logic [31:0]  data;   
    } cache_line_t;
    
    logic [31:0] RAM[63:0];
    
    assign rd = RAM[a[31:2]];
    
    always_ff @(posedge clk)
        if(we) RAM[a[31:2]] <= wd;
        
endmodule
