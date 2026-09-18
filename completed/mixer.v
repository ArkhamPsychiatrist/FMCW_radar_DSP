module mixer #(
	parameter OUT_WIDTH =8
)(
	input clk,
	input rst,
	input signed [OUT_WIDTH-1:0] sin_nco,
	input signed [OUT_WIDTH-1:0] cos_nco,
	input signed [OUT_WIDTH-1:0] input_waveform,
	output reg signed [2*OUT_WIDTH-1:0] Q_out,
	output reg signed [2*OUT_WIDTH-1:0] I_out
);

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			I_out <= 0;
			Q_out <= 0;
		end else begin
			I_out <= cos_nco * input_waveform;
			Q_out <= sin_nco * input_waveform;
		end
	end
endmodule

