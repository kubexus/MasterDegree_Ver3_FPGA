module Interface #(parameter NUM_OF_TAPS = 5, NUM_OF_MODULES = 20, SIZE = 24, BYTES = 4)(
	input 	clk,
	input 	rx,
	output 	tx,
	
	input [NUM_OF_MODULES-1:0] found,
	input [NUM_OF_MODULES-1:0] failure,
	input [NUM_OF_MODULES-1:0] ready,
	
	output reg [NUM_OF_MODULES-1:0] ena,
	output reg [NUM_OF_MODULES-1:0] res,

	output reg [NUM_OF_MODULES*BYTES*8-1:0] co_buf,
	
	output reg test1, test2, test3
	
);



wire [7:0] 	byte_in;
reg [7:0] 	byte_out;

reg 								transmit_byte;
reg [BYTES*8-1:0] 				buff;
reg [7:0] 						which;

reg [11:0] state;
parameter	IDLE 				= 12'b000000000001,
				RECEIVE 			= 12'b000000000010,
				ASSIGN_TO_REG	= 12'b000000000100,
				CONFIRM			= 12'b000000001000,
				TRANSMIT_POLY	= 12'b000000010000,
				FOUND				= 12'b000000100000,
				FAILURE			= 12'b000001000000,
				RESET				= 12'b000010000000,
				CAN_RECEIVE		= 12'b000100000000,
				WAIT_FOR_ACCK	= 12'b001000000000,
				SIGNAL_FOUND	= 12'b010000000000,
				WAIT_FOR_READY = 12'b100000000000;
				
				
parameter 	START = 	8'hf0,
				END	=	8'hff,
				ACCK	=	8'hf1,
				ERR	=	8'hee,
				FAIL	=	8'hf2,
				CAN_REC = 8'hf4,
				SIG_FOUND = 8'hf3;

wire jeden; 
assign jeden = 1'b0;

wire tx_ready;
wire take_byte;

reg [5:0] receive_count;
reg [5:0] assign_count;
reg [5:0] i;

initial begin
	byte_out <= 8'h00;
	transmit_byte <= 1'b0;
	buff <= {BYTES*8{1'b0}};
	which <= 8'h00;
	state <= IDLE;
	receive_count <= 1;
	assign_count <= 0;
	i <= 0;
	ena <= {NUM_OF_MODULES{1'b0}};
	res <= {NUM_OF_MODULES{1'b0}};
	co_buf <= {NUM_OF_MODULES*BYTES*8{1'b0}};
	test1 <= 1'b0;
	test2 <= 1'b0;
	test3 <= 1'b0;
end

Transmitter transmitter (
	.clk		(clk)			,
	.res		(jeden)		,
	.drl		(transmit)	,
	.load		(tx_ready)	,
	.din		(byte_out)	,
	.tx		(tx)
);

Receiver receiver (
	.clk		(clk)			,
	.res		(jeden)		,
	.rx		(rx)			,
	.take		(take_byte)	,
	.dout		(byte_in)
);

task conf;
input [7:0] byte;
begin
	byte_out <= byte;
	transmit_byte <= 1'b1;
	state <= CONFIRM;
end
endtask


always @ (posedge clk) begin
	case (state)
	
		RESET: begin
			byte_out <= 8'h00;
			transmit_byte <= 1'b0;
			buff <= {BYTES*8{1'b0}};
			which <= 8'h00;
			state <= IDLE;
			receive_count <= 1;
			assign_count <= 0;
			i <= 0;
			res <= {NUM_OF_MODULES{1'b0}};
		end
		
		IDLE: begin
			if (found != {NUM_OF_MODULES{1'b0}}) begin
				state <= SIGNAL_FOUND;
				transmit_byte <= 1'b1;
				byte_out <= SIG_FOUND;
			end else begin
				if (take_byte) begin
					if (byte_in == START && ena != {NUM_OF_MODULES{1'b1}}) begin
						state <= CAN_RECEIVE;
						transmit_byte <= 1'b1;
						byte_out <= CAN_REC;
					end
				end
			end
			if (failure != {NUM_OF_MODULES{1'b0}}) begin
				state <= FAILURE;
			end
		end
		
		CAN_RECEIVE: begin
			if (tx_ready) begin
				state <= RECEIVE;
				transmit_byte <= 1'b0;
			end
		end
		
		RECEIVE: begin
			if (take_byte) begin
				if (byte_in == END) begin
					state <= ASSIGN_TO_REG;
				end else begin
					buff[receive_count*8-1-:8] <= byte_in;
					receive_count <= receive_count + 1;
				end
			end
		end
		
		ASSIGN_TO_REG: begin
			if (ena[assign_count] == 1'b0) begin
				co_buf[(assign_count+1)*BYTES*8-1-:BYTES*8] <= buff;
				ena[assign_count] <= 1'b1;
				state <= WAIT_FOR_READY;
				//transmit_byte <= 1'b1;
				//conf(ACCK);
			end else begin
				assign_count <= assign_count + 1;
			end
			if (assign_count >= NUM_OF_MODULES) begin
				conf(ERR);
			end
		end
		
		WAIT_FOR_READY: begin
			if (ready[assign_count]) begin
				conf(ACCK);
			end
		end

		SIGNAL_FOUND: begin
			if (tx_ready) begin
				state <= WAIT_FOR_ACCK;
				transmit_byte <= 1'b0;
			end
		end

		WAIT_FOR_ACCK: begin
			if (take_byte) begin
				if (byte_in == ACCK) begin
					state <= FOUND;
				end else state <= IDLE;
			end
		end
		

		FOUND: begin
			if (found[i] == 1'b1) begin
				which <= i + 1;
				transmit_byte <= 1'b1;
				state <= TRANSMIT_POLY;
				i <= 0;
			end else i <= i + 1;
			if (i > NUM_OF_MODULES)
				conf(ERR);
		end
		
		
		TRANSMIT_POLY: begin
			if (tx_ready) begin
				if (i == 0) begin
					buff <= co_buf[which*BYTES*8-1-:BYTES*8];
				end
				if (i>0 && i<=BYTES) begin
					byte_out <= buff[i*8-1-:8];
					ena[which-1] 		<= 1'b0;
				end
				if (i == BYTES + 1) begin
					byte_out <= END;
					res[which-1] 		<= 1'b1;
				end
				if (i == BYTES + 2) begin
					transmit_byte		<= 1'b0;
					co_buf[(which)*BYTES*8-1-:BYTES*8] <= {BYTES*8{1'b0}};
					state	<= RESET;
				end 
				i <= i + 1;
			end
		end
		

		FAILURE: begin
			if (failure[i] == 1'b1) begin
				ena[i] <= 1'b0;
				res[i] <= 1'b1;
				co_buf[(i+1)*BYTES*8-1-:BYTES*8] <= {BYTES*8{1'b0}};
				byte_out <= FAIL;
				transmit_byte <= 1'b1;
				state <= CONFIRM;
			end else i <= i + 1;
			if (i > NUM_OF_MODULES)
				conf(ERR);
		end
		
	
		CONFIRM: begin
			if (tx_ready) begin
				state <= RESET;
			end
		end

	endcase
end
assign transmit = (transmit_byte) ? 1'b1:1'b0;

endmodule
