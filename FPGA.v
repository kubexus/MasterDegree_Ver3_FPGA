module FPGA #(parameter NUM_OF_TAPS = 2, SIZE = 24, NUM_OF_MODULES = 30, BYTES = 4 + NUM_OF_TAPS) (
	input clk,
	input wire rx,
	output wire tx,
	output reg found_smth,
	output wire startedmod,
	output wire t1, t2, t3
);

wire [NUM_OF_MODULES*BYTES*8-1:0] coefficient_buff;

wire [NUM_OF_MODULES-1:0] found;
wire [NUM_OF_MODULES-1:0] failure;
wire [NUM_OF_MODULES-1:0] res;
wire [NUM_OF_MODULES-1:0] ena;
wire [NUM_OF_MODULES-1:0] ready;

wire [NUM_OF_MODULES*NUM_OF_TAPS*8-1:0] co_buf_non;

wire [7:0] coef;

assign startedmod = ena[0];

Interface #(
			.NUM_OF_TAPS		(NUM_OF_TAPS)		, 
			.NUM_OF_MODULES	(NUM_OF_MODULES)	,
			.SIZE					(SIZE)				)
			
	interfejs (	
		.clk			(clk)			,
		.rx 			(rx)			,
		.tx			(tx)			,
		.found		(found)		,
		.failure		(failure)	,
		.ena			(ena)			,
		.res			(res)			,
		.ready		(ready)		,
		.co_buf_non (co_buf_non),
		.co_buf		(coefficient_buff),
		.test1  		(t1),
		.test2 		(t2),
		.test3 		(t3)
);

PRNG #(.SEED(8168464)) coef_gen(
	.clk	(clk)			,
	.res	(res_gen)	,
	.dout	(coef)		,
	.done	(take_coef)
);

genvar i;
generate
for (i=0; i<NUM_OF_MODULES; i=i+1) begin: Trololo
	
	NLFSR #(
				.NUM_OF_TAPS 	(NUM_OF_TAPS), 
				.SIZE 			(SIZE) )
		rejestr (
			.clk			(clk),
			.res			(res[i]),
			.ena			(ena[i]),
			.take_coef 	(take_coef),
			.coef			(coef),
			.co_buf_lin	(coefficient_buff[(i+1)*(SIZE)-1-:SIZE]),
			.ready		(ready[i]),
			.co_buf_non (co_buf_non[(i+1)*NUM_OF_TAPS*8-1-:NUM_OF_TAPS*8]),
			.failure		(failure[i]),
			.found		(found[i])
	);
	
end
endgenerate

initial begin
	found_smth <= 1'b0;
end

always @ (posedge clk) begin
	
	if (found != {NUM_OF_MODULES{1'b0}}) begin
		found_smth <= 1'b1;
	end

end

endmodule
