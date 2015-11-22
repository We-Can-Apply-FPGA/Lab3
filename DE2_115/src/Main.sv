module Main(
	input i_clk,
	input i_rst,
	input [7:0] i_sw,
	input i_sw[15], //???

	output o_i2c_sclk,
	output o_i2c_sdat,

	input i_aud_adclrck,
	input i_aud_adcdat,
	input i_aud_daclrck,
	output o_aud_dacdat,
	input i_aud_bclk,

	output o_aud_xck,
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

logic[23:0] i2c_dat;
logic i2c_finish;
logic[2:0] main_state_r,main_state_w;
logic[2:0] init_cnt_r,init_cnt_w;

always_comb begin
	main_state_w = main_state_r;
	case(main_state_r)
		S_IDLE:begin
			//power on/off
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
			if(i2c_finish == 1)begin
				main_state_w = S_INIT;
			end
			else begin
				main_state_w = S_INIT_WAIT;
			end
		end
		S_RECORD:begin
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


