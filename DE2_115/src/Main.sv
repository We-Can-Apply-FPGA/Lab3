module Main(
	input i_clk,
	input [7:0] i_sw,
);

localparam S_INIT = 0;
localparam S_RECORD = 1;
localparam S_PLAY = 2;
localparam S_RECORD_PAUSE = 3;
localparam S_PLAY_PAUSE = 4;
localparam S_STOP = 5;

logic[2:0] main_state_r,main_state_w;

always_comb begin
	main_state_w = main_state_r;
	case(main_state_r)
		S_INIT:begin
			//init
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
		S_RECORD:begin
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
		S_PLAY:begin
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
		S_RECORD_PAUSE:begin
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
		S_PLAY_PAUSE:begin
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
		S_STOP:begin
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
	I2cSender i2csender(?)(
		.i_start,
		.i_dat,
		.i_clk,
		.i_rst,
		.o_finished,
		.o_sclk,
		.o_sdat
	);


