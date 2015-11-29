module Controller(
    input i_clk,
    input i_rst_n,

    input [3:0] i_key,
    input i_rw,
    input i_mode,

    output [3:0] o_ptr_action,
	output [3:0] o_speed,
    output [3:0] o_mem_action
);
`include "define.sv"
logic [3:0] ptr_r, ptr_w;
logic [3:0] speed_r, speed_inc, speed_dec, speed_w;
assign o_mem_action = i_rw;
assign o_speed = 4'b1001;

always_comb begin
    o_ptr_action = ptr_r;
    if (!i_mode && !i_key[0]) o_ptr_action = PTR_RIGHT;
    else if (!i_mode && !i_key[3]) o_ptr_action = PTR_LEFT;
end

always_comb begin
	speed_inc = speed_r;
	speed_dec = speed_r;
	speed_w = speed_r;
	if (i_mode) begin
		if (speed_r == 'b0111) speed_inc = speed_r;
		else if (speed_r == 'b1001) speed_inc = 0;
		else if (!speed_r[3]) speed_inc = speed_r + 1;
		else speed_inc = speed_r - 1;
		
		if (speed_r == 'b1111) speed_dec = speed_r;
		else if (speed_r == 'b0000) speed_dec = 'b1001;
		else if (!speed_r[1]) speed_dec = speed_r - 1;
		else speed_dec = speed_r + 1;
	end
end

always_comb begin
    ptr_w = ptr_r;
	if (!i_mode) begin
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
end

always_ff @(negedge i_key[2] or negedge i_key[1] or negedge i_rst_n) begin
    if (!i_rst_n || !i_key[1]) ptr_r <= PTR_RESET;
	else ptr_r <= ptr_w;
end
always_ff @(negedge i_key[0] or negedge i_key[3] or negedge i_rst_n) begin
	if (!i_rst_n) speed_r <= 0;
	else begin
		if (!i_key[3]) speed_r <= speed_inc;
		else if (!i_key[0]) speed_r <= speed_dec;
		else speed_r = speed_w;
	end
end
endmodule

