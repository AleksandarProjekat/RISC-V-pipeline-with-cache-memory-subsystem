`timescale 1ns / 1ps

module cache_L2_tb();

    logic clk_s;
    logic rst_s;
    logic we_s;
    logic load_s;
    logic [31:0] address_s;
    logic [31:0] wd_s;
    logic [31:0] data_from_mem_s;
    logic valid_mem_s;

    logic [31:0] rd_s;
    logic stall_s;
    logic [31:0] address_to_mem_s;
    logic [31:0] data_to_mem_s;

    // DUT
    L2_cache dut (
        .clk(clk_s),
        .rst(rst_s),
        .we(we_s),
        .load(load_s),
        .address(address_s),
        .wd(wd_s),
        .data_from_mem(data_from_mem_s),
        .valid_mem(valid_mem_s),
        .rd(rd_s),
        .stall(stall_s),
        .address_to_mem(address_to_mem_s),
        .data_to_mem(data_to_mem_s)
    );

    // ----------------------------------------
    // TASK: simulacija memorije
    // ----------------------------------------
    task automatic mem_response(input [31:0] data);
    begin
        @(posedge clk_s);
        data_from_mem_s = data;
        valid_mem_s = 1;
        @(posedge clk_s);
        valid_mem_s = 0;
    end
    endtask

    // Clock
    always begin
        clk_s = ~clk_s;
        #50; 
    end
    
    // ----------------------------------------
    // TEST SEKVENCE
    // ----------------------------------------
    initial begin
        $display("=== START TEST ===");

        // INIT
        clk_s = 0;
        rst_s = 1;
        we_s = 0;
        load_s = 0;
        address_s = 0;
        wd_s = 0;
        data_from_mem_s = 0;
        valid_mem_s = 0;

        repeat(2) begin
            @(posedge clk_s);
        end
        
        rst_s = 0;

        //for( integer i = 0; i < 64; i++) begin
            @(posedge clk_s);
            we_s = 0;
            address_s = 0 * 4;
            wd_s      = 1;
            @(posedge clk_s);
            we_s = 1;
        //end

        //for( integer i = 0; i < 64; i++) begin
            @(posedge clk_s);
            we_s = 0;
            address_s = 0 * 4 + 64 * 4;
            wd_s      = 0 + 64;
            @(posedge clk_s);
            we_s = 1;
        //end

        //for( integer i = 0; i < 64; i++) begin
            @(posedge clk_s);
            we_s = 0;
            address_s = 0 * 4 + 128 * 4;
            wd_s      = 0 + 128;
            @(posedge clk_s);
            we_s = 1;
        //end

        //for( integer i = 0; i < 64; i++) begin
            @(posedge clk_s);
            we_s = 0;
            address_s = 0 * 4 + 128 * 4 + 64 * 4;
            wd_s      = 0 * 4 + 128 + 64;
            @(posedge clk_s);
            we_s = 1;
        //end

        //for( integer i = 0; i < 64; i++) begin
            @(posedge clk_s);
            we_s = 0;
            address_s = 0 * 4 + 128 * 4 + 128 * 4;
            wd_s      = 0 * 4 + 128 + 128;
            @(posedge clk_s);
            we_s = 1;
        //end

        #20000;
        $finish;
    end

endmodule