`timescale 1ns/1ps

// ----------------------------------------------------------------------------
// frame_capture
//
// Captures one full FFT frame (bin index, frequency, magnitude) to a text
// file. Which frame gets captured is selectable via TARGET_FRAME.
//
//   TARGET_FRAME = 0  -> first valid frame after reset (old tb.v behavior)
//   TARGET_FRAME = N  -> the (N+1)-th valid frame after reset
//
// Frame counting starts once fft_out first goes non-X (i.e. once the FFT
// pipeline has flushed its initial garbage), then increments on every
// fft_sync pulse.
// ----------------------------------------------------------------------------
module frame_capture #(
    parameter integer TARGET_FRAME = 0,
    parameter integer NFFT         = 512,
    parameter real    FS           = 100_000_000.0,   // Hz
    parameter         OUTFILE      = "fft_output.txt"
)(
    input clk,
    input rst,
    input [41:0] fft_output,
    input fft_sync
);

    localparam real DELTA_F = (FS / NFFT) / 1_000_000.0;   // MHz per bin

    integer fft_file;
    integer frame_idx;   // -1 = no valid frame seen yet
    integer bin_count;
    real    fft_real, fft_imag, fft_mag, fft_freq;
    reg     started, capturing, captured;

    initial begin
        fft_file = $fopen(OUTFILE, "w");
        if (fft_file == 0) begin
            $display("ERROR: could not open %s", OUTFILE);
            $finish;
        end
        frame_idx = -1;
        bin_count = 0;
        started   = 0;
        capturing = 0;
        captured  = 0;
    end

    // detect first valid (non-X) sample coming out of the FFT pipeline
    always @(posedge clk or posedge rst) begin
        if (rst)
            started <= 0;
        else if (!started && (^fft_output !== 1'bx))
            started <= 1;
    end

    // frame indexing + bin indexing within the current frame
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_idx <= -1;
            bin_count <= 0;
            capturing <= 0;
        end else if (started && fft_sync) begin
            frame_idx <= frame_idx + 1;
            bin_count <= 0;
            capturing <= (frame_idx + 1) == TARGET_FRAME;
        end else begin
            bin_count <= bin_count + 1;
        end
    end

    // write out every bin of the target frame, once
    always @(posedge clk) begin
        if (!rst && capturing && !captured && (^fft_output !== 1'bx)) begin
            fft_real = $signed(fft_output[41:21]);
            fft_imag = $signed(fft_output[20:0]);
            fft_mag  = $sqrt(fft_real*fft_real + fft_imag*fft_imag);
            fft_freq = bin_count * DELTA_F;
            $fwrite(fft_file, "%0d %f %f\n", bin_count, fft_freq, fft_mag);
        end
    end

    // mark done once the target frame has fully streamed through
    always @(posedge clk or posedge rst) begin
        if (rst)
            captured <= 0;
        else if (fft_sync && capturing && bin_count > 0)
            captured <= 1;
    end

endmodule
