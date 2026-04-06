// ============================================================
// spi_clgen.v
// SPI Master Core — Clock Generator
// Author : Jay Hepat, VIT Bhopal
// Description: Generates the SPI serial clock (sclk_out) by
//              dividing the system clock (wb_clk_in) using the
//              programmable DIVIDER register value.
//              Also produces cpol_0 and cpol_1 pulse signals
//              used by the shift register to clock data.
//
// Clock frequency formula:
//   f_sclk = f_wb_clk / (2 * (DIVIDER + 1))
// ============================================================

`include "spi_defines.v"

module spi_clgen (
    input  wire                         wb_clk_in,  // System clock
    input  wire                         wb_rst,     // Synchronous reset (active high)
    input  wire                         go,         // Transfer start signal
    input  wire                         tip,        // Transfer in progress
    input  wire                         last_clk,   // Last clock edge of transfer
    input  wire [`SPI_DIVIDER_LEN-1:0]  divider,    // Clock divider value

    output reg                          sclk_out,   // SPI serial clock output
    output reg                          cpol_0,     // Pulse on rising  edge of sclk
    output reg                          cpol_1      // Pulse on falling edge of sclk
);

    // Internal divider counter
    reg [`SPI_DIVIDER_LEN-1:0] cnt;

    // -------------------------------------------------------
    // Divider Counter
    // Counts from 1 to (divider + 1), then resets
    // -------------------------------------------------------
    always @(posedge wb_clk_in or posedge wb_rst) begin
        if (wb_rst) begin
            cnt <= {{(`SPI_DIVIDER_LEN-1){1'b0}}, 1'b1};
        end else if (tip) begin
            if (cnt == (divider + 1))
                cnt <= {{(`SPI_DIVIDER_LEN-1){1'b0}}, 1'b1};
            else
                cnt <= cnt + 1;
        end else if (cnt == 0) begin
            cnt <= {{(`SPI_DIVIDER_LEN-1){1'b0}}, 1'b1};
        end
    end

    // -------------------------------------------------------
    // Serial Clock Generation
    // Toggles sclk_out every (divider+1) system clock cycles
    // -------------------------------------------------------
    always @(posedge wb_clk_in or posedge wb_rst) begin
        if (wb_rst) begin
            sclk_out <= 1'b0;
        end else if (tip) begin
            if (cnt == (divider + 1)) begin
                if (!last_clk || sclk_out)
                    sclk_out <= ~sclk_out;
            end
        end
    end

    // -------------------------------------------------------
    // cpol_0 — one-cycle pulse on rising edge of sclk_out
    // cpol_1 — one-cycle pulse on falling edge of sclk_out
    // -------------------------------------------------------
    always @(posedge wb_clk_in or posedge wb_rst) begin
        if (wb_rst) begin
            cpol_0 <= 1'b0;
            cpol_1 <= 1'b0;
        end else begin
            cpol_0 <= (tip && (cnt == (divider + 1)) && !sclk_out);
            cpol_1 <= (tip && (cnt == (divider + 1)) &&  sclk_out);
        end
    end

endmodule
