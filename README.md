# FMCW_radar_DSP

An in-progress FMCW radar system. This repository contains the digital signal processing side, written in Verilog and implemented on a DE1-SoC FPGA board.

## Repository contents

- `completed/`: Verilog modules and files for running the simulation with Icarus Verilog and GTKWave
- `lite_first.sof`: FPGA configuration file for the DE1-SoC board, used to run real-time FFT

## Digital side: completed/

Modules: `mixer`, `NCO`, `FIR_filter`, `peak_detector`, `FFT_frameCapture`, integrated with an open-source FFT module "https://github.com/ZipCPU/dblclockfft".

- Simulated with Icarus Verilog
- Verified with GTKWave and MATLAB
- Real-time FFT implemented on a DE1-SoC FPGA board

## Running on hardware: lite_first.sof

Program `lite_first.sof` onto the DE1-SoC over JTAG using Quartus Programmer. The configuration is stored in SRAM, so it must be reloaded after each power cycle.

## Analog side

Researching RF front-end architecture (mixer, LNA, PA selection) for 24 GHz operation.

## Status

Ongoing personal project (July 2026 to present).
