module Reset_Delay(
	input i_clk,
	output reg o_rst
);
	reg [19:0] counter;

	always@(posedge i_clk) begin
		if (counter != 20'hFFFFF) begin   //22ms
			counter <= counter + 1;
			o_rst <= 1'b0;
		end
		else
			o_rst <= 1'b1;
	end
endmodule