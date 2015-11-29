module SetCodec(
	input i_clk,
	input i_rst_n,
	output o_sclk,
	inout io_sdat,
	output o_init_finish,
	output [31:0] debug
);

logic [23:0] init_data[5:0];
assign init_data[0] = 24'b001101000000100000010101; //analog audio path
assign init_data[1] = 24'b001101000000101000000000; //digital audio path
assign init_data[2] = 24'b001101000000110000000000; //power down
assign init_data[3] = 24'b001101000000111001000010; //digital audio interface format
assign init_data[4] = 24'b001101000001000000011001; //sampling
assign init_data[5] = 24'b001101000001001000000001; //active

localparam NUM_INIT_DATA = 6;
localparam S_START_TRANS = 0;
localparam S_WAIT = 1;

logic state_r, state_w;
logic [2:0] cnt_r, cnt_w;
logic start_r, start_w, finish;
assign o_init_finish = (cnt_r == NUM_INIT_DATA);

I2cSender #(.BYTE(3)) sender(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.i_start(start_r),
	.i_dat(init_data[cnt_r]),
	.o_finished(finish),
	.o_sclk(o_sclk),
	.io_sdat(io_sdat)
);

always_comb begin
	cnt_w = cnt_r;
	start_w = start_r;
	state_w = state_r;
	case(state_r)
		S_START_TRANS: begin
			if (cnt_r < NUM_INIT_DATA) begin
				start_w = 1;
				state_w = S_WAIT;
			end
		end
		S_WAIT: begin
			start_w = 0;
			if (finish) begin
				state_w = S_START_TRANS;
				cnt_w = cnt_r + 1;
			end
		end
	endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		state_r <= S_START_TRANS;
		cnt_r <= 0;
		start_r <= 0;
	end
	else begin
		state_r <= state_w;
		cnt_r <= cnt_w;
		start_r <= start_w;
	end
end
endmodule
