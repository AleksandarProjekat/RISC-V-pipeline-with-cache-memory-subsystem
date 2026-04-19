`timescale 1ns / 1ps

module L1_cache(
    input logic clk,
    input logic we,
    input logic rst,
    input logic [31:0]address, 
    input logic [31:0] wd, 
    input logic load_operation,
    output logic [31:0]rd,
    output logic stall
    );

    // -------------------------------------------------------
    // Adresna dekompozicija:
    //   [31:8]  -> tag    (24 bita)
    //   [7:2]   -> index  ( 6 bita, 64 seta)
    //   [1:0]   -> offset ( 2 bita, ignorisemo - word-aligned)
    // -------------------------------------------------------

    // -------------------------------------------------------
    // Cache_hit [1:0]:
    //   cache_hit == 00 -> ne znaci nista
    //   cache_hit == 10 -> cache hit
    //   cache_hit == 01 -> cache miss
    // -------------------------------------------------------

    typedef struct packed {
        logic        valid;
        logic        lru;      // 0 = ovaj je "most recently used"
        logic [23:0] tag;
        logic [31:0] data;
    } cache_line_t;

    cache_line_t cache_memory_L1[63:0][1:0]; // 64 sets with 2 ways each

    logic [23:0] tag;
    logic [5:0]  set_index;

    logic way0_hit;
    logic way1_hit;
    logic [1:0] cache_hit;

    typedef enum logic [1:0] {MAIN, WAIT_WRITE} state_t;
    state_t state, next_state;

    assign tag = address[31:8];
    assign set_index = address[7:2];

    logic [31:0] RAM[63:0];

    // State machine for cache miss handling
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= MAIN;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
        stall = 0;
        next_state = MAIN;

        case (state)
            MAIN: begin
                if(load_operation) begin        // LOAD
                    if (cache_hit == 2'b01) begin
                        next_state = WAIT_WRITE;    // Miss scenario - Next state has to fetch data from current address from data memory
                        stall = 'b1;
                    end 
                    else begin
                        next_state = MAIN;      
                        stall = 'b0;
                    end
                end
                else begin  
                    next_state = MAIN;      
                    stall = 'b0;
                end
            end
            WAIT_WRITE: begin
                stall = 'b1;

                if(cache_hit == 2'b10) begin
                    next_state = MAIN;
                end 
                else begin
                    next_state = WAIT_WRITE;
                end
            end
        endcase 
    end
    
    always_comb begin
        //rd = (load_operation == 1'b1) ? RAM[address[31:2]] : 32'bx;
        if(load_operation) begin
            way0_hit = (cache_memory_L1[set_index][0].valid && (cache_memory_L1[set_index][0].tag == tag)) ? 1 : 0;
            way1_hit = (cache_memory_L1[set_index][1].valid && (cache_memory_L1[set_index][1].tag == tag)) ? 1 : 0;

            if (way0_hit) begin
                cache_hit = 2'b10;          // HIT
                rd = cache_memory_L1[set_index][0].data;
            end else if (way1_hit) begin
                cache_hit = 2'b10;          // HIT
                rd = cache_memory_L1[set_index][1].data;
            end else begin
                cache_hit = 2'b01;          // MISS
            end
        end
        else begin
            way0_hit  = 0;
            way1_hit  = 0;
            cache_hit = 2'b00;
        end
    end
    
    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            for (integer i = 0; i < 64; i++) begin
                for (integer j = 0; j < 2; j++) begin
                    cache_memory_L1[i][j].valid <= 0;
                    cache_memory_L1[i][j].lru   <= 0;  
                    cache_memory_L1[i][j].tag   <= 'b0;
                    cache_memory_L1[i][j].data  <= 'b0;
                end
            end
        end 
        else begin
            if(we) begin
                RAM[address[31:2]] <= wd;


                if(cache_memory_L1[set_index][0].valid == 0 && cache_memory_L1[set_index][1].valid == 0) begin 
                    // Smesti na nulti way
                    cache_memory_L1[set_index][0].valid <= 1;
                    cache_memory_L1[set_index][0].lru   <= 0;   // Mark as recently used
                    cache_memory_L1[set_index][1].lru   <= 1;   // Mark Way 1 as least recently used
                    cache_memory_L1[set_index][0].data  <= wd;
                    cache_memory_L1[set_index][0].tag   <= tag;
                end
                // Nulti je zauzet - Prvi je slobodan
               else if(cache_memory_L1[set_index][0].valid == 1 && cache_memory_L1[set_index][1].valid == 0) begin
                    if(cache_memory_L1[set_index][0].tag != tag) begin
                        // Smesti na prvi
                        cache_memory_L1[set_index][1].valid <= 1;
                        cache_memory_L1[set_index][1].lru   <= 0;   // Mark as recently used
                        cache_memory_L1[set_index][0].lru   <= 1;   // Mark Way 1 as least recently used
                        cache_memory_L1[set_index][1].data  <= wd;
                        cache_memory_L1[set_index][1].tag   <= tag;
                    end
                    else begin
                        // Smesti na nutli
                        cache_memory_L1[set_index][0].valid <= 1;
                        cache_memory_L1[set_index][0].lru   <= 0;   // Mark as recently used
                        cache_memory_L1[set_index][1].lru   <= 1;   // Mark Way 1 as least recently used
                        cache_memory_L1[set_index][0].data  <= wd;
                        cache_memory_L1[set_index][0].tag   <= tag;
                    end
                end
                // Oba su zauzeta 
                else if(cache_memory_L1[set_index][0].valid == 1 && cache_memory_L1[set_index][1].valid == 1) begin
                    if(cache_memory_L1[set_index][0].tag == tag) begin
                        // Smesti na nulti i izbaci u DMEM
                        cache_memory_L1[set_index][0].data <= wd;
                        cache_memory_L1[set_index][0].lru  <= 0;
                        cache_memory_L1[set_index][1].lru  <= 1;
                    end 
                    else if(cache_memory_L1[set_index][1].tag == tag) begin
                        // Smesti na prvi i izbaci u DMEM
                        cache_memory_L1[set_index][1].data <= wd;
                        cache_memory_L1[set_index][1].lru  <= 0;
                        cache_memory_L1[set_index][0].lru  <= 1;
                    end
                    else if(cache_memory_L1[set_index][0].tag != tag && cache_memory_L1[set_index][1].tag != tag) begin
                        // LRU - Smesti na onaj ciji je LRU 1 i izbaci u DMEM
                        if(cache_memory_L1[set_index][0].lru == 1) begin
                            cache_memory_L1[set_index][0].data <= wd;
                            cache_memory_L1[set_index][0].tag  <= tag;
                            cache_memory_L1[set_index][0].lru  <= 0;
                            cache_memory_L1[set_index][1].lru  <= 1;
                        end
                        else if(cache_memory_L1[set_index][1].lru == 1) begin
                            cache_memory_L1[set_index][1].data <= wd;
			    			cache_memory_L1[set_index][1].tag  <= tag;
                            cache_memory_L1[set_index][1].lru  <= 0;
                            cache_memory_L1[set_index][0].lru  <= 1;
                        end
                    end
                end
            end
            // Load Hit in L1 - Only toggle LRU bits
            else if(cache_hit == 1 && load_operation) begin
                // Handle LOAD HIT: update LRU
                if (way0_hit == 1) begin
                    cache_memory_L1[set_index][0].lru <= 0; // Way 0 recently used
                    cache_memory_L1[set_index][1].lru <= 1; // Way 1 least recently used
                end 
                else if (way1_hit == 1) begin
                    cache_memory_L1[set_index][0].lru <= 1; // Way 0 least recently used
                    cache_memory_L1[set_index][1].lru <= 0; // Way 1 recently used
                end
            end    
        end
    end    
endmodule