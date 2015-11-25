module I2cSender #(parameter BYTE=3) (
	input i_start,
	input [BYTE*8-1:0] i_dat,
	input i_clk,
	input i_rst_n,
	output o_finished,
	output o_sclk,
	inout io_sdat
);

localparam S_IDLE = 0;
localparam S_START = 1;
localparam S_TRANS = 2;
localparam S_END = 3;

logic [1:0] state_r, state_w;
logic [4:0] byte_counter_r, byte_counter_w;
logic [2:0] bit_counter_r, bit_counter_w;
logic [1:0] counter_r, counter_w;
logic [BYTE*8-1:0] data_r, data_w;
logic oe_r, oe_w;
logic sdat_r, sdat_w;

assign o_finished = (state_r == 0);
assign o_sclk = (counter_r == 2);

inout_port io(
	.i_oe(oe_r),
	.io(io_sdat),
	.i(sdat_r)
);

always_comb begin
	state_w = state_r;
	data_w = data_r;
	oe_w = oe_r;
	sdat_w = sdat_r;
	byte_counter_w = byte_counter_r;
	bit_counter_w = bit_counter_r;
	counter_w = counter_r;
	if (state_r != S_IDLE) begin
		case(counter_r)
			2: begin
				counter_w = 1;
			end
			1: begin
				counter_w = 0;
			end
			0: begin
				counter_w = 2;
			end
		endcase
	end
	case(state_r)
		S_IDLE: begin
			if (i_start) begin
				data_w = i_dat;
				state_w = S_START;
				oe_w = 1;
				sdat_w = 0;
				counter_w = 2;
			end
		end
		S_START: begin
			if (counter_r == 1) begin
				sdat_w = data_r[8*BYTE-1];
				data_w = data_r << 1;
				byte_counter_w = BYTE-1;
				bit_counter_w = 7;
				state_w = S_TRANS;
			end
		end
		S_TRANS: begin
			if (counter_r == 1) begin
				if (!bit_counter_r) begin
					if (oe_w) begin
						oe_w = 0;
					end
					else begin
						oe_w = 1;
						if (!byte_counter_r) begin
							state_w = S_END;
							sdat_w = 0;
						end
						else begin
							byte_counter_w = byte_counter_r - 1;
							bit_counter_w = 7;
							sdat_w = data_r[8*BYTE-1];
							data_w = data_r << 1;
						end
					end
				end
				else begin
					bit_counter_w = bit_counter_r-1;
					sdat_w = data_r[8*BYTE-1];
					data_w = data_r << 1;
				end
			end
		end
		S_END: begin
			if (counter_r == 2) begin
				counter_w = 2;
				sdat_w = 1;
				state_w = S_IDLE;
			end
		end
	endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		state_r <= S_IDLE;
		data_r <= 0;
		oe_r = 0;
		sdat_r <= 1;
		byte_counter_r <= 0;
		bit_counter_r <= 0;
		counter_r <= 2;
	end
	else begin
		state_r <= state_w;
		data_r <= data_w;
		oe_r <= oe_w;
		sdat_r <= sdat_w;
		byte_counter_r <= byte_counter_w;
		bit_counter_r <= bit_counter_w;
		counter_r <= counter_w;
	end
end
endmodule

module inout_port(input i_oe, inout io, input i);
assign io = i_oe? i: 1'bz;
endmodule
