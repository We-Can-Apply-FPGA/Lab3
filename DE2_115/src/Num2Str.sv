module Num2Str(
	input  [31:0] i_num,
	output [7:0] o_tens,
	output [7:0] o_ones
);

logic [31:0] number;
logic [7:0] tens_char;
logic [7:0] ones_char;
logic [4:0] tens;
logic [4:0] ones;

assign number = i_num;
assign o_ones = ones_char;
assign o_tens = tens_char;

logic [7:0] mapping [0:10];
assign mapping[0]  = "0";
assign mapping[1]  = "1";
assign mapping[2]  = "2";
assign mapping[3]  = "3";
assign mapping[4]  = "4";
assign mapping[5]  = "5";
assign mapping[6]  = "6";
assign mapping[7]  = "7";
assign mapping[8]  = "8";
assign mapping[9]  = "9";
assign mapping[10] = "X";

always_comb begin
	tens = number / 10;
	ones = number - (tens*10);
	tens_char = mapping[tens];
	ones_char = mapping[ones];
end

endmodule
