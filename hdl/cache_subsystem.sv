module cache_subsystem (
    input logic clk_in,                         //OBAVEZNO
    input logic rst_in,                         //OBAVEZNO
    input logic [31:0] address_in,              //OBAVEZNO
    input logic load_operation_in,              //govoris L1 da ucita podatak
    input logic we_in,                          //OBAVEZNO
    input logic [31:0] wd_in,                   //OBAVEZNO
    input  logic [31:0] data_from_mem_in,       //Ucitavas podatak iz dmem
    input  logic valid_mem_in,
    
    output logic [31:0] rd_out,                 //OBAVEZNO
    output logic [31:0] address_to_mem_out,     //Pri evikciji saljes adresu 
    output logic [31:0] data_to_mem_out,        //Pri evikciji saljes podatak
    output logic we_dmem_out,                   //Pri evikciji enableujes upis
    output logic [1:0] cache_hit_out,           //Pri cache-hiss saljes load zahtev iz dmem
    output logic stall_out                      //U slucaju cache-miss drzis stall na 1 kako bi zaustavio pipeline da ne napreduje dalje
);

    logic valid_data_from_L2_s;
    logic we_L2_s;
    logic [1:0] cache_hit_s;

    logic load_L2_s;
    logic [31:0] data_to_L2_s;
    logic [31:0] address_to_L2_s, address_s;
    logic [31:0] address_L2;
    logic [31:0] data_from_L2_s;

    logic valid_mem_in_s, valid_mem_in_d;
    logic [31:0] data_from_mem_in_s, data_from_mem_in_d;

    L1_cache L1_mem(
        .clk(clk_in),
        .we(we_in),
        .rst(rst_in),
        .valid_load(valid_data_from_L2_s),
        .address(address_in), 
        .wd(wd_in), 
        .data_from_L2(data_from_L2_s),
        .load_operation(load_operation_in),
        .rd(rd_out),
        .data_to_L2(data_to_L2_s),
        .address_to_L2(address_to_L2_s),
        .stall(stall_out),
        .we_L2(we_L2_s),
        .cache_hit(cache_hit_s)
    );

    assign load_L2_s = (cache_hit_s == 2'b01) ? 1 : 0;

    always_comb begin
        if(we_L2_s == 1) begin
            address_s  = address_to_L2_s; 
        end
        else if(load_L2_s && cache_hit_s == 2'b01) begin
            address_s  = address_in;
        end
        else begin
            address_s  = 32'bx;
        end
    end

    assign valid_mem_in_s = valid_mem_in;
    assign data_from_mem_in_s = data_from_mem_in;

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            valid_mem_in_d   <= 0;
            data_from_mem_in_d <= '0;
        end 
        else begin
            valid_mem_in_d <= valid_mem_in_s;
            data_from_mem_in_d <= data_from_mem_in_s;
        end
    end

    L2_cache L2_mem(
        .clk(clk_in),
        .rst(rst_in),
        .we(we_L2_s),
        .load(load_L2_s),
        .address(address_s),
        .wd(data_to_L2_s),
        .data_from_mem(data_from_mem_in_d),
        .valid_mem(valid_mem_in_d),
        .rd(data_from_L2_s),
        .stall(),
        .address_to_mem(address_to_mem_out),
        .data_to_mem(data_to_mem_out),
        .we_dmem(we_dmem_out),
        .valid_data_from_L2(valid_data_from_L2_s),
        .cache_hit(cache_hit_out)
    );

endmodule