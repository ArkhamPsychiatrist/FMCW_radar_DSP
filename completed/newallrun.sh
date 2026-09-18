#!/bin/bash
iverilog -g2012 improvedFIR.v nco.v mixer.v tb.v fft/fftmain.v peak_detector.v frame_capture.v -y ~/verilogSIM/chirp_nco/fft
vvp a.out
gtkwave tb.vcd

