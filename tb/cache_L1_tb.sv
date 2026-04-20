module cache_L1_tb();

    reg clk_s=0, rst_s;
    
    logic [31:0] WriteData_s, DataAdr_s;
    logic MemWrite_s;

    logic we_s;
    logic [31:0]address_s; 
    logic [31:0] wd_s;
    logic [31:0] data_from_L2_s;
    logic load_operation_s;
    logic [31:0]rd_s;
    logic [31:0] data_to_L2_s;
    logic [31:0] address_to_L2_s;
    logic stall_s;

    logic valid_load_s;

    logic [23:0] tag_s;
    logic [5:0] index_s;
    
    assign tag_s   = address_s[31:8];
    assign index_s = address_s[ 7:2];

    L1_cache dut(
        .clk(clk_s),
        .we(we_s),
        .rst(rst_s),
        .address(address_s), 
        .wd(wd_s), 
        .data_from_L2(data_from_L2_s),
        .load_operation(load_operation_s),
        .valid_load(valid_load_s),
        .rd(rd_s),
        .data_to_L2(data_to_L2_s),
        .address_to_L2(address_to_L2_s),
        .stall(stall_s)
    );

    task automatic test_load_miss();
        fork
            begin
                load_operation_s = 1;
                repeat(5) begin
                    @(posedge clk_s);
                end
                load_operation_s = 0;
            end
            begin
                repeat(2) begin
                    @(posedge clk_s);
                end

                data_from_L2_s = 1;
                valid_load_s = 1;
                @(posedge clk_s);
                valid_load_s = 0;
            end
        join

        repeat(5) begin
            @(posedge clk_s);
        end
        
        fork
            begin
                load_operation_s = 1;
                address_s        = 64*4;
                repeat(5) begin
                    @(posedge clk_s);
                end
                load_operation_s = 0;
            end
            begin
                repeat(2) begin
                    @(posedge clk_s);
                end

                data_from_L2_s = 2;
                valid_load_s = 1;
                @(posedge clk_s);
                valid_load_s = 0;
            end
        join

        repeat(5) begin
            @(posedge clk_s);
        end
        
        fork
            begin
                load_operation_s = 1;
                address_s        = 128*4;
                repeat(5) begin
                    @(posedge clk_s);
                end
                load_operation_s = 0;
            end
            begin
                repeat(2) begin
                    @(posedge clk_s);
                end

                data_from_L2_s = 3;
                valid_load_s = 1;
                @(posedge clk_s);
                valid_load_s = 0;
            end
        join
    endtask
    
    task automatic test_data_eviction_from_set();
        for( integer i = 0; i < 64; i++) begin
            @(posedge clk_s);
            we_s = 0;
            address_s = i * 4;
            wd_s      = i;
            @(posedge clk_s);
            we_s = 1;
        end

        for( integer i = 0; i < 64; i++) begin
            @(posedge clk_s);
            we_s = 0;
            address_s = i * 4 + 64 * 4;
            wd_s      = i + 64;
            @(posedge clk_s);
            we_s = 1;
        end

        for( integer i = 0; i < 64; i++) begin
            @(posedge clk_s);
            we_s = 0;
            address_s = i * 4 + 128 * 4;
            wd_s      = i + 128;
            @(posedge clk_s);
            we_s = 1;
        end
    endtask

    always begin
        clk_s = ~clk_s;
        #50;
    end

    initial begin
        rst_s = 1'b1;
        we_s             = 'b0;
        address_s        = 'b0; 
        wd_s             = 'b0; 
        data_from_L2_s   = 'b0;
        load_operation_s = 'b0;
        valid_load_s = 0;

        #800;
        rst_s = 1'b0;

        repeat(5) begin
            @(posedge clk_s);
        end
        
        // =======================================================
        //  Stroing data in L1 first and second way of each set
        //  then storing another data to cause eviction
        // =======================================================
        test_data_eviction_from_set();

        // =======================================================
        //  Loading data from outstide in first and second way of set
        //  then storing another data to cause eviction
        // =======================================================
        //test_load_miss();

        #50000;
        $finish;    
    end
    
endmodule

