module SRamMgr(
	input i_clk,
	input i_rst_n,
	input i_rst_ptr,
	input[1:0] i_ptr_type,
	input i_bePtrMove,
	input[2:0] i_speed,
	input i_beSlow,
	//input beRerverse,
	inout[15:0] io_sram_dq,

	output o_sram_oe,
	output o_sram_we,
	output o_sram_ce,
	output o_sram_lb,
	output o_sram_ub,
	output[19:0] o_sram_addr,
	
	output[28:0] debug
);
localparam PTR_DUMMY=0;
localparam PTR_WRITE=1;
localparam PTR_READ=2;

logic[2:0] ptr_inc_r,ptr_inc_w;
logic[19:0] addr_r,addr_w;

assign o_sram_addr = addr_r;
localparam DATA_CON = 16'b0;
localparam ADDR_INIT = 20'b0;

always_comb begin
	ptr_inc_w = ptr_inc_r;
	addr_w = ADDR_INIT + addr_r;
	debug = 0;
	io_sram_dq = DATA_CON;
	o_sram_we = 0;
	o_sram_ce = 0;
	o_sram_oe = 0;
	o_sram_lb = 0;
	o_sram_ub = 0;
	
	if(i_rst_ptr)begin
		addr_w = ADDR_INIT;
	end
	if(i_beSlow == 0)begin
		ptr_inc_w = i_bePtrMove * (i_speed + 1);
	end
	if(i_ptr_type == PTR_READ)
		addr_w = ADDR_INIT; //This is wrong, just test!
	else begin
		//interploation
	end
	case(i_ptr_type)
		PTR_DUMMY:begin
			o_sram_we = 1;
			o_sram_ce = 0;
			o_sram_oe = 1;
			o_sram_lb = 1'bz;
			o_sram_ub = 1'bz;
			io_sram_dq = DATA_CON;
		end
		PTR_WRITE:begin
			o_sram_we = 0;
			o_sram_ce = 0;
			o_sram_oe = 1'bz;
			o_sram_lb = 0;
			o_sram_ub = 0;
			io_sram_dq = 16'b1;
			addr_w = addr_r + ptr_inc_r;
		end
		PTR_READ:begin
			o_sram_we = 1;
			o_sram_ce = 0;
			o_sram_oe = 0;
			o_sram_lb = 0;
			o_sram_ub = 0;
			io_sram_dq = 16'bz;
			debug[5:2] = io_sram_dq;
			debug[6] = 1;
		end
	endcase
	debug[1:0] = addr_r >> 18;
	//debug[4] = i_bePtrMove;
	//debug[5] = ptr_inc_w;
	//debug = debug + addr_r*100;
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		addr_r = 0;
		ptr_inc_r = 0;
	end
	else begin
		addr_r <= addr_w;
		ptr_inc_r <= ptr_inc_w;
	end
end	
endmodule
