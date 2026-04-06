// ============================================================
// tb.v
// Top-Level Testbench — SPI Master Core
// Author : Jay Hepat, VIT Bhopal
// Description: Verifies all four SPI operating modes by
//              connecting wishbone_master → spi_top → spi_slave.
//              Tests vary TX_NEG, RX_NEG, LSB, and CHAR_LEN
//              settings through the CTRL register.
//
// Test Configurations:
//   Mode 1: TX_NEG=0, RX_NEG=1, LSB=1, CHAR_LEN=4  (Mode 0 equiv.)
//   Mode 2: TX_NEG=0, RX_NEG=1, LSB=0, CHAR_LEN=4
//   Mode 3: TX_NEG=1, RX_NEG=0, LSB=1, CHAR_LEN=4  (Mode 1 equiv.)
//   Mode 4: TX_NEG=1, RX_NEG=0, LSB=0, CHAR_LEN=4
// ============================================================

`include "spi_defines.v"
`timescale 1ns/1ps

module tb;

    // -------------------------------------------------------
    // DUT signal declarations
    // -------------------------------------------------------
    reg  wb_clk_in, wb_rst_in;
    wire wb_we_in, wb_stb_in, wb_cyc_in, miso;
    wire [4:0]  wb_adr_in;
    wire [31:0] wb_dat_in;
    wire [3:0]  wb_sel_in;
    wire [31:0] wb_dat_o;
    wire        wb_ack_out, wb_int_o, sclk_out, mosi;
    wire [`SPI_SS_NB-1:0] ss_pad_o;
    wire        wb_err_in;
    assign      wb_err_in = 1'b0;

    parameter T = 20; // 50 MHz system clock

    // -------------------------------------------------------
    // Module instantiations
    // -------------------------------------------------------
    wishbone_master MASTER (
        .clk_in (wb_clk_in),
        .rst_in (wb_rst_in),
        .ack_in (wb_ack_out),
        .err_in (wb_err_in),
        .dat_in (wb_dat_o),
        .adr_o  (wb_adr_in),
        .cyc_o  (wb_cyc_in),
        .stb_o  (wb_stb_in),
        .we_o   (wb_we_in),
        .dat_o  (wb_dat_in),
        .sel_o  (wb_sel_in)
    );

    spi_top SPI_CORE (
        .wb_clk_in  (wb_clk_in),
        .wb_rst_in  (wb_rst_in),
        .wb_adr_in  (wb_adr_in),
        .wb_dat_in  (wb_dat_in),
        .wb_sel_in  (wb_sel_in),
        .wb_we_in   (wb_we_in),
        .wb_stb_in  (wb_stb_in),
        .wb_cyc_in  (wb_cyc_in),
        .wb_dat_o   (wb_dat_o),
        .wb_ack_out (wb_ack_out),
        .wb_int_o   (wb_int_o),
        .miso       (miso),
        .mosi       (mosi),
        .sclk_out   (sclk_out),
        .ss_pad_o   (ss_pad_o)
    );

    spi_slave SLAVE (
        .sclk     (sclk_out),
        .mosi     (mosi),
        .ss_pad_o (ss_pad_o),
        .miso     (miso)
    );

    // -------------------------------------------------------
    // Clock generation: 50 MHz
    // -------------------------------------------------------
    initial begin
        wb_clk_in = 1'b0;
        forever #(T/2) wb_clk_in = ~wb_clk_in;
    end

    // -------------------------------------------------------
    // Reset task
    // -------------------------------------------------------
    task rst;
    begin
        wb_rst_in = 1'b1;
        #13;
        wb_rst_in = 1'b0;
    end
    endtask

    // -------------------------------------------------------
    // MODE 1: TX_NEG=0, RX_NEG=1, LSB=1, CHAR_LEN=4
    // CTRL[13:8] = 6'b00_1010 = 0x3A  → with GO: 0x3B
    // -------------------------------------------------------
    initial begin
        $display("=== Mode 1: TX_NEG=0 RX_NEG=1 LSB=1 CHAR_LEN=4 ===");
        rst;
        MASTER.initialize;
        // Configure CTRL (GO=0)
        MASTER.single_write(5'h10, 32'h0000_3A04, 4'b1111);
        // Configure DIVIDER
        MASTER.single_write(5'h14, 32'h0000_0004, 4'b1111);
        // Configure SS (select slave 0)
        MASTER.single_write(5'h18, 32'h0000_0001, 4'b1111);
        // Load TX data
        MASTER.single_write(5'h00, 32'h0000_236f, 4'b1111);
        // Assert GO
        MASTER.single_write(5'h10, 32'h0000_3B04, 4'b1111);
        repeat(100) @(negedge wb_clk_in);
        $display("Mode 1 complete. MOSI=%b SCLK=%b SS=%b", mosi, sclk_out, ss_pad_o);
        $finish;
    end

    // -------------------------------------------------------
    // MODE 2: TX_NEG=0, RX_NEG=1, LSB=0, CHAR_LEN=4
    // CTRL = 0x3204 → GO: 0x3304
    // -------------------------------------------------------
    /*
    initial begin
        $display("=== Mode 2: TX_NEG=0 RX_NEG=1 LSB=0 CHAR_LEN=4 ===");
        rst;
        MASTER.initialize;
        MASTER.single_write(5'h10, 32'h0000_3204, 4'b1111);
        MASTER.single_write(5'h14, 32'h0000_0002, 4'b1111);
        MASTER.single_write(5'h18, 32'h0000_0001, 4'b1111);
        MASTER.single_write(5'h00, 32'h0000_236f, 4'b1111);
        MASTER.single_write(5'h10, 32'h0000_3304, 4'b1111);
        repeat(100) @(negedge wb_clk_in);
        $finish;
    end
    */

    // -------------------------------------------------------
    // MODE 3: TX_NEG=1, RX_NEG=0, LSB=1, CHAR_LEN=4
    // CTRL = 0x3C04 → GO: 0x3D04
    // -------------------------------------------------------
    /*
    initial begin
        $display("=== Mode 3: TX_NEG=1 RX_NEG=0 LSB=1 CHAR_LEN=4 ===");
        rst;
        MASTER.initialize;
        MASTER.single_write(5'h10, 32'h0000_3C04, 4'b1111);
        MASTER.single_write(5'h14, 32'h0000_0004, 4'b1111);
        MASTER.single_write(5'h18, 32'h0000_0001, 4'b1111);
        MASTER.single_write(5'h00, 32'h0000_236f, 4'b1111);
        MASTER.single_write(5'h10, 32'h0000_3D04, 4'b1111);
        repeat(100) @(negedge wb_clk_in);
        $finish;
    end
    */

    // -------------------------------------------------------
    // MODE 4: TX_NEG=1, RX_NEG=0, LSB=0, CHAR_LEN=4
    // CTRL = 0x3404 → GO: 0x3504
    // -------------------------------------------------------
    /*
    initial begin
        $display("=== Mode 4: TX_NEG=1 RX_NEG=0 LSB=0 CHAR_LEN=4 ===");
        rst;
        MASTER.initialize;
        MASTER.single_write(5'h10, 32'h0000_3404, 4'b1111);
        MASTER.single_write(5'h14, 32'h0000_0004, 4'b1111);
        MASTER.single_write(5'h18, 32'h0000_0001, 4'b1111);
        MASTER.single_write(5'h00, 32'h0000_236f, 4'b1111);
        MASTER.single_write(5'h10, 32'h0000_3504, 4'b1111);
        repeat(100) @(negedge wb_clk_in);
        $finish;
    end
    */

    // -------------------------------------------------------
    // VCD dump for waveform viewing in GTKWave
    // -------------------------------------------------------
    initial begin
        $dumpfile("sim/spi_tb.vcd");
        $dumpvars(0, tb);
    end

endmodule
