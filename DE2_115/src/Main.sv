module Main(
	input i_clk_12m,
	input i_clk_100k,
	input i_rst_n,
	
	input o_sclk,
	inout io_sdat,
	
	input i_aud_adclrck,
	input i_aud_adcdat,
	input i_aud_daclrck,
	output o_aud_dacdat,
	input i_aud_bclk,

	input [7:0] i_sw
	inout io_sram_dq,
	output o_sram_oe,
	output o_sram_we,
	output o_sram_ce,
	output o_sram_lb,
	output o_sram_ub,
	output o_sram_addr
	//output [31:0] debug
);

localparam S_INIT = 0;
localparam S_IDLE = 1;
localparam S_RECORD = 2;
localparam S_PLAY = 3;

localparam PTR_DUMMY=0;
localparam PTR_WRITE=1;
localparam PTR_READ=2;

localparam LEFT=0;
localparam RIGHT=1;

localparam FALSE=0;
localparam TRUE=1;

localparam CHANNEL_LENGTH=16;

logic[2:0] main_state_r, main_state_w;
logic init_finish;
logic [1:0] mem_ptr_type_r, mem_ptr_type_w;
logic start_i2s_r,start_i2s_w;
logic data_write_in_w,data_write_in_r;
logic rst_ptr;
logic data_read_out_w,data_read_out_r;
logic beIncAddr_r,beIncAddr_w;//increment 1 unit(depend on SRamMgr setting) if this addr is full
logic [3:0] left_cnt_r,left_cnt_w;
logic [3:0] right_cnt_r,right_cnt_w;
logic [3:0] sram_dq_loc;

assign rst_ptr = (main_state_r == S_IDLE)?TRUE:FALSE;

always_comb begin
	main_state_w = main_state_r;
	debug_w = debug_r;
	mem_ptr_type_w = mem_ptr_type_r;
	start_i2s_w = start_i2s_r;
	data_write_in_w = data_write_in_r;
	data_read_out_w = data_read_out_r;
	sram_dq_loc = 0;

	case(main_state_r)
		S_INIT: begin
			if(init_finish) main_state_w = S_IDLE;
		end
		S_IDLE: begin
			if(i_sw[0] == 1 && i_sw[1] == 1 && i_sw[2] == 0) begin
				main_state_w = S_RECORD;
				mem_ptr_type_w = PTR_WRITE;
			end
			else if(i_sw[0] == 1 && i_sw[1] == 0 && i_sw[2] == 1) begin
				main_state_w = S_PLAY;
				mem_ptr_type_w = PTR_READ;
			end
		end
		S_RECORD:begin
			if(i_sw[1] == 1 && i_sw[2] == 0) begin
				main_state_w = S_RECORD;
				if(start_i2s_r==0)begin //new peroid
					mem_ptr_type_w = PTR_DUMMY;
					start_i2s_w = 1;//wait one clock
					beIncAddr_w = FALSE;
				end
				else begin
					mem_ptr_type_w = PTR_WRITE;
					data_write_in_w = i_aud_adcdat;
					if(i_aud_adclrck == LEFT)begin
						if(left_cnt_r == CHANNEL_LENGTH-1)begin
							beIncAddr_w = TRUE;
							left_cnt_w = 0;
							start_i2s_w = FALSE;
						end
						else begin
							left_cnt_w = left_cnt_r + 1;
						end
						sram_dq_loc=left_cnt_r;
					end
					else begin
						if(right_cnt_r == CHANNEL_LENGTH-1)begin
							beIncAddr_w = TRUE;
							right_cnt_w = 0;
							start_i2s_w = FALSE;
						end
						else begin
							right_cnt_w = right_cnt_r + 1;
						end
						sram_dq_loc=right_cnt_r;
					end
				end
			end
			else begin
				main_state_w = S_IDLE;
				mem_ptr_type_w = PTR_DUMMY;
			end
		end
		S_PLAY:begin
			if(i_sw[1] == 0 && i_sw[2] == 1) begin
				main_state_w = S_PLAY;
				if(start_i2s_r==0)begin //new peroid
					mem_ptr_type_w=PTR_DUMMY;
					start_i2s_w = 1;//wait one clock
					beIncAddr_w = FALSE;
				end
				else begin
					mem_ptr_type_w=PTR_READ;
					o_aud_dacdat = data_read_out_r;
					if(i_aud_daclrck == LEFT)begin
						if(left_cnt_r == CHANNEL_LENGTH-1)begin
							beIncAddr_w = TRUE;
							left_cnt_w = 0;
							start_i2s_w = FALSE;
						end
						else begin
							left_cnt_w = left_cnt_r + 1;
						end
						sram_dq_loc=left_cnt_r;
					end
					else begin
						if(right_cnt_r == CHANNEL_LENGTH-1)begin
							beIncAddr_w = TRUE;
							right_cnt_w = 0;
							start_i2s_w = FALSE;
						end
						else begin
							right_cnt_w = right_cnt_r + 1;
						end
						sram_dq_loc=right_cnt_r;
					end
				end
			end
			else begin
				main_state_w = S_IDLE;
				mem_ptr_type_w = PTR_DUMMY;
			end
		end
	endcase
end

always_ff @(posedge i_clk_12m or negedge i_rst_n) begin
	if (!i_rst_n) begin
		main_state_r <= S_INIT;
		mem_ptr_type_r <= PTR_DUMMY;
		start_i2s_r <= 0;
	end
	else begin
		main_state_r <= main_state_w;
		mem_ptr_type_r <= mem_ptr_type_w;
		start_i2s_r <= start_i2s_w;
	end
end
	SetCodec init(
		.i_clk(i_clk_100k),
		.i_rst_n(i_rst_n),
		.o_sclk(o_sclk),
		.io_sdat(io_sdat),
		.o_init_finish(init_finish)
		
	);
	SRamMgr memory(
		.i_clk(i_clk_100k),
		.i_rst_n(i_rst_n),
		.i_ptr_type(mem_ptr_type_r),
		.i_rst_ptr(rst_ptr),
		.i_data_writein(data_write_in_r),
		.i_bePtrMove(i_sw[0]),
		.i_speed(i_sw[7:5]),
		.i_beSlow(i_sw[3]),
		.i_beIncAddr(beIncAddr_r)
		.o_data_readout(data_read_out_r),
		//.i_beReverse(i_sw[4]),
		.io_sram_dq(io_sram_dq),
		.i_sram_dq_loc(sram_dq_loc),
		.o_sram_oe(o_sram_oe),
		.o_sram_we(o_sram_we),
		.o_sram_ce(o_sram_ce),
		.o_sram_lb(o_sram_lb),
		.o_sram_ub(o_sram_ub),
		.o_sram_addr(o_sram_addr),
		//.debug(debug[31:3])
	);
endmodule
