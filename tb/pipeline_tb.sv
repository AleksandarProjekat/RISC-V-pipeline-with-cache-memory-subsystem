module tb();

    reg clk=0, rst;
    
    logic [31:0] WriteData_s, DataAdr_s;
    logic MemWrite_s;


    TOP dut(
        .clk(clk), 
        .reset(rst),
        .WriteData(WriteData_s), 
        .DataAdr(DataAdr_s),
        .MemWrite(MemWrite_s)
    );
    
    always begin
        clk = ~clk;
        #50;
    end

    initial begin
        rst <= 1'b1;
        #800;
        rst <= 1'b0;
        #20000;
        $finish;    
    end
    /*
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0);
    end
    */
    
endmodule