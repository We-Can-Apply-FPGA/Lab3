module SRamMgr(
	input i_clk,
	input i_rst_n,
	
	input i_mode,
	input [3:0] i_speed,
	input i_interpolate,
	input i_repeat,
	input [3:0] i_ptr_action,
	input [3:0] i_mem_action,
	input [15:0] i_data,
	output [15:0] o_data_read_out,
	
	output [19:0] o_sram_addr,
	inout signed [15:0] io_sram_dq,
	output o_sram_oe,
	output o_sram_we,
	output o_sram_ce,
	output o_sram_lb,
	output o_sram_ub
);
`include "define.sv"
logic [19:0] addr_r, addr_w, last_r, last_w;
logic [15:0] data_r, data_w;
logic [2:0] slow_cnt_r, slow_cnt_w;
logic signed [15:0] prev_data_r, prev_data_w, tmpa, tmpb, tmp;
logic signed [15:0] data_read_out_r, data_read_out_w;

assign o_sram_addr = addr_r;
assign io_sram_dq = (i_mem_action == MEM_READ)? 16'bz: i_data;
assign o_data_read_out = data_read_out_r;

always_comb begin
	addr_w = addr_r;
	last_w = last_r;
	slow_cnt_w = slow_cnt_r;
	prev_data_w = prev_data_r;
	data_read_out_w = data_read_out_r;
	
	o_sram_we = 1;
	o_sram_ce = 0;
	o_sram_oe = 1;
	o_sram_lb = 1'bz;
	o_sram_ub = 1'bz;
	tmp = 0;
	tmpa = 0;
	tmpb = 0;
	
	case(i_ptr_action)
		PTR_RESET: begin
			addr_w = 0;
		end
		PTR_PAUSE: begin
		end
		PTR_START: begin
			if (i_mem_action == MEM_WRITE) begin
				addr_w = addr_r + 1;
				last_w = addr_w;
				if (addr_w < addr_r) begin
					addr_w = addr_r;
					last_w = addr_r;
				end
			end
			else begin //READ
				if(!i_speed[3]) begin //fast or normal
					addr_w = addr_r + i_speed[2:0] + 1;
					if(addr_w > last_r || addr_w < addr_r) begin
						if(i_repeat) addr_w = 0;
						else addr_w = addr_r;
					end
					data_read_out_w = io_sram_dq;
				end
				else begin//slow
					if(!i_interpolate) begin
						if(slow_cnt_r == 0) begin
							slow_cnt_w = i_speed[2:0];
							addr_w = addr_r + 1;
							if(addr_w > last_r || addr_w < addr_r) begin
								if(i_repeat) addr_w = 0;
								else addr_w = addr_r;
							end
						end
						else slow_cnt_w = slow_cnt_r - 1;
						data_read_out_w = io_sram_dq;
					end
					else begin
						if(slow_cnt_r == 0) begin
							slow_cnt_w = i_speed[2:0];
							addr_w = addr_r + 1;
							if(addr_w > last_r || addr_w < addr_r) begin
								if(i_repeat) addr_w = 0;
								else addr_w = addr_r;
							end
							prev_data_w = io_sram_dq;
							data_read_out_w = io_sram_dq;
							//data_read_out_w = 0;
						end
						else begin
							//tmp = io_sram_dq - prev_data_r;
							/*
							if (prev_data_r > io_sram_dq) begin
								data_read_out_w = data_read_out_r - ((prev_data_r - io_sram_dq) >> 1);
							end
							else begin
								data_read_out_w = data_read_out_r + ((io_sram_dq - prev_data_r) >> 1);
							end*/
							case (i_speed[2:0])
								1: data_read_out_w = data_read_out_r + ((io_sram_dq - prev_data_r) / 2);
								2: data_read_out_w = data_read_out_r + ((io_sram_dq - prev_data_r) / 3);
								3: data_read_out_w = data_read_out_r + ((io_sram_dq - prev_data_r) / 4);
								4: data_read_out_w = data_read_out_r + ((io_sram_dq - prev_data_r) / 5);
								5: data_read_out_w = data_read_out_r + ((io_sram_dq - prev_data_r) / 6);
								6: data_read_out_w = data_read_out_r + ((io_sram_dq - prev_data_r) / 7);
								7: data_read_out_w = data_read_out_r + ((io_sram_dq - prev_data_r) / 8);
							endcase
							slow_cnt_w = slow_cnt_r - 1;
							/*
							if (io_sram_dq - prev_data)
							if (prev_data_r[15]) begin
								tmpa = ~((~prev_data_r) >> 1);
							end
							else begin
								tmpa = prev_data_r * slow_cnt_r / (i_speed[2:0] + 1);
							end*/
							/*
							if (prev_data_r[15]) begin
								tmpa = ~((~prev_data_r) >> 1);
							end
							else begin
								tmpa = prev_data_r / 2;
							end*//*
							if (io_sram_dq[15]) begin
								tmpb = ~((~io_sram_dq) >> 1);
							end
							else begin
								tmpb = io_sram_dq * (i_speed[2:0] + 1 - slow_cnt_r) / (i_speed[2:0] + 1);
							end*/
							/*
							if ((prev_data_r[15] && tmpa[15]) || (!prev_data_r[15] && !tmpa[15])) data_read_out_w = 0;
							else data_read_out_w = tmpa;*/
							//data_read_out_w = tmpa+tmpb;
							//	+ io_sram_dq * (i_speed[2:0] + 1 - slow_cnt_r) / (i_speed[2:0] + 1);
						end
					end
				end
			end
		end
		PTR_RIGHT: begin
			addr_w = addr_r + 2;
			if (addr_w > last_r) begin
				if (i_repeat) addr_w = 0;
				else addr_w = last_r;
			end
		end
		PTR_LEFT: begin
			addr_w = addr_r - 2;
			if (addr_w > addr_r) begin
				if (i_repeat) addr_w = last_r;
				else addr_w = 0;
			end
		end
	endcase
	
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

always_ff @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		data_r <= 0;
		addr_r <= 0;
		last_r <= 0;
		slow_cnt_r <=0;
		prev_data_r <=0;
		data_read_out_r <= '0;
	end
	else begin
		data_r <= data_w;
		addr_r <= addr_w;
		last_r <= last_w;
		slow_cnt_r <= slow_cnt_w;
		prev_data_r <= prev_data_w;
		data_read_out_r <= data_read_out_w;
	end
end
endmodule
