module SRamMgr(
	input i_clk,
	input i_rst_n,
	
	input i_ptr_start,
	input i_mem_start,
	input [1:0] i_ptr_action,
	input [1:0] i_mem_action,
	input [15:0] i_data,
	
	output [19:0] o_sram_addr,
	inout [15:0] io_sram_dq,

	output o_sram_oe,
	output o_sram_we,
	output o_sram_ce,
	output o_sram_lb,
	output o_sram_ub,
);

localparam PTR_PAUSE = 0;
localparam PTR_START = 1;
localparam PTR_RESET = 2;

localparam MEM_ECHO = 0;
localparam MEM_WRITE = 1;
localparam MEM_READ = 2;


logic[2:0] ptr_inc_r, ptr_inc_w;
logic[19:0] addr_r, addr_w, last_r, last_w;

assign o_sram_addr = addr_r;
assign io_sram_dq = (i_mem_action == MEM_READ)? 16'bz: i_data;

always_comb begin
	ptr_inc_w = ptr_inc_r;
	addr_w = addr_r;
	last_w = last_r;
	
	o_sram_we = 1;
	o_sram_ce = 0;
	o_sram_oe = 1;
	o_sram_lb = 1'bz;
	o_sram_ub = 1'bz;
	if (i_ptr_start) begin
		case(i_ptr_action)
			PTR_PAUSE: begin
			end
			PTR_START: begin
				addr_w = addr_r + ptr_inc_r;
				if (i_mem_action == MEM_WRITE) last_w = addr_r + ptr_inc_r;
				else begin
					if (addr_r + ptr_inc_r > last_r) addr_w = 0;
				end
			end
			PTR_RESET: begin
				addr_w = 0;
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
	end
	else begin
		addr_r <= addr_w;
		last_r <= last_w;
		ptr_inc_r <= ptr_inc_w;
	end
end
endmodule
