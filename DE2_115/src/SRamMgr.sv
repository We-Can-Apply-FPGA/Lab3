module SRamMgr(
	input i_clk,
	input i_rst_n,
	input i_mode,
	
	input [3:0] i_speed,
	input i_interpolate,
	input i_repeat,
	input i_ptr_start,
	input i_mem_start,
	input [3:0] i_ptr_action,
	input [3:0] i_mem_action,
	input [15:0] i_data,
	
	output [19:0] o_sram_addr,
	inout [15:0] io_sram_dq,
	output [15:0] o_data_read_out,

	output o_sram_oe,
	output o_sram_we,
	output o_sram_ce,
	output o_sram_lb,
	output o_sram_ub
);
`include "define.sv"
logic[2:0] ptr_inc_r, ptr_inc_w;
logic[19:0] addr_r, addr_w, last_r, last_w;
logic [2:0] slow_cnt_r,slow_cnt_w;
logic [15:0] prev_data_r,prev_data_w;
logic [15:0] data_read_out_r , data_read_out_w;

assign o_sram_addr = addr_r;
assign io_sram_dq = (i_mem_action == MEM_READ)? 16'bz: i_data;
assign o_data_read_out = data_read_out_r;

always_comb begin
	ptr_inc_w = ptr_inc_r;
	addr_w = addr_r;
	last_w = last_r;
	slow_cnt_w = slow_cnt_r;
	prev_data_w = prev_data_r;
	data_read_out_w = data_read_out_r;
	//o_data_read_out = 16'b0;
	
	o_sram_we = 1;
	o_sram_ce = 0;
	o_sram_oe = 1;
	o_sram_lb = 1'bz;
	o_sram_ub = 1'bz;
	if (i_ptr_start) begin
		case(i_ptr_action)
			PTR_RESET: begin
				addr_w = 0;
			end
			PTR_PAUSE: begin
			end
			PTR_START: begin
				if (i_mem_action == MEM_WRITE) begin
					addr_w = addr_r + ptr_inc_r;
					last_w = addr_r + ptr_inc_r;
					if (addr_w < addr_r) begin
						addr_w = addr_r;
						last_w = addr_r;
					end
				end
				else begin //READ
					if(!i_speed[3])begin //fast or normal
						addr_w = addr_r + ptr_inc_r;
						if(addr_w > last_r || addr_w < addr_r) begin
							if(i_repeat) addr_w = 0;
							else addr_w = addr_r;
						end
						data_read_out_w = io_sram_dq;
					end
					else begin//slow
						if(!i_interpolate) begin
							if(slow_cnt_r == i_speed[2:0])begin
								slow_cnt_w = 0;
								addr_w = addr_r + ptr_inc_r;
								if(addr_w > last_r || addr_w < addr_r) begin
									if(i_repeat) addr_w = 0;
									else addr_w = addr_r;
								end
							end
							else begin
								addr_w = addr_r;
								slow_cnt_w = slow_cnt_r + 1;
							end
							data_read_out_w = io_sram_dq;
						end
						else begin
							if(slow_cnt_r == i_speed[2:0]) begin
								slow_cnt_w = 0;
								addr_w = addr_r + ptr_inc_r;
								prev_data_w = io_sram_dq;
								data_read_out_w = io_sram_dq;
								if(addr_w > last_r || addr_w < addr_r) begin
									if(i_repeat) addr_w = 0;
									else addr_w = addr_r;
								end
							end
							else begin
								slow_cnt_w = slow_cnt_r + 1;
								data_read_out_w = ((prev_data_r*(i_speed[2:0] + 1 - slow_cnt_r)) / (i_speed[2:0]+1)) + ((io_sram_dq*slow_cnt_r)/(i_speed[2:0]+1));
							end
						end
					end
				end
			end
            PTR_RIGHT: begin
                addr_w = addr_r + ptr_inc_r * 2;
                if (addr_w > last_r) begin
                    if (i_repeat) addr_w = 0;
                    else addr_w = last_r;
                end
            end
            PTR_LEFT: begin
                addr_w = addr_r - ptr_inc_r * 2;
                if (addr_w > addr_r) begin
                    if (i_repeat) addr_w = last_r;
                    else addr_w = 0;
                end
            end
		endcase
	end
	if (i_mem_start) begin
		case(i_mem_action)
			MEM_READ: begin
				o_sram_we = 1;
				o_sram_ce = 0;
				o_sram_oe = 0;
				o_sram_lb = 0;
				o_sram_ub = 0;
			end
			MEM_WRITE: begin
				o_sram_we = 0;
				o_sram_ce = 0;
				o_sram_oe = 1'bz;
				o_sram_lb = 0;
				o_sram_ub = 0;
			end
		endcase
	end
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		addr_r <= 0;
		last_r <= 0;
		ptr_inc_r <= 1;
		slow_cnt_r <=0;
		prev_data_r <=0;
		data_read_out_r <= '0;
	end
	else begin
		addr_r <= addr_w;
		last_r <= last_w;
		ptr_inc_r <= ptr_inc_w;
		slow_cnt_r <= slow_cnt_w;
		prev_data_r <= prev_data_w;
		data_read_out_r <= data_read_out_w;
	end
end
endmodule
