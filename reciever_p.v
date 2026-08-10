`timescale 1ns / 1ps

module reciever_p(

    input clk,
    input rst,
    input rx,
    input rdy_clr,
    input clk_enb,

    output reg rdy,
    output reg [7:0] data_out,
    output reg parity_error

);

parameter start_state  = 2'b00;
parameter data_state   = 2'b01;
parameter parity_state = 2'b10;
parameter stop_state   = 2'b11;

reg [1:0] state;

reg [3:0] sample;

reg [2:0] index;

reg [7:0] temp_register;

reg parity_received;


// --------------------------------------------------
// RECEIVER
// --------------------------------------------------

always @(posedge clk)
begin

    if (rst)
    begin
        state         <= start_state;
        sample        <= 4'd0;
        index         <= 3'd0;
        temp_register <= 8'd0;

        data_out      <= 8'd0;

        rdy           <= 1'b0;

        parity_received <= 1'b0;
        parity_error    <= 1'b0;
    end

    else
    begin

        // ------------------------------------------
        // CLEAR READY
        // ------------------------------------------

        if (rdy_clr)
        begin
            rdy <= 1'b0;
        end


        // ------------------------------------------
        // RECEIVE ONLY WHEN RX ENABLE OCCURS
        // ------------------------------------------

        if (clk_enb)
        begin

            case(state)

                // ==================================
                // START STATE
                // ==================================

                start_state:
                begin

                    if (rx == 1'b0)
                    begin

                        sample <= sample + 1'b1;

                        if (sample == 4'd15)
                        begin
                            state <= data_state;

                            sample <= 4'd0;

                            index <= 3'd0;

                            temp_register <= 8'd0;

                            parity_error <= 1'b0;
                        end

                    end

                    else
                    begin
                        sample <= 4'd0;
                    end

                end


                // ==================================
                // DATA STATE
                // ==================================

                data_state:
                begin

                    sample <= sample + 1'b1;


                    // Sample in middle of bit
                    if (sample == 4'd8)
                    begin
                        temp_register[index] <= rx;
                    end


                    // End of one bit
                    if (sample == 4'd15)
                    begin

                        sample <= 4'd0;


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


                // ==================================
                // PARITY STATE
                // ==================================

                parity_state:
                begin

                    sample <= sample + 1'b1;


                    // Sample parity in middle
                    if (sample == 4'd8)
                    begin
                        parity_received <= rx;

                        // EVEN PARITY CHECK
                        if (rx != (^temp_register))
                        begin
                            parity_error <= 1'b1;
                        end

                        else
                        begin
                            parity_error <= 1'b0;
                        end

                    end


                    // End of parity bit
                    if (sample == 4'd15)
                    begin

                        sample <= 4'd0;

                        state <= stop_state;

                    end

                end


                // ==================================
                // STOP STATE
                // ==================================

                stop_state:
                begin

                    sample <= sample + 1'b1;


                    if (sample == 4'd15)
                    begin

                        state <= start_state;

                        data_out <= temp_register;

                        rdy <= 1'b1;

                        sample <= 4'd0;

                    end

                end


                // ==================================
                // DEFAULT
                // ==================================

                default:
                begin

                    state <= start_state;

                    sample <= 4'd0;

                    index <= 3'd0;

                end

            endcase

        end

    end

end

endmodule