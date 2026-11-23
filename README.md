# 512-bit SRAM Array

A USC EE 577a team project that takes a transistor-level SRAM from schematic design through physical layout and parasitic-extracted simulation in 45 nm CMOS.

## Architecture

The array stores **32 words × 16 bits** in an **8-row × 64-column** grid of 6T bitcells. The upper three address bits select one of eight wordlines; the lower two drive a one-hot column decoder and 4:1 column selection. Each word draws four bits from each of four 128-bit banks. On a read, the array precharges the differential bitlines, lets the selected bitcell develop a voltage difference, and senses and latches the result. Write drivers drive the selected bitline pairs.

<img width="1382" height="801" alt="512-bit SRAM architecture: four banks, row decoder, column mux, and read/write circuitry" src="https://github.com/user-attachments/assets/52c23b73-0419-4b7f-a063-c9b0b1fb7c2a" />

*Architecture reference: USC EE 577a Lab4A handout, Figure 1.*

## Design and verification

- **Lab4A: Schematic design.** Used a loaded single-bit testbench to sequence precharge, write, and sense controls before integrating the full array. Directed full-array schematic read/write tests ran in simulation at **1 GHz**.
- **Lab4B: Physical layout.** Built abuttable bitcells and aligned the precharge, wordline-enable, and column-mux interfaces to the array pitch. Checked the 2 × 4 test structure and full array with DRC and LVS. The flow used Cadence Virtuoso, Spectre, Quantus extraction, and course-supplied SKILL automation.
- **Post-layout results.** Ran directed extracted read/write tests at **500 MHz**. The extracted read timing gave an estimated **1.046 ns minimum period (~956 MHz)** at 50% duty cycle. The extracted multiword test did not fully match expected outputs, so the estimate is not a verified operating limit or a silicon measurement.

## Explore the design

| Path | What's inside |
| --- | --- |
| [6T bitcell](EE577a_SRAM/SRAM_1bit) | Transistor-level schematic and physical layout |
| [4:1 column mux](EE577a_SRAM/ColumnMUX_4to1) | Pitch-matched column selection schematic and layout |
| [Integrated SRAM](EE577a_SRAM/SRAM_512b_cell) | Full-array schematic and layout; see the separate [array testbench](EE577a_SRAM/SRAM_512b_TB) for stimulus and observation setup |
| [Single-bit stimulus](Lab4A/SRAM_1bit.vec), [schematic functional stimulus](Lab4A/SRAM_512bit.vec), and [extracted functional stimulus](Lab4B/SRAM_512b_function_og.vec) | Example Cadence simulation vectors |
| [Supporting digital library](EE577a_S26) | Selected digital cells and testbenches |

The functional vectors use fixed synthetic addresses and data. Static checks cover vector formatting, timing/control fields, and expected reads; the revised vectors have not been rerun in Cadence.

This is a portfolio snapshot, not a standalone build. The design views use Cadence OpenAccess. Team reports, course-provided SKILL scripts, and generated extraction and simulation outputs are not included. Re-running the design requires the course technology setup and omitted dependencies.
