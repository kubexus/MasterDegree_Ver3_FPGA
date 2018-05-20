module PRNG #(parameter SEED = 384154861654616) (
	input 				clk,
	input					res,
	output reg [7:0] 	dout,
	output reg 			done
);

reg [31:0] 	lfsr;
reg [7:0] 	waiter;
reg [3:0] 	i;

wire feedback;

assign feedback 	= (lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]);

initial begin
	lfsr 			<= SEED;
	dout			<= 8'h00;
	waiter		<= 8'h00;
	i 				<= 4'b0000;
	done 			<= 1'b0;
end

always @ (posedge clk) begin

	if (res) begin
		dout		<= 8'h00;
		done 		<= 1'b0;
		i 			<= 4'b0000;
		waiter	<= 8'h00;
	end 
	if (waiter < 33) begin
		waiter <= waiter + 1; // pozwala przeliczyc cala dlugosc rejestru
	end 
	if (waiter >= 33) begin
		lfsr <= {feedback,lfsr[31:1]};
		if (i < 7) begin
			done <= 1'b0;
			dout[i] <= lfsr[31];
			i <= i + 1;
		end
		if (i == 7) begin
			dout[i] <= lfsr[31];
			if (dout[4:0] != 5'b00000) // sygnalizuj tylko pod warunkiem ze donry wspolczynnik
				done <= 1'b1;
			i <= 0;
		end
	end
end

endmodule
