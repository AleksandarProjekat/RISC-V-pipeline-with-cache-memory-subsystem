
module cache_subsystem_tb();

    logic clk_s=0, rst_s;
    
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

    cache_subsystem dut (
        .clk_in(clk_s),
        .rst_in(rst_s),
        .address_in(address_s),
        .load_operation_in(load_operation_s),
        .we_in(we_s),
        .wd_in(wd_s),
        .data_from_mem_in(),
        .valid_mem_in(),
        
        .rd_out(),
        .address_to_mem_out(),
        .data_to_mem_out(),
        .we_dmem_out(),
        .cache_hit_out(),
        .stall_out()
    );

    always begin
        clk_s = ~clk_s;
        #50;
    end

    initial begin
        // INIT
        clk_s = 0;
        rst_s = 1;
        we_s = 0;
        address_s = 0;
        wd_s = 0;

        repeat(2) begin
            @(posedge clk_s);
        end
        
        rst_s = 0;

        repeat(2) begin
            @(posedge clk_s);
        end

        // UPIS U PRVI WAY
        @(posedge clk_s);
        we_s = 0;
        address_s = 0 * 4;
        wd_s      = '1;
        @(posedge clk_s);
        we_s = 1;

        repeat(3) begin
            @(posedge clk_s);
            we_s = 0;
        end
        
        // UPIS U DRUGI WAY
        @(posedge clk_s);
        we_s = 0;
        address_s = 0 * 4 + 64 * 4;
        wd_s      = 32'h10101010;
        @(posedge clk_s);
        we_s = 1;

        repeat(3) begin
            @(posedge clk_s);
            we_s = 0;
        end

        // UPIS U PRVI WAY DRUGI PUT
        @(posedge clk_s);
        we_s = 0;
        address_s = 0 * 4 + 64 * 4 + 64 * 4;
        wd_s      = 32'h01010101;
        @(posedge clk_s);
        we_s = 1;

        @(posedge clk_s);
        we_s = 0;
        address_s = '1;

        repeat(3) begin
            @(posedge clk_s);
            we_s = 0;
        end

        // UPIS U DRUGI WAY DRUGI PUT
        @(posedge clk_s);
        we_s = 0;
        address_s = 0 * 4 + 64 * 4 + 64 * 4 + 64 * 4;
        wd_s      = 32'h11110000;
        @(posedge clk_s);
        we_s = 1;

        @(posedge clk_s);
        we_s = 0;
        address_s = '1;

        repeat(3) begin
            @(posedge clk_s);
            we_s = 0;
        end

        // UPIS U PRVI WAY TRECI PUT
        @(posedge clk_s);
        we_s = 0;
        address_s = 0 * 4 + 64 * 4 + 64 * 4 + 64 * 4 + 64 * 4;
        wd_s      = 32'h00001111;
        @(posedge clk_s);
        we_s = 1;

        @(posedge clk_s);
        we_s = 0;
        address_s = '1;

        repeat(3) begin
            @(posedge clk_s);
            we_s = 0;
        end

        // UPIS U DRUGI WAY TRECI PUT
        @(posedge clk_s);
        we_s = 0;
        address_s = 0 * 4 + 64 * 4 + 64 * 4 + 64 * 4 + 64 * 4 + 64 * 4;
        wd_s      = 32'h1;
        @(posedge clk_s);
        we_s = 1;

        @(posedge clk_s);
        we_s = 0;
        address_s = '1;

        repeat(3) begin
            @(posedge clk_s);
            we_s = 0;
        end

        // UPIS U DRUGI WAY TRECI PUT
        @(posedge clk_s);
        we_s = 0;
        address_s = 0 * 4 + 64 * 4 + 64 * 4 + 64 * 4 + 64 * 4 + 64 * 4 + 64 * 4;
        wd_s      = 32'h2;
        @(posedge clk_s);
        we_s = 1;

        @(posedge clk_s);
        we_s = 0;
        address_s = '1;

        #20000;
        $finish;    
    end

endmodule