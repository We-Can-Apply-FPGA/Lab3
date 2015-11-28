module SRamMgr(
	input i_clk,
	input i_rst_n,
	//input i_rst_ptr,
	input[1:0] i_ptr_type,
	input i_data_writein,
	input i_bePtrMove,
	input[2:0] i_speed,
	input i_beSlow,
	output o_data_readout,
	//input beRerverse,
	inout[15:0] io_sram_dq,

	output o_sram_oe,
	output o_sram_we,
	output o_sram_ce,
	output o_sram_lb,
	output o_sram_ub,
	output[19:0] o_sram_addr
	
	//output[28:0] debug
);

logic[15:0] data;
logic[2:0] addr_inc_r,addr_inc_w;
logic[19:0] addr_r,addr_w;

localparam PTR_DUMMY=0;
localparam PTR_WRITE=1;
localparam PTR_READ=2;

localparam DATA_CON = 16'b0;
localparam ADDR_FIRST = 20'b0;
localparam ADDR_LAST = 20'b1;

assign o_sram_addr = addr_r;
assign io_sram_dq = data;
assign ptr_type = i_bePtrMove?i_ptr_type:PTR_DUMMY
assign oe = (ptr_type==PTR_READ)?1:0


Task DoNoting;
	begin
		o_sram_we = 1'bz;
		o_sram_ce = 1;
		o_sram_oe = 1'bz;
		o_sram_lb = 1'bz;
		o_sram_ub = 1'bz;
	end
endtask

Task Record;
	begin
		o_sram_we = 0;
		o_sram_ce = 0;
		o_sram_oe = 1'bz;
		o_sram_lb = 0;
		o_sram_ub = 0;
		io_sram_dq = i_data_writein;
	end
endtask

Task Play;
	begin
		o_sram_we = 1;
		o_sram_ce = 0;
		o_sram_oe = 0;
		o_sram_lb = 0;
		o_sram_ub = 0;
	end
endtask


inout_port io_sram(
	.i_oe(oe),
	.io(io_sram_dq),
	.i_o(o_data_readout)
);


always_comb begin
	
	//if(i_rst_ptr)begin
		//addr_w = ADDR_FIRST;
	//end
	case(ptr_type)
		PTR_DUMMY:begin
			DoNoting();
		end
		PTR_WRITE:begin
			if((addr_r + addr_inc_r) > ADDR_LAST)begin
				DoNoting();
			end
			else begin
				Record();
			end
		end
		PTR_READ:begin
			if((addr_r + addr_inc_r > ADDR_LAST)) begin
				addr_r = 
			end
			else begin
				Play();
			end
		end
	endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		addr_r <= 0;
		addr_inc_r <= 0;
	end
	else begin
		addr_r <= addr_w;
		addr_inc_r <= addr_inc_w;
	end
end	
endmodule


module inout_port(input i_oe, inout io, input i_o);
assign io = i_oe? i_o: 1'bz;
endmodule
