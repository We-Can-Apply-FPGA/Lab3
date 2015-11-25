module Main(
	input i_clk,
	input i_rst_n,

	input i_aud_adclrck,
	input i_aud_adcdat,
	input i_aud_daclrck,
	output o_aud_dacdat,
	input i_aud_bclk,

	input [2:0] i_sw,
	output [31:0] debug
);

localparam S_INIT = 0;
localparam S_IDLE = 1;
localparam S_RECORD = 2;
localparam S_PLAY = 3;
localparam S_RECORD_PAUSE = 4;
localparam S_PLAY_PAUSE = 5;

logic[2:0] main_state_r,main_state_w;
logic [31:0] debug_r, debug_w;
logic [10:0] clk_r, clk_w;
assign debug = debug_r;


always_comb begin
	main_state_w = main_state_r;
	debug_w = debug_r;
	clk_w = clk_r;
	case(main_state_r)
		S_INIT: begin
			if (clk_r < 15000) clk_w = clk_r + 1;
			else main_state_w = S_IDLE;
		end
		S_IDLE: begin
			if(i_sw[0] == 1 && i_sw[1] == 1 && i_sw[2] == 0) begin
				main_state_w = S_RECORD;
			end
			else if(i_sw[0] == 1 && i_sw[1] == 0 && i_sw[2] == 1) begin
				main_state_w = S_PLAY;
			end
		end
		S_RECORD:begin
			if(i_sw[0] == 1 && i_sw[1] == 1 && i_sw[2] == 0) begin
				main_state_w = S_RECORD;
			end
			else if(i_sw[0] == 0 && i_sw[1] == 1 && i_sw[2] == 0)begin
				main_state_w = S_RECORD_PAUSE;
			end
			else begin
				main_state_w = S_IDLE;
			end
		end
		S_PLAY:begin
			if(i_sw[0] == 1 && i_sw[1] == 0 && i_sw[2] == 1) begin
				main_state_w = S_PLAY;
			end
			else if(i_sw[0] == 0 && i_sw[1] == 0 && i_sw[2] == 1)begin
				main_state_w = S_PLAY_PAUSE;
			end
			else begin
				main_state_w = S_IDLE;
			end
		end
		S_RECORD_PAUSE:begin
			if(i_sw[0] == 0 && i_sw[1] == 1 && i_sw[2] == 0)begin
				main_state_w = S_RECORD_PAUSE;
			end
			else if(i_sw[0] == 1 && i_sw[1] == 1 && i_sw[2] == 0) begin
				main_state_w = S_RECORD;
			end
			else begin
				main_state_w = S_IDLE;
			end
		end
		S_PLAY_PAUSE:begin
			if(i_sw[0] == 0 && i_sw[1] == 0 && i_sw[2] == 1)begin
				main_state_w = S_PLAY_PAUSE;
			end
			else if(i_sw[0] == 1 && i_sw[1] == 0 && i_sw[2] == 1) begin
				main_state_w = S_PLAY;
			end
			else begin
				main_state_w = S_IDLE;
			end
		end
	endcase
end
always_ff @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		main_state_r <= S_INIT;
		clk_r <= 0;
		debug_r <= 0;
	end
	else begin
		main_state_r <= main_state_w;
		debug_r <= debug_w;
		clk_r <= clk_w;
	end
end
	/*
	SRamMgr memory(
		.i_clk(i_clk),
		.i_rst(i_rst),
		.i_rst_ptr(rst_ptr),
		.i_ptr_type(mem_ptr_type_r),
		.i_bePtrMove(i_sw[0]),
		.i_speed(i_sw[7:5]),
		.i_beSlow(i_sw[3]),
		//.i_beReverse(i_sw[4]),
		.io_sram_dq(io_sram_dq),
		.o_sram_oe(o_sram_oe),
		.o_sram_we(o_sram_we),
		.o_sram_ce(o_sram_ce),
		.o_sram_lb(o_sram_lb),
		.o_sram_ub(o_sram_ub),
		.o_sram_addr(o_sram_addr)
	);
	inout_port16 io(
		.i_oe(oe_r),
		.io_port(io_sram_dq),
		.i_o(sram_dq_r)
	);
	*/
endmodule
/*
module inout_port16(input i_oe, inout[15:0] io_port, input[15:0] i_o);
assign io_port = i_oe? i_o: 1'bz;
endmodule
*/
