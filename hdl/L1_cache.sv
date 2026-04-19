`timescale 1ns / 1ps

module L1_cache(
    input logic clk,
    input logic we,
    input logic [31:0]address, 
    input logic [31:0] wd, 
    input logic load_operation,
    output logic [31:0]rd

    );

    // -------------------------------------------------------
    // Adresna dekompozicija:
    //   [31:8]  -> tag    (24 bita)
    //   [7:2]   -> index  ( 6 bita, 64 seta)
    //   [1:0]   -> offset ( 2 bita, ignorisemo - word-aligned)
    // -------------------------------------------------------

    typedef struct packed {
        logic        valid;
        logic        lru;      // 1 = ovaj je "most recently used"
        logic [23:0] tag;
        logic [31:0] data;
    } cache_line_t;

    cache_line_t cache_memory_L1[63:0][2:0]; // 64 sets with 2 ways each

    logic [23:0] tag;
    logic [5:0]  index;

    logic way0_hit;
    logic way1_hit;
    logic cache_hit;

    typedef enum logic [1:0] {IDLE, CACHE_HIT} state_t;
    state_t state, next_state;


    assign tag = address[31:8];
    assign set_index = address[7:2];


    logic [31:0] RAM[63:0];
    
    assign rd = (load_operation == 1'b1) ? RAM[address[31:2]] : 32'bx;
    
    always_ff @(posedge clk)
        if(we) RAM[address[31:2]] <= wd;

    
    

    
    
    
        
endmodule