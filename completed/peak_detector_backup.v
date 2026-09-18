module peak_detector (
    input clk,
    input rst,
    input [41:0] fft_output,
    input fft_sync
);

    localparam real FS      = 100_000_000.0;              // Hz
    localparam real NFFT    = 512.0;
    localparam real DELTA_F = (FS / NFFT) / 1_000_000.0;   // MHz per bin

    integer fft_file;
    integer frame_number;

    reg started;
    reg [8:0] bin_count;   // 0-511
    reg [8:0] peak_bin;

    real fft_real, fft_imag, fft_mag;
    real max_current;
    real peak_freq;

    initial begin
        fft_file = $fopen("fft_peaks.txt", "w");
        if (fft_file == 0) begin
            $display("ERROR: could not open fft_peaks.txt");
            $finish;
        end
        frame_number = 0;
        started      = 0;
        bin_count    = 0;
        max_current  = 0.0;
        peak_bin     = 0;
    end

    // latch that we've seen the first frame boundary
    always @(posedge clk or posedge rst) begin
        if (rst)
            started <= 0;
        else if (fft_sync)
            started <= 1;
    end

    // which bin index is on fft_output this cycle
    always @(posedge clk or posedge rst) begin
        if (rst)
            bin_count <= 0;
        else if (fft_sync)
            bin_count <= 0;
        else if (started)
            bin_count <= bin_count + 1;
    end

    // decode + magnitude, combinational off the current sample
    always @(*) begin
        fft_real = $itor($signed(fft_output[41:21]));
        fft_imag = $itor($signed(fft_output[20:0]));
        fft_mag  = $sqrt(fft_real*fft_real + fft_imag*fft_imag);
    end

    // running argmax, reset every frame
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            max_current <= 0.0;
            peak_bin    <= 0;
        end else if (fft_sync) begin
            max_current <= 0.0;
            peak_bin    <= 0;
        end else if (started && (bin_count<=(NFFT/2))) begin
            if (fft_mag > max_current) begin
                max_current <= fft_mag;
                peak_bin    <= bin_count;
            end
        end
    end

    // report the just-finished frame's peak when the next fft_sync arrives
    always @(posedge clk) begin
        if (fft_sync && started && bin_count > 0) begin
            frame_number = frame_number + 1;
            peak_freq    = peak_bin * DELTA_F;
            $fwrite(fft_file, "%0d %0d %f %f\n", frame_number, peak_bin, peak_freq, max_current);
        end
    end

endmodule
