module Controller(
    input i_clk,
    input i_rst_n,

    input [3:0] i_key,
    input i_rw,
    input i_mode,

    output [3:0] o_ptr_action,
    output [3:0] o_mem_action,
	output [3:0] o_speed
);
`include "define.sv"
logic [3:0] ptr_r, ptr_w;
logic [3:0] speed_r, speed_w;
logic [15:0] clk_speed_r, clk_speed_w;
logic state_speed_r, state_speed_w;

assign o_mem_action = i_rw;
assign o_speed = speed_r;

always_comb begin
    o_ptr_action = ptr_r;
    if (!i_mode && !i_key[0]) o_ptr_action = PTR_RIGHT;
    else if (!i_mode && !i_key[3]) o_ptr_action = PTR_LEFT;
end

always_comb begin
	speed_w = speed_r;
	state_speed_w = state_speed_r;
	clk_speed_w = clk_speed_r;
	case(state_speed_r)
		0: begin
			if (!i_key[0] && i_mode) begin
				if (speed_r == 'b0111) speed_w = speed_r;
				else if (speed_r == 'b1001) speed_w = 'b0000;
				else if (!speed_r[3]) speed_w = speed_r + 1;
				else speed_w = speed_r - 1;
				state_speed_w = 1;
				clk_speed_w = 12800;
			end
			else if (!i_key[3] && i_mode) begin
				if (speed_r == 'b1111) speed_w = speed_r;
				else if (speed_r == 'b0000) speed_w = 'b1001;
				else if (!speed_r[3]) speed_w = speed_r - 1;
				else speed_w = speed_r + 1;
				state_speed_w = 1;
				clk_speed_w = 12800;
			end
		end
		1: begin
			if (clk_speed_r == 0) state_speed_w = 0;
			else clk_speed_w = clk_speed_r - 1;
		end
	endcase
end

always_comb begin
    ptr_w = ptr_r;
	case (ptr_r)
		PTR_RESET: begin
			ptr_w = PTR_START;
		end
		PTR_START: begin
			ptr_w = PTR_PAUSE;
		end
		PTR_PAUSE: begin
			ptr_w = PTR_START;
		end
	endcase
end

always_ff @(negedge i_key[2] or negedge i_key[1] or negedge i_rst_n) begin
    if (!i_rst_n || !i_key[1]) ptr_r <= PTR_RESET;
	else ptr_r <= ptr_w;
end

always_ff @(negedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		speed_r <= 0;
		clk_speed_r <= 12800;
		state_speed_r <= 0;
	end
	else if (!i_clk) begin
		speed_r <= speed_w;
		clk_speed_r <= clk_speed_w;
		state_speed_r <= state_speed_w;
	end
end

endmodule

