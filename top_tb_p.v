`timescale 1ns / 1ps

module top_tb_p;

    // ==================================================
    // FINAL UART INPUTS
    // ==================================================
    reg        clk;
    reg        rst;
    reg [7:0]  data_in;
    reg        wr_en;
    reg        rdy_clr;

    // ==================================================
    // FINAL UART OUTPUTS
    // ==================================================
    wire       rdy;
    wire       busy;
    wire [7:0] data_out;
    wire       parity_error;

    // ==================================================
    // DUT
    // ==================================================
    uart_top_p uut (
        .rst          (rst),
        .data_in      (data_in),
        .wr_en        (wr_en),
        .clk          (clk),
        .rdy_clr       (rdy_clr),

        .rdy          (rdy),
        .busy         (busy),
        .data_out     (data_out),
        .parity_error (parity_error)
    );

    // ==================================================
    // CLOCK
    // 100 MHz clock
    // ==================================================
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ==================================================
    // TEST
    // ==================================================
    initial begin

        // ----------------------------------------------
        // INITIAL VALUES
        // ----------------------------------------------
        rst     = 1'b1;
        data_in = 8'b00000000;
        wr_en   = 1'b0;
        rdy_clr = 1'b0;

        // ----------------------------------------------
        // RESET
        // ----------------------------------------------
        repeat(10) @(posedge clk);

        rst = 1'b0;

        repeat(10) @(posedge clk);

        // ----------------------------------------------
        // SEND BYTE
        // ----------------------------------------------
        data_in = 8'b10101010;

        $display("==========================================");
        $display("UART TEST START");
        $display("FINAL INPUT = %b", data_in);
        $display("==========================================");

        @(posedge clk);
        wr_en = 1'b1;

        @(posedge clk);
        wr_en = 1'b0;

        // ----------------------------------------------
        // WAIT FOR TRANSMITTER
        // ----------------------------------------------
        wait(busy == 1'b1);

        $display("Transmitter started...");

        wait(busy == 1'b0);

        $display("Transmitter finished.");

        // ----------------------------------------------
        // WAIT FOR RECEIVER
        // ----------------------------------------------
        wait(rdy == 1'b1);

        // ----------------------------------------------
        // DISPLAY FINAL RESULT
        // ----------------------------------------------
        $display("------------------------------------------");
        $display("FINAL INPUT  = %b", data_in);
        $display("FINAL OUTPUT = %b", data_out);
        $display("PARITY ERROR = %b", parity_error);
        $display("------------------------------------------");

        if(data_out == data_in)
            $display("UART LOOPBACK PASS");
        else
            $display("UART LOOPBACK FAIL");

        // ----------------------------------------------
        // CLEAR READY
        // ----------------------------------------------
        @(posedge clk);
        rdy_clr = 1'b1;

        @(posedge clk);
        rdy_clr = 1'b0;

        #500;

        $display("==========================================");
        $display("SIMULATION FINISHED");
        $display("==========================================");

        $finish;
    end

endmodule