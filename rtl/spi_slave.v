// ============================================================
// spi_slave.v
// SPI Slave Device (for simulation/testbench use only)
// Author : Jay Hepat, VIT Bhopal
// Description: Simple SPI slave that shifts in data on MOSI
//              and reflects data back on MISO. Used to verify
//              master-slave communication in simulation.
// ============================================================

`include "spi_defines.v"

module spi_slave (
    input  wire                    sclk,      // Serial clock from SPI master
    input  wire                    mosi,      // Master Out Slave In
    input  wire [`SPI_SS_NB-1:0]   ss_pad_o,  // Slave select (active low)
    output wire                    miso       // Master In Slave Out
);

    reg rx_slave = 1'b0;   // Slave is receiving from master
    reg tx_slave = 1'b0;   // Slave is transmitting to master

    reg [127:0] temp1 = 128'd0;   // Receive shift register
    reg [127:0] temp2 = 128'd0;   // Transmit shift register

    reg miso1 = 1'b0;
    reg miso2 = 1'b1;

    // Shift in MOSI data on rising edge when slave is selected and tx_slave active
    always @(posedge sclk) begin
        if ((ss_pad_o != {`SPI_SS_NB{1'b1}}) && ~rx_slave && tx_slave)
            temp1 <= {temp1[126:0], mosi};
    end

    // Shift in MOSI data on falling edge when rx_slave active
    always @(negedge sclk) begin
        if ((ss_pad_o != {`SPI_SS_NB{1'b1}}) && rx_slave && ~tx_slave)
            temp2 <= {temp2[126:0], mosi};
    end

    // Generate MISO on falling edge (rx_slave path)
    always @(negedge sclk) begin
        if (rx_slave && ~tx_slave)
            miso1 <= temp1[127];
    end

    // Generate MISO on falling edge (tx_slave path)
    always @(negedge sclk) begin
        if (~rx_slave && tx_slave)
            miso2 <= temp2[127];
    end

    assign miso = miso1 | miso2;

endmodule
