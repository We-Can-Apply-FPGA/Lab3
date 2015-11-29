module Main(
	input i_aud_bclk,
	input i_clk_100k,
	input i_rst_n,
	input [7:0] i_sw,
	
	output o_sclk,
	inout io_sdat,
	
	input i_adclrck,
	input i_adcdat,
	input i_daclrck,
	output o_dacdat,
	
	output [19:0] o_sram_addr,
	inout [15:0] io_sram_dq,
	output o_sram_oe,
	output o_sram_we,
	output o_sram_ce,
	output o_sram_lb,
	output o_sram_ub,

	output [31:0] o_curtime
);

localparam S_INIT = 0;
localparam S_LEFT = 1;
localparam S_RIGHT = 2;

localparam PTR_PAUSE = 0;
localparam PTR_START = 1;
localparam PTR_RESET = 2;

localparam MEM_ECHO = 0;
localparam MEM_WRITE = 1;
localparam MEM_READ = 2;

localparam CHANNEL_LENGTH = 16;

logic[2:0] state_r, state_w;
logic [31:0] debug_r, debug_w;
logic [15:0] data_r, data_w;
logic [10:0] clk_r, clk_w;
logic [1:0] ptr_action, mem_action;
logic ptr_start, mem_start, ok_r, ok_w;
logic init_finish;

//assign o_dacdat = i_adcdat;
assign ptr_action = i_sw[0] + ((i_sw[2:0] == 0) << 1);
assign mem_action = (i_sw[2] << 1) + i_sw[1];
//assign mem_action = (((i_sw[2] << 1) + i_sw[1]) == 3)?MEM_ECHO : ((i_sw[2] << 1) + i_sw[1]);
//assign ptr_action = (i_sw[1] ^ i_sw[2])?((i_sw[1] ^ i_sw[2])+i_sw[0]) : PTR_RESET;
//assign mem_action = (i_sw[1] ^ i_sw[2])?(i_sw[2] + 1):MEM_ECHO;

assign o_curtime = o_sram_addr / 32000 ;
assign debug = o_sram_addr / 32000;

SetCodec init(
	.i_clk(i_clk_100k),
	.i_rst_n(i_rst_n),
	.o_sclk(o_sclk),
	.io_sdat(io_sdat),
	.o_init_finish(init_finish)
);

SRamMgr memory(
	.i_clk(i_aud_bclk),
	.i_rst_n(i_rst_n),
	
	.i_ptr_start(ptr_start),
	.i_mem_start(mem_start),
	.i_ptr_action(ptr_action),
	.i_mem_action(mem_action),
	.i_data(data_r),
	
	.o_sram_addr(o_sram_addr),
	.io_sram_dq(io_sram_dq),
	.o_sram_oe(o_sram_oe),
	.o_sram_we(o_sram_we),
	.o_sram_ce(o_sram_ce),
	.o_sram_lb(o_sram_lb),
	.o_sram_ub(o_sram_ub),
);

task audio;
begin
	if (clk_r > 0) begin
		case(mem_action)
			MEM_READ: begin
				o_dacdat = io_sram_dq[clk_r - 1];
				mem_start = 1;
			end
			MEM_WRITE: begin
				data_w = (data_r << 1) + i_adcdat;
			end
			MEM_ECHO: begin
				o_dacdat = i_adcdat;
			end
		endcase
		clk_w = clk_r - 1;
	end
	else begin // full!
		if (!ok_r && mem_action == MEM_WRITE) begin
			mem_start = 1;
			ok_w = 1;
		end
		else mem_start = 0;
	end
end
endtask

always_comb begin
	state_w = state_r;
	clk_w = clk_r;
	ok_w = ok_r;
	o_dacdat = 0;
	data_w = data_r;
	mem_start = 0;
	ptr_start = 0;
	//adc dac clock will work simultaneously?
	case(state_r)
		S_INIT: begin
			if (init_finish) begin
				clk_w = CHANNEL_LENGTH;
				ok_w = 0;
				data_w = 0;
				state_w = S_LEFT;
			end
		end
		S_LEFT: begin
			if (i_adclrck) begin
				clk_w = CHANNEL_LENGTH;
				ok_w = 0;
				data_w = 0;
				state_w = S_RIGHT;
			end
			audio();
			
		end
		S_RIGHT: begin
			if (!i_adclrck) begin
				clk_w = CHANNEL_LENGTH;
				ok_w = 0;
				data_w = 0;
				ptr_start = 1;
				state_w = S_LEFT;
			end
			audio();
		end
	endcase
end

always_ff @(negedge i_rst_n or negedge i_aud_bclk) begin
	if (!i_rst_n) begin
		state_r <= S_INIT;
		data_r <= 0;
		ok_r <= 0;
	end
	else if (!i_aud_bclk) begin
		state_r <= state_w;
		clk_r <= clk_w;
		ok_r <= ok_w;
		data_r <= data_w;
	end
end
endmodule
