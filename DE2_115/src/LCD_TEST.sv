module LCD_TEST (
	//    Host Side
	input i_clk,
	input i_RST_N,
	input reg [7:0] i_p[31:0],
	//    LCD Side
	output [7:0] LCD_DATA,
	output LCD_RW,
	output LCD_EN,
	output LCD_RS
);

	//    Internal Wires/Registers
	reg [5:0] LUT_INDEX;
	reg [8:0] LUT_DATA;
	reg [5:0] mLCD_ST;
	reg [17:0] mDLY;
	reg mLCD_Start;
	reg [7:0] mLCD_DATA;
	reg mLCD_RS;
	wire mLCD_Done;

	parameter LCD_INTIAL = 0;
	parameter LCD_LINE1 = 5;
	parameter LCD_CH_LINE = LCD_LINE1+16;
	parameter LCD_LINE2 = LCD_LINE1+16+1;
	parameter LUT_SIZE = LCD_LINE1+32+1;

	always @(posedge i_clk or negedge i_RST_N) begin
		if (!i_RST_N) begin
			LUT_INDEX <= 0;
			mLCD_ST <= 0;
			mDLY <= 0;
			mLCD_Start <= 0;
			mLCD_DATA <= 0;
			mLCD_RS <= 0;
		end
		else begin
			if(LUT_INDEX<LUT_SIZE) begin
				case(mLCD_ST)
					0:begin
						mLCD_DATA <= LUT_DATA[7:0];
						mLCD_RS <= LUT_DATA[8];
						mLCD_Start <= 1;
						mLCD_ST <= 1;
					end
					1:begin
						if(mLCD_Done) begin
							mLCD_Start <= 0;
							mLCD_ST <= 2;                    
						end
					end
					2:begin
						if(mDLY<18'h3FFFE)    // 5.2ms
							mDLY <= mDLY + 1;
						else begin
							mDLY <= 0;
							mLCD_ST <= 3;
						end
					end
					3:begin
						LUT_INDEX <= LUT_INDEX + 1;
						mLCD_ST <= 0;
					end
				endcase
			end
		end
	end

	always begin
		case(LUT_INDEX)
			//    Initial
			LCD_INTIAL+0:LUT_DATA <= 9'h038; //Fun set
			LCD_INTIAL+1:LUT_DATA <= 9'h00C; //dis on
			LCD_INTIAL+2:LUT_DATA <= 9'h001; //clr dis
			LCD_INTIAL+3:LUT_DATA <= 9'h006; //Ent mode
			LCD_INTIAL+4:LUT_DATA <= 9'h080; //set ddram address
			//    Line 1
			LCD_LINE1+0:LUT_DATA <= (9'h100 + i_p[0]);
			LCD_LINE1+1:LUT_DATA <= (9'h100 + i_p[1]);
			LCD_LINE1+2:LUT_DATA <= (9'h100 + i_p[2]);
			LCD_LINE1+3:LUT_DATA <= (9'h100 + i_p[3]);
			LCD_LINE1+4:LUT_DATA <= (9'h100 + i_p[4]);
			LCD_LINE1+5:LUT_DATA <= (9'h100 + i_p[5]);
			LCD_LINE1+6:LUT_DATA <= (9'h100 + i_p[6]);
			LCD_LINE1+7:LUT_DATA <= (9'h100 + i_p[7]);
			LCD_LINE1+8:LUT_DATA <= (9'h100 + i_p[8]);
			LCD_LINE1+9:LUT_DATA <= (9'h100 + i_p[9]);
			LCD_LINE1+10:LUT_DATA <= (9'h100 + i_p[10]);
			LCD_LINE1+11:LUT_DATA <= (9'h100 + i_p[11]);
			LCD_LINE1+12:LUT_DATA <= (9'h100 + i_p[12]);
			LCD_LINE1+13:LUT_DATA <= (9'h100 + i_p[13]);
			LCD_LINE1+14:LUT_DATA <= (9'h100 + i_p[14]);
			LCD_LINE1+15:LUT_DATA <= (9'h100 + i_p[15]);
			//    Change Line
			LCD_CH_LINE:LUT_DATA <= 9'h0C0;
			//    Line 2
			LCD_LINE2+0:LUT_DATA <= (9'h100 + i_p[16]);
			LCD_LINE2+1:LUT_DATA <= (9'h100 + i_p[17]);
			LCD_LINE2+2:LUT_DATA <= (9'h100 + i_p[18]);
			LCD_LINE2+3:LUT_DATA <= (9'h100 + i_p[19]);
			LCD_LINE2+4:LUT_DATA <= (9'h100 + i_p[20]);
			LCD_LINE2+5:LUT_DATA <= (9'h100 + i_p[21]);
			LCD_LINE2+6:LUT_DATA <= (9'h100 + i_p[22]);
			LCD_LINE2+7:LUT_DATA <= (9'h100 + i_p[23]);
			LCD_LINE2+8:LUT_DATA <= (9'h100 + i_p[24]);
			LCD_LINE2+9:LUT_DATA <= (9'h100 + i_p[25]);
			LCD_LINE2+10:LUT_DATA <= (9'h100 + i_p[26]);
			LCD_LINE2+11:LUT_DATA <= (9'h100 + i_p[27]);
			LCD_LINE2+12:LUT_DATA <= (9'h100 + i_p[28]);
			LCD_LINE2+13:LUT_DATA <= (9'h100 + i_p[29]);
			LCD_LINE2+14:LUT_DATA <= (9'h100 + i_p[30]);
			LCD_LINE2+15:LUT_DATA <= (9'h100 + i_p[31]);
			default:LUT_DATA <= 9'h000;
		endcase
	end

	LCD_Controller u0 (
		//    Host Side
		.iDATA(mLCD_DATA),
		.iRS(mLCD_RS),
		.iStart(mLCD_Start),
		.oDone(mLCD_Done),
		.i_clk(i_clk),
		.i_RST_N(i_RST_N),
		//    LCD Interface
		.LCD_DATA(LCD_DATA),
		.LCD_RW(LCD_RW),
		.LCD_EN(LCD_EN),
		.LCD_RS(LCD_RS)
	);
endmodule

module LCD_Controller (
	//    Host Side
	input [7:0] iDATA,
	input iRS,
	input iStart,
	output reg oDone,
	input i_clk,
	input i_RST_N,
	//    LCD Interface
	output [7:0] LCD_DATA,
	output LCD_RW,
	output reg LCD_EN,
	output LCD_RS
);
	//    CLK
	parameter CLK_Divide = 16;

	//    Internal Register
	reg [4:0] Cont;
	reg [1:0] ST;
	reg preStart,mStart;

	/////////////////////////////////////////////
	//    Only write to LCD, bypass iRS to LCD_RS
	assign LCD_DATA = iDATA; 
	assign LCD_RW = 1'b0;
	assign LCD_RS = iRS;
	/////////////////////////////////////////////

	always@(posedge i_clk or negedge i_RST_N) begin
		if (!i_RST_N) begin
			oDone <= 1'b0;
			LCD_EN <= 1'b0;
			preStart <= 1'b0;
			mStart <= 1'b0;
			Cont <= 0;
			ST <= 0;
		end
		else begin
			//////    Input Start Detect ///////
			preStart <= iStart;
			if({preStart,iStart}==2'b01) begin // latch ?
				mStart <= 1'b1;
				oDone <= 1'b0;
			end
			//////////////////////////////////
			if(mStart) begin //generate LCD_EN
				case(ST)
					0:ST <= 1;    //    Wait Setup, tAS >= 40ns
					1:begin
						LCD_EN <= 1'b1;
						ST <= 2;
					end
					2:begin                    
						if(Cont<CLK_Divide)
							Cont <= Cont+1;
						else
							ST <= 3;
					end
					3:begin
						LCD_EN <= 1'b0;
						mStart <= 1'b0;
						oDone <= 1'b1;
						Cont <= 0;
						ST <= 0;
					end
				endcase
			end
		end
	end
endmodule
