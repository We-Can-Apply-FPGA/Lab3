module Main(
	input i_bclk,
	input i_clk_100k,
	input i_rst_n,
	input [3:0] i_key,
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

	output [31:0] o_curtime,
	output [3:0] o_ptr_action,
	output [3:0] o_mem_action,
	output [3:0] o_speed,
	output [31:0] debug
);
`include "define.sv"
localparam S_INIT = 0;
localparam S_LEFT = 1;
localparam S_RIGHT = 2;

localparam M_NORMAL = 0;
localparam M_MODIFY = 1;

localparam CHANNEL_LENGTH = 16;

logic [2:0] state_r, state_w;
logic [31:0] debug_r, debug_w;
logic [15:0] data_r, data_w;
logic [10:0] clk_r, clk_w;
logic init_finish;
logic [15:0] o_data;

assign o_curtime = o_sram_addr / 32000 ;

SetCodec init(
	.i_clk(i_clk_100k),
	.i_rst_n(i_rst_n),
	.o_sclk(o_sclk),
	.io_sdat(io_sdat),
	.o_init_finish(init_finish)
);

SRamMgr memory(
	.i_clk(i_adclrck),
	.i_rst_n(i_rst_n),
	
	.i_speed(o_speed),
	.i_interpolate(i_sw[3]),
	.i_repeat(i_sw[1]),
	
	.i_ptr_action(o_ptr_action),
	.i_mem_action(o_mem_action),
	.i_data(data_r),
	.o_data_read_out(o_data),
	
	.o_sram_addr(o_sram_addr),
	.io_sram_dq(io_sram_dq),
	.o_sram_oe(o_sram_oe),
	.o_sram_we(o_sram_we),
	.o_sram_ce(o_sram_ce),
	.o_sram_lb(o_sram_lb),
	.o_sram_ub(o_sram_ub)
);

Controller control(
    .i_clk(i_adclrck),
    .i_rst_n(i_rst_n),

    .i_key(i_key),
    .i_rw(i_sw[0]),
    .i_mode(i_sw[2]),
	
    .o_ptr_action(o_ptr_action),
    .o_mem_action(o_mem_action),
	.o_speed(o_speed)
);

task audio;
begin
	if (clk_r > 0) begin
		case(o_mem_action)
			MEM_READ: begin
				o_dacdat = o_data[clk_r - 1];
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
end
endtask

always_comb begin
	state_w = state_r;
	clk_w = clk_r;
	o_dacdat = 0;
	data_w = data_r;
	case(state_r)
		S_INIT: begin
			if (init_finish) begin
				clk_w = CHANNEL_LENGTH;
				data_w = 0;
				state_w = S_LEFT;
			end
		end
		S_LEFT: begin
			if (i_adclrck) begin
				clk_w = CHANNEL_LENGTH;
				data_w = 0;
				state_w = S_RIGHT;
			end
			audio();
			
		end
		S_RIGHT: begin
			if (!i_adclrck) begin
				clk_w = CHANNEL_LENGTH;
				data_w = 0;
				state_w = S_LEFT;
			end
			audio();
		end
	endcase
end

always_ff @(negedge i_bclk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		state_r <= S_INIT;
		data_r <= 0;
		clk_r <= 0;
	end
	else if (!i_bclk) begin
		state_r <= state_w;
		clk_r <= clk_w;
		data_r <= data_w;
	end
end
endmodule



