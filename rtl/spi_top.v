// ============================================================
// spi_top.v
// SPI Master Core — Top-Level Module
// Author : Jay Hepat, VIT Bhopal
// Description: Integrates the clock generator (spi_clgen) and
//              shift register (spi_shift_reg) into a complete
//              SPI Master Core with a WISHBONE rev.B1 interface.
//              Supports up to 32 slave devices, interrupt
//              generation, and all four SPI modes.
// ============================================================

`include "spi_defines.v"

module spi_top (
    // --- Wishbone Interface ---
    input  wire                       wb_clk_in,   // Master clock
    input  wire                       wb_rst_in,   // Synchronous reset (active high)
    input  wire [4:0]                 wb_adr_in,   // Address bus (lower 5 bits)
    input  wire [31:0]                wb_dat_in,   // Data input to core
    input  wire [3:0]                 wb_sel_in,   // Byte select
    input  wire                       wb_we_in,    // Write enable
    input  wire                       wb_stb_in,   // Strobe / core select
    input  wire                       wb_cyc_in,   // Valid bus cycle

    output reg  [31:0]                wb_dat_o,    // Data output from core
    output reg                        wb_ack_out,  // Bus cycle acknowledge
    output reg                        wb_int_o,    // Interrupt output

    // --- SPI External Connections ---
    input  wire                       miso,        // Master In Slave Out
    output wire                       mosi,        // Master Out Slave In
    output wire                       sclk_out,    // Serial clock
    output wire [`SPI_SS_NB-1:0]      ss_pad_o     // Slave select (active low)
);

    // -------------------------------------------------------
    // Internal signals
    // -------------------------------------------------------
    wire                          rx_negedge;
    wire                          tx_negedge;
    wire [3:0]                    spi_tx_sel;
    wire [`SPI_CHAR_LEN_BITS-1:0] char_len;
    wire                          go, ie, ass, lsb;
    wire                          cpol_0, cpol_1, last, tip;
    wire [`SPI_MAX_CHAR-1:0]      rx;

    wire spi_divider_sel = wb_cyc_in & wb_stb_in & (wb_adr_in == `SPI_DIVIDE);
    wire spi_ctrl_sel    = wb_cyc_in & wb_stb_in & (wb_adr_in == `SPI_CTRL);
    wire spi_ss_sel      = wb_cyc_in & wb_stb_in & (wb_adr_in == `SPI_SS);

    assign spi_tx_sel[0] = wb_cyc_in & wb_stb_in & (wb_adr_in == `SPI_TX_0);
    assign spi_tx_sel[1] = wb_cyc_in & wb_stb_in & (wb_adr_in == `SPI_TX_1);
    assign spi_tx_sel[2] = wb_cyc_in & wb_stb_in & (wb_adr_in == `SPI_TX_2);
    assign spi_tx_sel[3] = wb_cyc_in & wb_stb_in & (wb_adr_in == `SPI_TX_3);

    reg [`SPI_DIVIDER_LEN-1:0]   divider;
    reg [`SPI_CTRL_BIT_NB-1:0]   ctrl;
    reg [`SPI_SS_NB-1:0]         ss;
    reg [31:0]                   wb_temp_dat;

    // -------------------------------------------------------
    // Sub-module: Clock Generator
    // -------------------------------------------------------
    spi_clgen SC (
        .wb_clk_in (wb_clk_in),
        .wb_rst    (wb_rst_in),
        .go        (go),
        .tip       (tip),
        .last_clk  (last),
        .divider   (divider),
        .sclk_out  (sclk_out),
        .cpol_0    (cpol_0),
        .cpol_1    (cpol_1)
    );

    // -------------------------------------------------------
    // Sub-module: Shift Register
    // -------------------------------------------------------
    spi_shift_reg SR (
        .wb_clk_in  (wb_clk_in),
        .wb_rst     (wb_rst_in),
        .go         (go),
        .miso       (miso),
        .lsb        (lsb),
        .sclk       (sclk_out),
        .cpol_0     (cpol_0),
        .cpol_1     (cpol_1),
        .rx_negedge (rx_negedge),
        .tx_negedge (tx_negedge),
        .byte_sel   (wb_sel_in),
        .latch      (spi_tx_sel[3:0] & {4{wb_we_in}}),
        .len        (char_len),
        .p_in       (wb_dat_in),
        .p_out      (rx),
        .last       (last),
        .mosi       (mosi),
        .tip        (tip)
    );

    // -------------------------------------------------------
    // Address decoder — combinational read mux
    // -------------------------------------------------------
    always @(*) begin
        case (wb_adr_in)
            `SPI_RX_0 : wb_temp_dat = rx[31:0];
            `SPI_RX_1 : wb_temp_dat = 32'b0;
            `SPI_RX_2 : wb_temp_dat = 32'b0;
            `SPI_RX_3 : wb_temp_dat = 32'b0;
            `SPI_CTRL : wb_temp_dat = {{(32-`SPI_CTRL_BIT_NB){1'b0}}, ctrl};
            `SPI_DIVIDE : wb_temp_dat = {{(32-`SPI_DIVIDER_LEN){1'b0}}, divider};
            `SPI_SS   : wb_temp_dat = {{(32-`SPI_SS_NB){1'b0}}, ss};
            default   : wb_temp_dat = 32'hx;
        endcase
    end

    // -------------------------------------------------------
    // Wishbone data output register
    // -------------------------------------------------------
    always @(posedge wb_clk_in or posedge wb_rst_in) begin
        if (wb_rst_in) wb_dat_o <= 32'd0;
        else           wb_dat_o <= wb_temp_dat;
    end

    // -------------------------------------------------------
    // Wishbone acknowledge
    // -------------------------------------------------------
    always @(posedge wb_clk_in or posedge wb_rst_in) begin
        if (wb_rst_in) wb_ack_out <= 1'b0;
        else           wb_ack_out <= wb_cyc_in & wb_stb_in & ~wb_ack_out;
    end

    // -------------------------------------------------------
    // Interrupt generation
    // -------------------------------------------------------
    always @(posedge wb_clk_in or posedge wb_rst_in) begin
        if (wb_rst_in)                        wb_int_o <= 1'b0;
        else if (ie && tip && last && cpol_0) wb_int_o <= 1'b1;
        else if (wb_ack_out)                  wb_int_o <= 1'b0;
    end

    // -------------------------------------------------------
    // Slave select output (active low, auto or manual)
    // -------------------------------------------------------
    assign ss_pad_o = ~((ss & {`SPI_SS_NB{tip & ass}}) |
                        (ss & {`SPI_SS_NB{~ass}}));

    // -------------------------------------------------------
    // Divider register write
    // -------------------------------------------------------
    always @(posedge wb_clk_in or posedge wb_rst_in) begin
        if (wb_rst_in) begin
            divider <= {`SPI_DIVIDER_LEN{1'b0}};
        end else if (spi_divider_sel && wb_we_in && !tip) begin
            if (wb_sel_in[0]) divider[7:0]  <= wb_dat_in[7:0];
`ifdef SPI_DIVIDER_LEN_16
            if (wb_sel_in[1]) divider[15:8] <= wb_dat_in[15:8];
`endif
        end
    end

    // -------------------------------------------------------
    // Control register write
    // -------------------------------------------------------
    always @(posedge wb_clk_in or posedge wb_rst_in) begin
        if (wb_rst_in) begin
            ctrl <= {`SPI_CTRL_BIT_NB{1'b0}};
        end else if (spi_ctrl_sel && wb_we_in && !tip) begin
            if (wb_sel_in[0])
                ctrl[7:0] <= wb_dat_in[7:0] | {7'd0, ctrl[0]};
            if (wb_sel_in[1])
                ctrl[`SPI_CTRL_BIT_NB-1:8] <= wb_dat_in[`SPI_CTRL_BIT_NB-1:8];
        end else if (tip && last && cpol_0)
            ctrl[`SPI_CTRL_GO] <= 1'b0;
    end

    // Control register field decode
    assign rx_negedge = ctrl[`SPI_CTRL_RX_NEGEDGE];
    assign tx_negedge = ctrl[`SPI_CTRL_TX_NEGEDGE];
    assign lsb        = ctrl[`SPI_CTRL_LSB];
    assign ie         = ctrl[`SPI_CTRL_IE];
    assign ass        = ctrl[`SPI_CTRL_ASS];
    assign go         = ctrl[`SPI_CTRL_GO];
    assign char_len   = ctrl[`SPI_CTRL_CHAR_LEN];

    // -------------------------------------------------------
    // Slave select register write
    // -------------------------------------------------------
    always @(posedge wb_clk_in or posedge wb_rst_in) begin
        if (wb_rst_in) begin
            ss <= {`SPI_SS_NB{1'b0}};
        end else if (spi_ss_sel && wb_we_in && !tip) begin
            if (wb_sel_in[0]) ss[7:0] <= wb_dat_in[7:0];
        end
    end

endmodule
