// ============================================================
// wishbone_master.v
// Wishbone Bus Master Interface
// Author : Jay Hepat, VIT Bhopal
// Description: Implements a Wishbone rev.B1 master that drives
//              single-cycle read and write transactions to the
//              SPI core's register map. Used by the testbench
//              to configure and trigger the SPI master.
// ============================================================

module wishbone_master (
    input  wire         clk_in,   // System clock
    input  wire         rst_in,   // Synchronous reset (active high)
    input  wire         ack_in,   // Wishbone acknowledge from slave
    input  wire         err_in,   // Wishbone error (unused here)
    input  wire [31:0]  dat_in,   // Read data from slave

    output reg  [4:0]   adr_o,    // Address output
    output reg          cyc_o,    // Cycle valid
    output reg          stb_o,    // Strobe
    output reg          we_o,     // Write enable
    output reg  [31:0]  dat_o,    // Write data
    output reg  [3:0]   sel_o     // Byte select
);

    // Internal temporaries (driven by tasks)
    integer adr_temp, sel_temp, dat_temp;
    reg     we_temp, cyc_temp, stb_temp;

    // -------------------------------------------------------
    // initialize — clear all bus signals
    // -------------------------------------------------------
    task initialize;
    begin
        adr_temp = 0;
        cyc_temp = 0;
        stb_temp = 0;
        we_temp  = 0;
        dat_temp = 0;
        sel_temp = 0;
    end
    endtask

    // -------------------------------------------------------
    // single_write — perform one Wishbone write cycle
    // -------------------------------------------------------
    task single_write;
        input [4:0]  adr;
        input [31:0] dat;
        input [3:0]  sel;
    begin
        @(negedge clk_in);
        adr_temp = adr;
        sel_temp = sel;
        we_temp  = 1'b1;
        dat_temp = dat;
        cyc_temp = 1'b1;
        stb_temp = 1'b1;

        @(negedge clk_in);
        wait(~ack_in);

        @(negedge clk_in);
        adr_temp = 5'bz;
        sel_temp = 4'd0;
        we_temp  = 1'b0;
        dat_temp = 32'bz;
        cyc_temp = 1'b0;
        stb_temp = 1'b0;
    end
    endtask

    // -------------------------------------------------------
    // Register output assignments (clocked)
    // -------------------------------------------------------
    always @(posedge clk_in) adr_o <= adr_temp;
    always @(posedge clk_in) we_o  <= we_temp;
    always @(posedge clk_in) dat_o <= dat_temp;
    always @(posedge clk_in) sel_o <= sel_temp;

    always @(posedge clk_in) begin
        if (rst_in) cyc_o <= 1'b0;
        else        cyc_o <= cyc_temp;
    end

    always @(posedge clk_in) begin
        if (rst_in) stb_o <= 1'b0;
        else        stb_o <= stb_temp;
    end

endmodule
