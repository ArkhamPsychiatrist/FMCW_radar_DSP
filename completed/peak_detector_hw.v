// peak_detector_hw.v
//
// Synthesizable replacement for peak_detector.v (which uses $fopen/$fwrite/
// $sqrt/real and is simulation-only). Tracks the running argmax of |X[k]|^2
// over bins 0..NFFT/2 of each FFT frame (squared magnitude preserves the
// same argmax as magnitude, so no sqrt is needed), and reports the peak
// bin + frequency once per completed frame.
//
// fft_result format matches fftmain.v's o_result: {real[20:0], imag[20:0]}.
// fft_sync marks the first output sample of a new frame (same timing as
// fftmain's o_sync). i_ce must be asserted on the same cycles you're
// feeding fftmain, since fftmain only advances state on i_ce.

module peak_detector_hw #(
    parameter integer NFFT         = 512,
    parameter integer LGNFFT       = 9,
    parameter integer FREQ_STEP_HZ = 976   // Hz per bin = FS_HZ / NFFT; set from your actual sample rate
) (
    input  wire               clk,
    input  wire               rst,
    input  wire               i_ce,
    input  wire [41:0]        fft_result,
    input  wire               fft_sync,

    output reg  [LGNFFT-1:0]  o_peak_bin,
    output reg  [31:0]        o_peak_freq_hz,
    output reg                o_peak_valid   // one-cycle pulse when a new frame's peak is ready
);

    wire signed [20:0] s_real = fft_result[41:21];
    wire signed [20:0] s_imag = fft_result[20:0];

    wire signed [41:0] real_sq = s_real * s_real;
    wire signed [41:0] imag_sq = s_imag * s_imag;
    wire        [42:0] mag_sq  = real_sq + imag_sq;

    reg                  started;
    reg [LGNFFT-1:0]     bin_count;
    reg [LGNFFT-1:0]     peak_bin;
    reg [42:0]           peak_mag;

    // latch that we've seen the first frame boundary
    always @(posedge clk) begin
        if (rst)
            started <= 1'b0;
        else if (i_ce && fft_sync)
            started <= 1'b1;
    end

    // which bin index corresponds to fft_result this cycle
    always @(posedge clk) begin
        if (rst)
            bin_count <= {LGNFFT{1'b0}};
        else if (i_ce) begin
            if (fft_sync)
                bin_count <= {LGNFFT{1'b0}};
            else if (started)
                bin_count <= bin_count + 1'b1;
        end
    end

    // running argmax over bins 0..NFFT/2, reset every frame
    always @(posedge clk) begin
        if (rst) begin
            peak_mag <= 43'd0;
            peak_bin <= {LGNFFT{1'b0}};
        end else if (i_ce) begin
            if (fft_sync) begin
                peak_mag <= 43'd0;
                peak_bin <= {LGNFFT{1'b0}};
            end else if (started && (bin_count <= (NFFT/2))) begin
                if (mag_sq > peak_mag) begin
                    peak_mag <= mag_sq;
                    peak_bin <= bin_count;
                end
            end
        end
    end

    // report the just-finished frame's peak when the next fft_sync arrives
    always @(posedge clk) begin
        if (rst) begin
            o_peak_valid <= 1'b0;
        end else if (i_ce && fft_sync && started && (bin_count != {LGNFFT{1'b0}})) begin
            o_peak_bin     <= peak_bin;
            o_peak_freq_hz <= peak_bin * FREQ_STEP_HZ;
            o_peak_valid   <= 1'b1;
        end else begin
            o_peak_valid <= 1'b0;
        end
    end

endmodule
