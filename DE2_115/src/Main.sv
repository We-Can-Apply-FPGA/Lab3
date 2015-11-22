module Main(
	input i_clk,
	input i_rst,

	//controller
	input [7:0] i_sw,
	input i_sw[15], //???

	//CODEC
	output o_i2c_sclk,
	output o_i2c_sdat,
	input i_aud_adclrck,
	input i_aud_adcdat,
	input i_aud_daclrck,
	output o_aud_dacdat,
	input i_aud_bclk,
	output o_aud_xck,
	
	//SRAM
	inout[15:0] io_sram_dq,
	output o_sram_oe,
	output o_sram_we,
	output o_sram_ce,
	output o_sram_lb,
	output o_sram_ub,
	output[19:0] o_sram_addr,
);

localparam S_IDLE = 0;
localparam S_INIT = 1;
localparam S_INIT_WAIT = 2;
localparam S_RECORD = 3;
localparam S_PLAY = 4;
localparam S_RECORD_PAUSE = 5;
localparam S_PLAY_PAUSE = 6;
localparam S_STOP = 7;

//2-wire interface
//ADDR-w-DATA (24bits)
logic [143:0] init_data;
assign init_data[23 :  0] = 24'b001101000000100000010101; //analog audio path
assign init_data[47 : 24] = 24'b001101000000101000000000; //digital audio path
assign init_data[71 : 48] = 24'b001101000000110000000000; //power down
assign init_data[95 : 72] = 24'b001101000000111001000010; //digital audio interface format
assign init_data[119: 96] = 24'b001101000001000000011001; //sampling
assign init_data[143:120] = 24'b001101000001001000000001; //active
//After initing , what value should we assigned to init_data???

//SRAM control
localparam PTR_DUMMY=0;
localparam PTR_WRITE=1;
localparam PTR_READ=2;


logic[23:0] i2c_dat;
logic i2c_finish;
logic[2:0] main_state_r,main_state_w;
logic[2:0] init_cnt_r,init_cnt_w;
logic[1:0] mem_ptr_type_r;mem_ptr_type_w;
logic rst_ptr;


always_comb begin
	
	main_state_w = main_state_r;
	mem_ptr_type_w = mem_ptr_type_r;
	rst_ptr=0;
	case(main_state_r)
		S_IDLE:begin
			//power on/off
			rst_ptr = 1;
			mem_ptr_type_w = PTR_DUMMY;
			if(i_sw[15] == 1)begin
				main_state_w = S_INIT;
				init_cnt_r = 0;
			end
			else begin
				main_state_w = S_IDLE;
			end
		end
		S_INIT:begin
			if(i_sw[15] == 0)begin
				main_state_w = S_IDLE;
			end
			else if(init_cnt_r != 6)begin
				i2c_dat = init_data[(init_cnt_r+1)*8:init_cnt_r*8];
				init_cnt_w = init_cnt_r + 1;
				main_state_w = S_INIT_WAIT;
			end
			else begin
				if(i_sw[0] == 1 && i_sw[1] == 1 && i_sw[2] == 0)begin
					main_state_w = S_RECORD;
				end
				else if(i_sw[0] == 1 && i_sw[1] == 0 && i_sw[2] == 1)begin
					main_state_w = S_PLAY;
				end
				else begin
					main_state_w = S_STOP;
				end
			end
		end
		S_INIT_WAIT:begin
			i2c_dat = init_data[(init_cnt_r+1)*8:init_cnt_r*8];
			if(i2c_finish == 1)begin
				main_state_w = S_INIT;
				init_cnt_w = init_cnt_r + 1;
			end
			else begin
				main_state_w = S_INIT_WAIT;
			end
		end
		S_RECORD:begin
			mem_ptr_type_w = PTR_WRITE;
			if(i_sw[15] == 0)begin
				main_state_w = S_IDLE;
			end
			else begin
				if(i_sw[0] == 1 && i_sw[1] == 1 && i_sw[2] == 0) begin
					main_state_w = S_RECORD;
				end
				else if(i_sw[0] == 0 && i_sw[1] == 1 && i_sw[2] == 0)begin
					main_state_w = S_RECORD_PAUSE;
				end
				else begin
					main_state_w = S_STOP;
				end
			end
		end
		S_PLAY:begin
			mem_ptr_type_w = PTR_READ;
			if(i_sw[15] == 0)begin
				main_state_w = S_IDLE;
			end
			else begin
				if(i_sw[0] == 1 && i_sw[1] == 0 && i_sw[2] == 1) begin
					main_state_w = S_PLAY;
				end
				else if(i_sw[0] == 0 && i_sw[1] == 0 && i_sw[2] == 1)begin
					main_state_w = S_PLAY_PAUSE;
				end
				else begin
					main_state_w = S_STOP;
				end
			end
		end
		S_RECORD_PAUSE:begin
			mem_ptr_type_w = PTR_READ;
			if(i_sw[15] == 0)begin
				main_state_w = S_IDLE;
			end
			else begin
				if(i_sw[0] == 0 && i_sw[1] == 1 && i_sw[2] == 0)begin
					main_state_w = S_RECORD_PAUSE;
				end
				else if(i_sw[0] == 1 && i_sw[1] == 1 && i_sw[2] == 0) begin
					main_state_w = S_RECORD;
				end
				else begin
					main_state_w = S_STOP;
				end
			end
		end
		S_PLAY_PAUSE:begin
			mem_ptr_type_w = PTR_WRITE;
			if(i_sw[15] == 0)begin
				main_state_w = S_IDLE;
			end
			else begin
				if(i_sw[0] == 0 && i_sw[1] == 0 && i_sw[2] == 1)begin
					main_state_w = S_PLAY_PAUSE;
				end
				else if(i_sw[0] == 1 && i_sw[1] == 0 && i_sw[2] == 1) begin
					main_state_w = S_PLAY;
				end
				else begin
					main_state_w = S_STOP;
				end
			end
		end
		S_STOP:begin
			rst_ptr=1;
			mem_ptr_type_w = PTR_DUMMY;
			if(i_sw[15] == 0)begin
				main_state_w = S_IDLE;
			end
			else begin
				if(i_sw[0] == 1 && i_sw[1] == 1 && i_sw[2] == 0)begin
					main_state_w = S_RECORD;
				end
				else if(i_sw[0] == 1 && i_sw[1] == 0 && i_sw[2] == 1)begin
					main_state_w = S_PLAY;
				end
				else begin
					main_state_w = S_STOP;
				end
			end
		end
	endcase
end

	I2cSender i2csender#(.BYTE(3))(
		.i_start(i_start),
		.i_dat(i2c_dat),
		.i_clk(i_clk),
		.i_rst(i_rst),
		.o_finished(i2c_finish),
		.o_sclk(o_i2c_sclk),
		.o_sdat(o_i2c_sdat)
	);
	SRamMgr memory(
		.i_clk(i_clk),
		.i_rst(i_rst),
		.i_rst_ptr(rst_ptr),
		.i_ptr_type(mem_ptr_type_r),
		.i_bePtrMove(i_sw[0]),
		.i_speed(i_sw[7:5]),
		.i_beSlow(i_sw[3]),
		.i_beReverse(i_swp[4]),
		.io_sram_dq(),
		.o_sram_oe(),
		.o_sram_we(),
		.o_sram_ce(),
		.o_sram_lb(),
		.o_sram_ub(),
		.o_sram_addr(),

	)


