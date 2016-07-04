// Verilog code for DC2290A
// One or two lane, DDR mode
// 16 or 18 bits
// 15MHz output data rate, 15MHz input clock
// Expect 1 lane test pattern mode output: 
//   18 bit part; 164348; interpret as -97796 (min code)
//   16 bit part; 41087; interpret as -24449 (min code)
// Expect 2 lane test pattern mode output:
//   18 bit part; 209148; interpret as -52996 (min code)
//   16 bit part; 52287; interpret as -13249 (min code)
// The timing constraints for this device are:
// CNV pulse width >5nsec
// Time from CNV rising edge to first CLK_ADC rising edge >TBDnsec
// DJS 6/30/15

module LTC2387 (
  // 2.5V CMOS inputs
  input wire bits_18,
  input wire two_lane,
  input wire	CLK_IN,			// Input clock. (CLKIN on schematic)
  // 2.5V CMOS outputs
  output wire [17:0] DATA,		// Data outputs. Data is LSB justified for 18-bits (D0,...D17 on schematic)
  output wire LATCH,				// Data latching signal (OUTPUT_LATCH on schematic)
  output wire CNV_EN,			// Resets CNV flip-flop (CNV_EN on schematic)
  // LVDS inputs
  input DCO_n,						// DCO from A/D (DCO- on schematic)
  input DA_n, 						// Lane A data from A/D (DA- on schematic)
  input DB_n, 						// Lane B data from A/D (DB- on schematic)
  // LVDS outputs
  output CLK_ADC_n				// Serial clock to A/D (CLK- on schematic)
);
				
// Internal wire and register definitions
wire	clk_360;						// Internal high speed clock
wire  clk_en;						// Enables transmitting output CLK
wire 	[17:0] dout;				// Data output from the receiver block
wire  sync;							// Sync pulse from pll. 3.125ns wide every 66.7ns

// Assignments
assign	DATA[17:0] = dout[17:0];	

// PLL design: clk_in = 15MHz, clk_360 = 360MHz, sync = 15MHz/5%DC/0.5ns delay
altpll0	upll(	.inclk0(CLK_IN),
					.c0(clk_360),
					.c1(sync)
					);
				
// Module to control the timing
wire dv;
control		ucontrol	( 	.bits_18(bits_18),
								.two_lane(two_lane),
								.clk(clk_360),
							   .sync(sync),
							   .cnv_en(CNV_EN),
							   .clk_en(clk_en),
							   .LATCH(LATCH)
							    );
								 
// Receives serial data from ADC
data_rx		urx		( .bits_18(bits_18),
							  .two_lane(two_lane),
							  .dco(~DCO_n),	//invert this to account for polarity reversal on DC2290A
							  .da(~DA_n),		//invert this to account for polarity reversal on DC2290A						  
							  .db(~DB_n),		//invert this to account for polarity reversal on DC2290A
							  .LATCH(LATCH),
							  .dout(dout)
							 );

// CLK DDIO output register
altddioout	uclkddr ( .datain_h(~clk_en),
							 .datain_l(1'b1),
							 .outclock(clk_360),
							 .dataout(CLK_ADC_n)
							);

endmodule