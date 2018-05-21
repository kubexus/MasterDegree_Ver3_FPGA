module NLFSR #(parameter SIZE = 24, NUM_OF_TAPS = 2, BYTES = 4)(

	input 					clk,
	input 					res,
	input 					ena,
	input						take_coef,
	input	[7:0]				coef,
	input [BYTES*8-1:1]	co_buf_lin,
	
	output reg 	ready,
	output reg	failure,
	output reg	found,
	output reg [NUM_OF_TAPS*8-1:0]		co_buf_non
);

parameter [35:0] period = (2**SIZE) - 1;
parameter INIT_VAL = {{SIZE-1{1'b0}},1'b1};


reg [4:0] taps_count;
reg [35:0] i;
reg [7:0] j;
reg [SIZE-1:0] state;
reg [NUM_OF_TAPS:1] TAPS;



initial begin
	co_buf_non <= {NUM_OF_TAPS{8'h00}};
	taps_count <= 1;
	i <= 0;
	state <= INIT_VAL;
	failure <= 1'b0;
	found 	<= 1'b0;
	j <= 0;
	TAPS <= {NUM_OF_TAPS{1'b0}};
	ready <= 1'b0;
end

reg [SIZE-1:1] feedback;

wire feedback1;
assign feedback1 = ^feedback ^ state[0] ^ (TAPS[1] & TAPS[2]);// ^ (TAPS[3] & TAPS[4]);

always @ (posedge clk) begin
	if (res) begin
		ready 		<= 1'b0;
		state 		<= INIT_VAL;
		found 		<= 1'b0;
		failure 		<= 1'b0;
		i 				<= {36{1'b0}};
		taps_count 	<= 1;
		co_buf_non 	<= {NUM_OF_TAPS{8'h00}};
	end
	if (ena) begin
		if (!ready) begin
			if (take_coef && taps_count <= NUM_OF_TAPS && coef[4:0] < SIZE) begin
				if (taps_count == 1)
					co_buf_non[taps_count*8-1-:8] <= {3'b000,coef[4:0]};
				if (taps_count == 2 && coef[4:0] != co_buf_non[4:0])
					co_buf_non[taps_count*8-1-:8] <= {3'b000,coef[4:0]};
				taps_count <= taps_count + 1;
				if (taps_count == NUM_OF_TAPS) begin
					ready <= 1'b1;
				end
			end
		end else begin
			if (!found && !failure) begin
				state <= {feedback1, state[SIZE-1:1]};
				i <= i + 1;
			end
			if (state == INIT_VAL) begin
				if (i == period)
					found <= 1'b1; 
				if (i > 5 && i < period)
					failure <= 1'b1;
			end
			if (i > period + 3)
				failure <= 1'b1;
		end
	end
end

always @ (*) begin
	for (j=1;j<SIZE;j=j+1) begin
		feedback[j] <= state[j] & co_buf_lin[j];
	end
end

genvar k;
generate
for (k = 1; k <= NUM_OF_TAPS; k = k + 1) 
	begin: TAPSY
	always @ (*) begin
		if (res) begin
			TAPS[k] <= 1'b0;
		end 
		if (ena) begin
			case (co_buf_non[k*8-1-:8])
				8'h01 :	TAPS[k] <= state[1];
				8'h02 :	TAPS[k] <= state[2];
				8'h03 :	TAPS[k] <= state[3];
				8'h04 :	TAPS[k] <= state[4];
				8'h05 :	TAPS[k] <= state[5];
				8'h06 :	TAPS[k] <= state[6];
				8'h07 :	TAPS[k] <= state[7];
				8'h08 :	TAPS[k] <= state[8];
				8'h09 :	TAPS[k] <= state[9];
				8'h0a :	TAPS[k] <= state[10];
				8'h0b :	TAPS[k] <= state[11];
				8'h0c :	TAPS[k] <= state[12];
				8'h0d :	TAPS[k] <= state[13];
				8'h0e :	TAPS[k] <= state[14];
				8'h0f :	TAPS[k] <= state[15];
				8'h10 :	TAPS[k] <= state[16];
				8'h11 :	TAPS[k] <= state[17];
				8'h12 :	TAPS[k] <= state[18];
				8'h13 :	TAPS[k] <= state[19];
				8'h14 :	TAPS[k] <= state[20];
				8'h15 :	TAPS[k] <= state[21];
				8'h16 :	TAPS[k] <= state[22];
				8'h17 :	TAPS[k] <= state[23];
//				8'h18 :	TAPS[k] <= state[24];
//				8'h19 :	TAPS[k] <= state[25];
//				8'h1a :	TAPS[k] <= state[26];
//				8'h1b :	TAPS[k] <= state[27];
//				8'h1c :	TAPS[k] <= state[28];
//				8'h1d :	TAPS[k] <= state[29];
//				8'h1e :	TAPS[i] <= state[30];
//				8'h1f :	TAPS[i] <= state[31];
			endcase
		end
	end
end
endgenerate

endmodule

