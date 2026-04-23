module L2_cache(
    input  logic clk,
    input  logic rst,
    input  logic we,
    input  logic load,
    input  logic [31:0] address,
    input  logic [31:0] address_from_L1,
    input  logic [31:0] wd,
    input  logic [31:0] data_from_mem,
    input  logic valid_mem,

    output logic [31:0] rd,
    output logic stall,
    output logic [31:0] address_to_mem,
    output logic [31:0] data_to_mem,
    output logic we_dmem,
    output logic valid_data_from_L2,
    output logic [1:0] cache_hit
);

    // -------------------------------------------------------
    // PARAMETRI
    // -------------------------------------------------------
    localparam NUM_SETS = 64;
    localparam NUM_WAYS = 4;

    typedef struct packed {
        logic        valid;
        logic [23:0] tag;
        logic [31:0] data;
    } line_t;

    line_t cache_L2 [63:0][3:0];

    // MRU (2 bita po setu)
    logic [1:0] mru [63:0];

    logic [23:0] tag;
    logic [5:0]  index;

    assign tag   = address[31:8];
    assign index = address[7:2];

    // -------------------------------------------------------
    // HIT LOGIKA
    // -------------------------------------------------------
    logic [3:0] hit_vec;
    logic hit;
    logic [1:0] hit_way;

    
    logic [1:0] free_way, target_way;
    logic found_free;

    always_comb begin
        hit_vec = 4'b0000;
        hit = 0;
        hit_way = 0;

        for (int i = 0; i < 4; i++) begin
            if (cache_L2[index][i].valid && cache_L2[index][i].tag == tag)
                hit_vec[i] = 1;
        end

        hit = |hit_vec;

        case (hit_vec)
            4'b0001: hit_way = 2'd0;
            4'b0010: hit_way = 2'd1;
            4'b0100: hit_way = 2'd2;
            4'b1000: hit_way = 2'd3;
            default: hit_way = 2'd0;
        endcase
    end

    // -------------------------------------------------------
    // FSM
    // -------------------------------------------------------
    typedef enum logic [1:0] {IDLE, MISS} state_t;
    state_t state, next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
        end 
        else begin
            state <= next;
        end
    end

    always_comb begin
        case (state)
            IDLE: begin
                if (load && !hit) begin
                    cache_hit = 2'b01; // CACHE MISS
                    stall = 1;
                    next  = MISS;
                end
                else begin
                    stall = 0;
                    cache_hit = 2'b00; 
                    next = IDLE;   
                end
            end

            MISS: begin
                if (load && hit) begin
                    cache_hit = 2'b10; // CACHE HIT
                    next = IDLE;
                end
                else begin
                    stall = 1;
                    cache_hit = 2'b01; // CACHE MISS
                    next = MISS;
                end
            end
            default: next = IDLE;
        endcase
    end

    // -------------------------------------------------------
    // READ
    // -------------------------------------------------------
    always_comb begin
        if (load && hit) begin
            rd = cache_L2[index][hit_way].data;
            valid_data_from_L2 = 1;
        end
        else begin
            rd = 32'hx;
            valid_data_from_L2 = 0;
        end
    end

    always_comb begin
        found_free = 0;
        free_way = 0;

        for (int i = 0; i < 4; i++) begin
            if (!cache_L2[index][i].valid && !found_free) begin
                free_way   = i;
                found_free = 1;
            end
        end

        // ODABIR WAY-A
        if (found_free) begin
            // CASE 1: postoji slobodan slot
            target_way = free_way;
        end
        else begin
            // CASE 2: cache set je pun → NMRU replace

            case (mru[index])
                2'd0: target_way = 1;
                2'd1: target_way = 2;
                2'd2: target_way = 3;
                2'd3: target_way = 0;
            endcase
        end
    end

    // -------------------------------------------------------
    // WRITE + MISS HANDLING
    // -------------------------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < NUM_SETS; i++) begin
                mru[i] <= 0;
                for (int j = 0; j < NUM_WAYS; j++) begin
                    cache_L2[i][j].valid <= 0;
                    cache_L2[i][j].tag   <= 0;
                    cache_L2[i][j].data  <= 0;
                end
            end
            we_dmem        <= 0;
            data_to_mem    <= 0;
            address_to_mem <= 0;
        end
        else begin
            // -----------------------------------
            // WRITE (STORE)
            // -----------------------------------
            if (we) begin
                if (hit) begin
                    // WRITE HIT
                    cache_L2[index][hit_way].data <= wd;
                    mru[index] <= hit_way;
                    we_dmem    <= 0;
                end 
                else begin
                    // EVICTION (SAMO AKO JE VALID)
                    if (!found_free && cache_L2[index][target_way].valid) begin
                        data_to_mem    <= cache_L2[index][target_way].data;
                        address_to_mem <= {cache_L2[index][target_way].tag,index,2'b00};
                        we_dmem        <= 1;
                    end
                    else begin
                        data_to_mem    <= '0;
                        address_to_mem <= '0;
                        we_dmem        <=  0;
                    end

                    // WRITE ALLOCATE (UPIS NOVOG PODATKA)
                    cache_L2[index][target_way].valid <= 1;
                    cache_L2[index][target_way].tag   <= tag;
                    cache_L2[index][target_way].data  <= wd;

                    // UPDATE MRU
                    mru[index] <= target_way;
                end
            end
            // LOAD HIT -> update MRU
            else if (load && hit && state == IDLE) begin
                mru[index] <= hit_way;
                we_dmem    <= 0;
            end
            // LOAD MISS
            else if (state == MISS && valid_mem) begin
                // eviction
                if (!found_free && cache_L2[index][target_way].valid) begin
                    data_to_mem    <= cache_L2[index][target_way].data;
                    address_to_mem <= {cache_L2[index][target_way].tag,index,2'b00};
                    we_dmem        <= 1;
                end
                else begin
                    data_to_mem    <= '0;
                    address_to_mem <= '0;
                    we_dmem        <=  0;
                end

                // fill
                cache_L2[index][target_way].valid <= 1;
                cache_L2[index][target_way].tag   <= tag;
                cache_L2[index][target_way].data  <= data_from_mem;

                mru[index] <= target_way;
            end
            else begin
                data_to_mem    <= '0;
                address_to_mem <= '0;
                we_dmem        <=  0;
            end

        end
    end

endmodule