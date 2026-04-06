// ============================================================
// spi_shift_reg.v
// SPI Master Core — Shift Register
// Author : Jay Hepat, VIT Bhopal
// Description: Handles serial data shifting for both transmit
//              (MOSI) and receive (MISO) paths.
//              Supports MSB/LSB-first transfer, configurable
//              character length, and independent TX/RX clock
//              edge selection.
// ============================================================

`include "spi_defines.v"

module spi_shift_reg (
    input  wire                         wb_clk_in,    // System clock
    input  wire                         wb_rst,       // Synchronous reset
    input  wire                         go,           // Start transfer
    input  wire                         miso,         // Master In Slave Out
    input  wire                         lsb,          // 1 = LSB first, 0 = MSB first
    input  wire                         sclk,         // SPI serial clock (from clgen)
    input  wire                         cpol_0,       // Rising  edge pulse
    input  wire                         cpol_1,       // Falling edge pulse
    input  wire                         rx_negedge,   // Sample MISO on falling edge
    input  wire                         tx_negedge,   // Drive  MOSI on falling edge
    input  wire [3:0]                   byte_sel,     // Wishbone byte select
    input  wire [3:0]                   latch,        // Latch strobe from spi_top
    input  wire [`SPI_CHAR_LEN_BITS-1:0] len,         // Transfer length in bits
    input  wire [31:0]                  p_in,         // Parallel data in (from Wishbone)

    output wire [`SPI_MAX_CHAR-1:0]     p_out,        // Parallel data out (to RX regs)
    output wire                         last,         // Last bit flag
    output reg                          mosi,         // Master Out Slave In
    output reg                          tip           // Transfer in progress
);

    // Internal registers
    reg  [`SPI_CHAR_LEN_BITS:0]  char_count;
    reg  [`SPI_MAX_CHAR-1:0]     master_data;
    reg  [`SPI_CHAR_LEN_BITS:0]  tx_bit_pos;
    reg  [`SPI_CHAR_LEN_BITS:0]  rx_bit_pos;

    // Clock enables
    wire tx_clk = ((tx_negedge) ? cpol_1 : cpol_0) & ~last;
    wire rx_clk = ((rx_negedge) ? cpol_1 : cpol_0) & (~last | sclk);

    // -------------------------------------------------------
    // Transfer-in-progress (TIP) logic
    // -------------------------------------------------------
    always @(posedge wb_clk_in or posedge wb_rst) begin
        if (wb_rst)
            tip <= 1'b0;
        else if (go && ~tip)
            tip <= 1'b1;
        else if (last && tip && cpol_0)
            tip <= 1'b0;
    end

    // -------------------------------------------------------
    // Character bit counter (counts down from len to 0)
    // -------------------------------------------------------
    always @(posedge wb_clk_in or posedge wb_rst) begin
        if (wb_rst)
            char_count <= {(`SPI_CHAR_LEN_BITS+1){1'b0}};
        else if (tip) begin
            if (cpol_0)
                char_count <= char_count - 1;
        end else
            char_count <= {1'b0, len};
    end

    // last = all char_count bits are zero
    assign last = ~(|char_count);

    // -------------------------------------------------------
    // TX bit position (which bit of master_data to drive)
    // -------------------------------------------------------
    always @(*) begin
        if (lsb)
            tx_bit_pos = ({~{|len}, len} - char_count);
        else
            tx_bit_pos = char_count - 1;
    end

    // -------------------------------------------------------
    // RX bit position (where to store received MISO bit)
    // -------------------------------------------------------
    always @(*) begin
        if (lsb) begin
            if (rx_negedge)
                rx_bit_pos = {~(|len), len} - (char_count + 1);
            else
                rx_bit_pos = {~(|len), len} - char_count;
        end else begin
            if (rx_negedge)
                rx_bit_pos = char_count;
            else
                rx_bit_pos = char_count - 1;
        end
    end

    // -------------------------------------------------------
    // MOSI serial output
    // -------------------------------------------------------
    always @(posedge wb_clk_in or posedge wb_rst) begin
        if (wb_rst)
            mosi <= 1'b0;
        else if (tx_clk)
            mosi <= master_data[tx_bit_pos[`SPI_CHAR_LEN_BITS-1:0]];
    end

    // -------------------------------------------------------
    // Master data register: latch TX data or shift in MISO
    // -------------------------------------------------------
    always @(posedge wb_clk_in or posedge wb_rst) begin
        if (wb_rst) begin
            master_data <= {`SPI_MAX_CHAR{1'b0}};
        end else if (latch[0] && ~tip) begin
            if (byte_sel[0]) master_data[7:0]  <= p_in[7:0];
        end else begin
            if (rx_clk)
                master_data[rx_bit_pos[`SPI_CHAR_LEN_BITS-1:0]] <= miso;
        end
    end

    assign p_out = master_data;

endmodule
