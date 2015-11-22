module SRamMgr(
	input i_clk,
	input i_rst,
	input i_rst_ptr,
	input i_ptr_type,
	input i_bePtrMove,
	input[3:0] i_speed,
	input i_beSlow,
	//input beRerverse,
	inout[15:0] io_sram_dq,
	//input[15:0] i_data_read,
	//output[15:0] o_data_write,
	output o_sram_oe,
	output o_sram_we,
	output o_sram_ce,
	output o_sram_lb,
	output o_sram_ub,
	output[19:0] o_sram_addr,

)
localparam PTR_DUMMY=0;
localparam PTR_WRITE=1;
localparam PTR_READ=2;
//logic sram_oe_w,sram_we_r,sram_ce,sram_lb,sram_ub;
//logic[19:0] sram_addr_w,;
//logic[15:0] sram_dq;

//assign o_sram_oe = o_sram_oe;
//assign sram_we = o_sram_we;
//assign sram_ce = o_sram_ce;
//assign sram_lb = o_sram_lb;
//assign sram_ub = o_sram_ub;
logic[2:0] ptr_inc_r,ptr_inc_w;
logic[19:0] addr_r,addr_w;

assign o_sram_addr = addr_r;
assign DATA_CON= 16'b0;



always_comb begin
	if(i_rst_ptr)begin
		//reset mem ptr
	end

	if(i_beSlow == 0)begin
		ptr_inc_w = i_bePtrMove * i_speed;
	end
	else begin
		//interploation
	end
	case(i_ptr_type):
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
			io_sram_dq = Q__Q;
		end
		PTR_READ:begin
			o_sram_we = 1;
			o_sram_ce = 0;
			o_sram_oe = 0;
			o_sram_lb = 0;
			o_sram_ub = 0;
			io_sram_dq = 16'bz;
		end
	endcase
	addr_w = addr_r + ptr_inc_r;
	//o_data_write = io_sram_dq;
	//i_data_read = io_sram_dq;
end


//module inout_port(input i_oe, inout io_sda,input i_o);
//logic i, o;
//assign io_sda = i_oe? i_o: 1'bz;
//endmodule
