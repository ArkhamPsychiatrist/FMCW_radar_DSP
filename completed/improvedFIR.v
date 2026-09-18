module improved_fir (
	input rst,
	input clk,
	input signed [15:0] data_in,
	output signed [31:0] filtered_out
);

	//fc: cutoff frequency
	parameter fc = 25000000;
	
	// N: filter length
	parameter N = 1001;

	// scale
	parameter SCALE = 1048579;

	// h(d): impulse response
	reg signed [31:0] hd [N-1:0];

	// window function
	reg signed [31:0] w [N-1:0];

	// h = hd * w
	reg signed [31:0] h [N-1:0];

	// reg to store results. Use this to assign to output wire filtered_out
	reg signed [15:0] filtered;

	real fc_norm;

	reg signed [63:0] acc;

	integer i;
	
	// to store N number of previous input data
	reg signed [15:0] buffer [N-1:0];

	// count number of values in the buffer
	reg [31:0] counter;

	initial begin 
		
		// fc_norm =  fc/fs. fs is sampling frequency.
		fc_norm = fc/100_000_000.0;

		// hd initialization
		hd[500] = $rtoi(2*fc_norm*SCALE);
                for (i=501; i<N;i=i+1) begin
                        hd[i] = $rtoi(2*fc_norm* $sin((i-500)*2*3.14159*fc_norm)/((i-500)*2*3.14159*fc_norm)*SCALE);
                        hd[1000-i] = hd[i];		//symmetric
                end
		
		// window function initialization
		for (i=0; i<N;i=i+1) begin
                        w[i] = 1;
                end

		// h initialization
		for (i=0; i<N;i=i+1) begin
                        h[i] = hd[i] * w[i];
                end

		// buffer initialization
		for (i=0;i<N;i=i+1) begin
			buffer[i]<=0;
		end

                // counter initialzation
                counter = 0;
	end


// added from now. New structure introduced by Prof. Arias
	wire signed [63:0] P [N-1:0];
	wire signed [63:0] A [N-2:0];
	reg signed [63:0] D [N-2:0];

	assign P[N-1]=h[N-1] * data_in;
	genvar j;
	generate
    	for (j=0; j<N-1; j=j+1) begin : gen_block
            assign P[j] = data_in*h[j];
	    assign A[j] = P[j] + D[j];
    	end
	endgenerate
	always @(posedge clk or posedge rst) begin
                if (rst) begin
                        counter = 0;
                        for (i=0;i<N-1;i=i+1) begin
                                D[i]<=0;
                        end
                end else begin
                        counter <= counter +1;
                        for (i=0;i<=N-3;i=i+1) begin       
                                D[i] <= A[i+1];
                        end
			D[N-2] <= P[N-1];
                end
        end

        assign filtered_out = A[0]/SCALE;


endmodule




