`timescale 1ns / 1ps

module uart_top_p(

    input rst,
    input [7:0] data_in,
    input wr_en,
    input clk,
    input rdy_clr,

    output rdy,
    output busy,
    output [7:0] data_out,
    output parity_error

);

wire rx_clk_en;
wire tx_clk_en;

wire tx_temp;


// --------------------------------------------------
// BAUD RATE GENERATOR
// --------------------------------------------------

baud_rate_generator_p bg (

    .clk(clk),

    .tx_enb(tx_clk_en),
    .rx_enb(rx_clk_en)

);


// --------------------------------------------------
// TRANSMITTER
// --------------------------------------------------

transmitter_p ut (

    .clk(clk),
    .wr_enb(wr_en),
    .rst(rst),

    .enb(tx_clk_en),

    .data_in(data_in),

    .tx(tx_temp),

    .busy(busy)

);


// --------------------------------------------------
// RECEIVER
// --------------------------------------------------

reciever_p ur (

    .clk(clk),
    .rst(rst),

    .rx(tx_temp),

    .rdy_clr(rdy_clr),

    .clk_enb(rx_clk_en),

    .rdy(rdy),

    .data_out(data_out),

    .parity_error(parity_error)

);

endmodule