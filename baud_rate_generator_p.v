module baud_rate_generator_p (
    input clk,
    output reg tx_enb,
    output reg rx_enb
);

    reg [12:0] tx_counter = 13'd0;
    reg [9:0]  rx_counter = 10'd0;

    // TX counter
    // Generates TX enable after 5208 clock cycles
    always @(posedge clk) begin

        // Default: enable is LOW
        tx_enb <= 1'b0;

        if (tx_counter == 13'd5207) begin
            tx_counter <= 13'd0;
            tx_enb <= 1'b1;
        end
        else begin
            tx_counter <= tx_counter + 13'd1;
        end

    end


    // RX counter
    // Generates RX enable after 325 clock cycles
    always @(posedge clk) begin

        // Default: enable is LOW
        rx_enb <= 1'b0;

        if (rx_counter == 10'd324) begin
            rx_counter <= 10'd0;
            rx_enb <= 1'b1;
        end
        else begin
            rx_counter <= rx_counter + 10'd1;
        end

    end

endmodule