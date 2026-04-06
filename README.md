# SPI Master Core Design in Verilog

A complete SPI (Serial Peripheral Interface) Master Core implemented in Verilog HDL, featuring a WISHBONE rev.B1 bus interface, programmable clock divider, and support for all four SPI communication modes.

**Author:** Jay Hepat | VIT Bhopal University  
**Domain:** VLSI | Digital Design | RTL Design  
**Tools:** Quartus Prime | ModelSim / Icarus Verilog | GTKWave

---

## Project Overview

This project implements a fully functional SPI Master Core that communicates with slave peripherals using the four standard SPI signals: MOSI, MISO, SCLK, and SS. The core is accessed by a host processor through a WISHBONE bus interface and supports configurable data width, clock polarity, and bit ordering.

## Architecture

```
 ┌─────────────────────────────────────────────┐
 │              spi_top.v (Top Module)          │
 │  ┌──────────────┐   ┌─────────────────────┐ │
 │  │  spi_clgen.v │   │  spi_shift_reg.v    │ │
 │  │ Clock Gen    │──▶│  Shift Register     │ │
 │  └──────────────┘   └─────────────────────┘ │
 └────────────────────┬────────────────────────┘
          WISHBONE    │         SPI Bus
    ◀─────────────────┤──────────────────▶
   wishbone_master.v  │      spi_slave.v
                      │
              MOSI / MISO / SCLK / SS
```

## Features

- Full-duplex synchronous serial data transfer
- Programmable character length: 8 to 128 bits
- MSB or LSB first data transfer
- Independent TX/RX clock edge selection (all 4 SPI modes)
- Up to 8 slave select lines (configurable up to 32)
- Auto Slave Select mode
- Interrupt on transfer complete
- WISHBONE rev.B1 compatible interface

## Repository Structure

```
SPI_Design/
├── rtl/
│   ├── spi_defines.v       # Global parameters and macros
│   ├── spi_clgen.v         # Clock generator module
│   ├── spi_shift_reg.v     # Shift register module
│   ├── spi_top.v           # Top-level SPI master core
│   ├── spi_slave.v         # SPI slave (for simulation)
│   └── wishbone_master.v   # Wishbone bus master
├── tb/
│   └── tb.v                # Top-level testbench (all 4 modes)
├── sim/                    # VCD waveform outputs
└── README.md
```

## SPI Modes Tested

| Mode | TX_NEG | RX_NEG | LSB | Description |
|------|--------|--------|-----|-------------|
| 1 | 0 | 1 | 1 | Drive on rising, sample on falling, LSB first |
| 2 | 0 | 1 | 0 | Drive on rising, sample on falling, MSB first |
| 3 | 1 | 0 | 1 | Drive on falling, sample on rising, LSB first |
| 4 | 1 | 0 | 0 | Drive on falling, sample on rising, MSB first |

## Register Map

| Register | Address | Access | Description |
|----------|---------|--------|-------------|
| Rx0–Rx3  | 0x00–0x0C | R | Receive data registers |
| Tx0–Tx3  | 0x00–0x0C | R/W | Transmit data registers |
| CTRL     | 0x10 | R/W | Control and status register |
| DIVIDER  | 0x14 | R/W | Clock divider register |
| SS       | 0x18 | R/W | Slave select register |

## Running Simulation (Icarus Verilog)

```bash
# Compile
iverilog -o sim/spi_sim \
  rtl/spi_defines.v rtl/spi_clgen.v rtl/spi_shift_reg.v \
  rtl/spi_top.v rtl/spi_slave.v rtl/wishbone_master.v \
  tb/tb.v

# Run
vvp sim/spi_sim

# View waveforms
gtkwave sim/spi_tb.vcd
```

## Tools Used

- **Quartus Prime** — Synthesis and FPGA implementation
- **ModelSim / Icarus Verilog** — RTL simulation
- **GTKWave** — Waveform analysis
- **Verilog HDL** — Hardware description language
