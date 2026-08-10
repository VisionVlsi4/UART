`timescale 1ns / 1ps

module transmitter_p(
    input clk,
    input wr_enb,
    input rst,
    input enb,
    input [7:0] data_in,

    output reg tx,
    output busy
);

parameter idle_state  = 3'b000;
parameter start_state = 3'b001;
parameter data_state  = 3'b010;
parameter parity_state = 3'b011;
parameter stop_state  = 3'b100;

reg [7:0] data;
reg [2:0] index;
reg [2:0] state;

reg parity_bit;


// --------------------------------------------------
// BUSY
// --------------------------------------------------

assign busy = (state != idle_state);


// --------------------------------------------------
// TRANSMITTER
// --------------------------------------------------

always @(posedge clk)
begin

    if (rst)
    begin
        tx         <= 1'b1;
        data       <= 8'b0;
        index      <= 3'd0;
        state      <= idle_state;
        parity_bit <= 1'b0;
    end

    else
    begin

        case(state)

            // --------------------------------------
            // IDLE
            // --------------------------------------

            idle_state:
            begin
                tx <= 1'b1;

                if (wr_enb)
                begin
                    data       <= data_in;
                    parity_bit <= ^data_in;
                    index      <= 3'd0;

                    state <= start_state;
                end
            end


            // --------------------------------------
            // START BIT
            // --------------------------------------

            start_state:
            begin
                if (enb)
                begin
                    tx <= 1'b0;

                    state <= data_state;
                end
            end


            // --------------------------------------
            // DATA BITS
            // LSB FIRST
            // --------------------------------------

            data_state:
            begin
                if (enb)
                begin

                    tx <= data[index];

                    if (index == 3'd7)
                    begin
                        state <= parity_state;
                    end

                    else
                    begin
                        index <= index + 1'b1;
                    end

                end
            end


            // --------------------------------------
            // PARITY BIT
            // --------------------------------------

            parity_state:
            begin
                if (enb)
                begin
                    tx <= parity_bit;

                    state <= stop_state;
                end
            end


            // --------------------------------------
            // STOP BIT
            // --------------------------------------

            stop_state:
            begin
                if (enb)
                begin
                    tx <= 1'b1;

                    state <= idle_state;
                end
            end


            // --------------------------------------
            // DEFAULT
            // --------------------------------------

            default:
            begin
                tx    <= 1'b1;
                state <= idle_state;
            end

        endcase

    end

end

endmodule