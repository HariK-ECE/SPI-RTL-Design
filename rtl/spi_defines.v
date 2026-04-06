// ============================================================
// spi_defines.v
// SPI Master Core — Global Definitions & Parameters
// Author : Jay Hepat, VIT Bhopal
// Description: Macro definitions for clock divider length,
//              max character length, slave select count,
//              register offsets, and control register bits.
// ============================================================

// --- Clock Generator Divider Length ---
// Uncomment ONE of the following:
`define SPI_DIVIDER_LEN_8
//`define SPI_DIVIDER_LEN_16
//`define SPI_DIVIDER_LEN_24
//`define SPI_DIVIDER_LEN_32

`ifdef SPI_DIVIDER_LEN_8
  `define SPI_DIVIDER_LEN 8
`endif
`ifdef SPI_DIVIDER_LEN_16
  `define SPI_DIVIDER_LEN 16
`endif
`ifdef SPI_DIVIDER_LEN_24
  `define SPI_DIVIDER_LEN 24
`endif
`ifdef SPI_DIVIDER_LEN_32
  `define SPI_DIVIDER_LEN 32
`endif

// --- Max Number of Bits per Transfer ---
// Uncomment ONE of the following:
`define SPI_MAX_CHAR_8
//`define SPI_MAX_CHAR_16
//`define SPI_MAX_CHAR_32
//`define SPI_MAX_CHAR_64
//`define SPI_MAX_CHAR_128

`ifdef SPI_MAX_CHAR_8
  `define SPI_MAX_CHAR     8
  `define SPI_CHAR_LEN_BITS 3
`endif
`ifdef SPI_MAX_CHAR_16
  `define SPI_MAX_CHAR     16
  `define SPI_CHAR_LEN_BITS 4
`endif
`ifdef SPI_MAX_CHAR_32
  `define SPI_MAX_CHAR     32
  `define SPI_CHAR_LEN_BITS 5
`endif
`ifdef SPI_MAX_CHAR_64
  `define SPI_MAX_CHAR     64
  `define SPI_CHAR_LEN_BITS 6
`endif
`ifdef SPI_MAX_CHAR_128
  `define SPI_MAX_CHAR     128
  `define SPI_CHAR_LEN_BITS 7
`endif

// --- Number of Slave Select Lines ---
// Uncomment ONE of the following:
`define SPI_SS_NB_8
//`define SPI_SS_NB_16
//`define SPI_SS_NB_24
//`define SPI_SS_NB_32

`ifdef SPI_SS_NB_8
  `define SPI_SS_NB 8
`endif
`ifdef SPI_SS_NB_16
  `define SPI_SS_NB 16
`endif
`ifdef SPI_SS_NB_24
  `define SPI_SS_NB 24
`endif
`ifdef SPI_SS_NB_32
  `define SPI_SS_NB 32
`endif

// --- Register Offsets (5-bit Wishbone Address) ---
`define SPI_RX_0    5'b00000   // Receive  register 0 (address 0x00)
`define SPI_RX_1    5'b00100   // Receive  register 1 (address 0x04)
`define SPI_RX_2    5'b01000   // Receive  register 2 (address 0x08)
`define SPI_RX_3    5'b01100   // Receive  register 3 (address 0x0C)
`define SPI_TX_0    5'b00000   // Transmit register 0 (address 0x00, shared with RX)
`define SPI_TX_1    5'b00100   // Transmit register 1
`define SPI_TX_2    5'b01000   // Transmit register 2
`define SPI_TX_3    5'b01100   // Transmit register 3
`define SPI_CTRL    5'b10000   // Control & Status register (address 0x10)
`define SPI_DIVIDE  5'b10100   // Clock Divider register   (address 0x14)
`define SPI_SS      5'b11000   // Slave Select register    (address 0x18)

// --- Control Register Width & Bit Positions ---
`define SPI_CTRL_BIT_NB   14

`define SPI_CTRL_ASS      13   // Auto Slave Select
`define SPI_CTRL_IE       12   // Interrupt Enable
`define SPI_CTRL_LSB      11   // LSB First
`define SPI_CTRL_TX_NEGEDGE 10 // Drive MOSI on falling edge
`define SPI_CTRL_RX_NEGEDGE  9 // Sample MISO on falling edge
`define SPI_CTRL_GO        8   // GO / BUSY bit
`define SPI_CTRL_CHAR_LEN  6:0 // Character length [6:0]
