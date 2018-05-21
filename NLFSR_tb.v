module NLFSR_tb ();

parameter BYTES = 4;
parameter NUM_OF_TAPS = 2;

reg 				clk;
reg 				res;
reg 				ena;
reg				take_coef;
reg	[7:0]			coef;
reg 	[BYTES*8-1:1]		co_buf_lin;
	
wire 				ready;
wire				failure;
wire				found;
wire 	[NUM_OF_TAPS*8-1:0]	co_buf_non;

NLFSR nlfsr(
	.clk		(clk),
	.res		(res),
	.ena		(ena),
	.take_coef 	(take_coef),
	.coef		(coef),
	.co_buf_lin	(co_buf_lin),
	.ready		(ready),
	.co_buf_non 	(co_buf_non),
	.failure	(failure),
	.found		(found)
);

initial begin
	clk = 1'b0;
	co_buf_lin = 32'h00004181;
	ena = 1'b0;
	forever #5 clk = ~clk;
end

initial begin
	ena = 1'b0;
	repeat(8) @(posedge clk);
	ena = 1'b1;
	repeat(8) @(posedge clk);
	@ (negedge clk)
	take_coef = 1'b1;
	coef = 8'h07;
	@ (negedge clk) take_coef = 1'b0;
	repeat(8) @(posedge clk);
	@ (negedge clk)
	take_coef = 1'b1;
	coef = 8'h12;
	@ (negedge clk) take_coef = 1'b0;
	repeat(100) @(posedge clk);
	$finish;
end

endmodule