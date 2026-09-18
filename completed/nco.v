module nco #(
    parameter PHASE_WIDTH = 16,
    parameter OUT_WIDTH = 8
)(
    input clk,
    input rst,
    input [PHASE_WIDTH-1:0] initial_phase_inc, //assigned in testbench
    input [PHASE_WIDTH-1:0] stop_phase_inc,
    input [PHASE_WIDTH-1:0] chirp_rate, //assigned in testbench 
    input chirp_en,
    output signed [OUT_WIDTH-1:0] sin_out,
    output signed [OUT_WIDTH-1:0] cos_out
);

reg [PHASE_WIDTH-1:0] phase_acc;
reg [PHASE_WIDTH-1:0] phase_inc;
reg signed [OUT_WIDTH-1:0] sin_lut [0:255];
reg signed [OUT_WIDTH-1:0] cos_lut [0:255];

// one sine period is divided by 256, stored in sine LUT
integer i;
initial begin
    for (i = 0; i < 256; i = i + 1)
        sin_lut[i] = $rtoi(127.0 * $sin(2.0 * 3.14159 * i / 256.0));
    for (i = 0; i < 256; i = i + 1)
        cos_lut[i] = $rtoi(127.0 * $cos(2.0 * 3.14159 * i / 256.0));
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        phase_acc <= 0;
	phase_inc <= initial_phase_inc;
    end else begin
	if (chirp_en) begin
	    if (phase_inc >= stop_phase_inc)
		phase_inc <= initial_phase_inc;
	    else
                phase_inc <= phase_inc + chirp_rate;
        end
        phase_acc <= phase_acc + phase_inc;
    end
end

// Only the upper 8 bits are used, while we have 16 bits. Finer control. 
assign sin_out = sin_lut[phase_acc[PHASE_WIDTH-1 -: OUT_WIDTH]];
assign cos_out = cos_lut[phase_acc[PHASE_WIDTH-1 -: OUT_WIDTH]];

endmodule


