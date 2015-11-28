module DE2_115(
	input CLOCK_50,
	input CLOCK2_50,
	input CLOCK3_50,
	input ENETCLK_25,
	input SMA_CLKIN,
	output SMA_CLKOUT,
	output [8:0] LEDG,
	output [17:0] LEDR,
	input [3:0] KEY,
	input [17:0] SW,
	output [6:0] HEX0,
	output [6:0] HEX1,
	output [6:0] HEX2,
	output [6:0] HEX3,
	output [6:0] HEX4,
	output [6:0] HEX5,
	output [6:0] HEX6,
	output [6:0] HEX7,
	output LCD_BLON,
	inout [7:0] LCD_DATA,
	output LCD_EN,
	output LCD_ON,
	output LCD_RS,
	output LCD_RW,
	output UART_CTS,
	input UART_RTS,
	input UART_RXD,
	output UART_TXD,
	inout PS2_CLK,
	inout PS2_DAT,
	inout PS2_CLK2,
	inout PS2_DAT2,
	output SD_CLK,
	inout SD_CMD,
	inout [3:0] SD_DAT,
	input SD_WP_N,
	output [7:0] VGA_B,
	output VGA_BLANK_N,
	output VGA_CLK,
	output [7:0] VGA_G,
	output VGA_HS,
	output [7:0] VGA_R,
	output VGA_SYNC_N,
	output VGA_VS,
	input AUD_ADCDAT,
	inout AUD_ADCLRCK,
	inout AUD_BCLK,
	output AUD_DACDAT,
	inout AUD_DACLRCK,
	output AUD_XCK,
	output EEP_I2C_SCLK,
	inout EEP_I2C_SDAT,
	output I2C_SCLK,
	inout I2C_SDAT,
	output ENET0_GTX_CLK,
	input ENET0_INT_N,
	output ENET0_MDC,
	input ENET0_MDIO,
	output ENET0_RST_N,
	input ENET0_RX_CLK,
	input ENET0_RX_COL,
	input ENET0_RX_CRS,
	input [3:0] ENET0_RX_DATA,
	input ENET0_RX_DV,
	input ENET0_RX_ER,
	input ENET0_TX_CLK,
	output [3:0] ENET0_TX_DATA,
	output ENET0_TX_EN,
	output ENET0_TX_ER,
	input ENET0_LINK100,
	output ENET1_GTX_CLK,
	input ENET1_INT_N,
	output ENET1_MDC,
	input ENET1_MDIO,
	output ENET1_RST_N,
	input ENET1_RX_CLK,
	input ENET1_RX_COL,
	input ENET1_RX_CRS,
	input [3:0] ENET1_RX_DATA,
	input ENET1_RX_DV,
	input ENET1_RX_ER,
	input ENET1_TX_CLK,
	output [3:0] ENET1_TX_DATA,
	output ENET1_TX_EN,
	output ENET1_TX_ER,
	input ENET1_LINK100,
	input TD_CLK27,
	input [7:0] TD_DATA,
	input TD_HS,
	output TD_RESET_N,
	input TD_VS,
	inout [15:0] OTG_DATA,
	output [1:0] OTG_ADDR,
	output OTG_CS_N,
	output OTG_WR_N,
	output OTG_RD_N,
	input OTG_INT,
	output OTG_RST_N,
	input IRDA_RXD,
	output [12:0] DRAM_ADDR,
	output [1:0] DRAM_BA,
	output DRAM_CAS_N,
	output DRAM_CKE,
	output DRAM_CLK,
	output DRAM_CS_N,
	inout [31:0] DRAM_DQ,
	output [3:0] DRAM_DQM,
	output DRAM_RAS_N,
	output DRAM_WE_N,
	output [19:0] SRAM_ADDR,
	output SRAM_CE_N,
	inout [15:0] SRAM_DQ,
	output SRAM_LB_N,
	output SRAM_OE_N,
	output SRAM_UB_N,
	output SRAM_WE_N,
	output [22:0] FL_ADDR,
	output FL_CE_N,
	inout [7:0] FL_DQ,
	output FL_OE_N,
	output FL_RST_N,
	input FL_RY,
	output FL_WE_N,
	output FL_WP_N,
	inout [35:0] GPIO,
	input HSMC_CLKIN_P1,
	input HSMC_CLKIN_P2,
	input HSMC_CLKIN0,
	output HSMC_CLKOUT_P1,
	output HSMC_CLKOUT_P2,
	output HSMC_CLKOUT0,
	inout [3:0] HSMC_D,
	input [16:0] HSMC_RX_D_P,
	output [16:0] HSMC_TX_D_P,
	inout [6:0] EX_IO
);

	logic [7:0] p[31:0];
	logic clk_12m, clk_100k;
	logic [31:0] debug;
	logic rst, rst_n;
	logic [17:0] sw;
	
	wire DLY_RST;
	assign LCD_ON = 1'b1;
	assign LCD_BLON = 1'b1;
	assign {p[0],p[1],p[2],p[3],p[4],p[5],p[6],p[7],p[8],p[9],p[10],p[11],p[12],p[13],p[14],p[15]}           = "we are DCLAB Q_Q";
	assign {p[16],p[17],p[18],p[19],p[20],p[21],p[22],p[23],p[24],p[25],p[26],p[27],p[28],p[29],p[30],p[31]} = "Coooooooooooooon";
	
	assign AUD_XCK = clk_12m;
	//assign debug = AUD_ADCDAT*10 + AUD_ADCLRCK;
	//assign debug[7:5] = sw[2:0];
	//assign debug[4] = rst;
	//assign debug[2:0] = SW[2:0];
	//assign debug[3] = 1'b1;
	
	Debounce deb_rst(
		.i_in(KEY[0]),
		.i_clk(CLOCK_50),
		.o_debounced(rst_n)
	);
	Debounce deb_sw0(
		.i_in(SW[0]),
		.i_clk(CLOCK_50),
		.o_debounced(sw[0])
	);
	Debounce deb_sw1(
		.i_in(SW[1]),
		.i_clk(CLOCK_50),
		.o_debounced(sw[1])
	);
	Debounce deb_sw2(
		.i_in(SW[2]),
		.i_clk(CLOCK_50),
		.o_debounced(sw[2])
	);
	Debounce deb_sw3(
		.i_in(SW[3]),
		.i_clk(CLOCK_50),
		.o_debounced(sw[3])
	);
	Debounce deb_sw4(
		.i_in(SW[4]),
		.i_clk(CLOCK_50),
		.o_debounced(sw[4])
	);
	Debounce deb_sw5(
		.i_in(SW[5]),
		.i_clk(CLOCK_50),
		.o_debounced(sw[5])
	);
	Debounce deb_sw6(
		.i_in(SW[6]),
		.i_clk(CLOCK_50),
		.o_debounced(sw[6])
	);
	Debounce deb_sw7(
		.i_in(SW[7]),
		.i_clk(CLOCK_50),
		.o_debounced(sw[7])
	);
	SevenHexDecoder seven_dec0(
		.i_hex(debug),
		.o_seven_1(HEX0),
		.o_seven_2(HEX1),
		.o_seven_3(HEX2),
		.o_seven_4(HEX3),
		.o_seven_5(HEX4),
		.o_seven_6(HEX5),
		.o_seven_7(HEX6),
		.o_seven_8(HEX7)
	);
	Reset_Delay r0(
		.i_clk(CLOCK_50),
		.o_rst(DLY_RST)
	);
	LCD_TEST lcd0(    
		//    Host Side
		.i_clk(CLOCK_50),
      .i_RST_N(DLY_RST),
		.i_p(p),
      //    LCD Side
      .LCD_DATA(LCD_DATA),
      .LCD_RW(LCD_RW),
      .LCD_EN(LCD_EN),
      .LCD_RS(LCD_RS)
	);
	Main m0(
		.i_clk_12m(clk_12m),
		.i_clk_100k(clk_100k),
		.i_rst_n(rst_n),
		
		.o_sclk(I2C_SCLK),
		.io_sdat(I2C_SDAT),

		.i_aud_adclrck(AUD_ADCLRCK),
		.i_aud_adcdat(AUD_ADCDAT),
		.i_aud_daclrck(AUD_DACLRCK),
		.o_aud_dacdat(AUD_DACDAT),
		.i_aud_bclk(AUD_BCLK),

		.i_sw(sw[7:0]),
		
		.debug(debug)
		
		/*
		.io_sram_dq(SRAM_DQ),
		.o_sram_oe(SRAM_OE_N),
		.o_sram_we(SRAM_WE_N),
		.o_sram_ce(SRAM_CE_N),
		.o_sram_lb(SRAM_LB_N),
		.o_sram_ub(SRAM_UB_N),
		.o_sram_addr(SRAM_ADDR)
		*/
	);
	//SetCodec init(
	//);
	lab3 qsys(
		.clk_clk(CLOCK_50),
		.id100k_clk(clk_100k),
		.id12m_clk(clk_12m),
		.reset_reset_n(rst_n)
	);
endmodule
