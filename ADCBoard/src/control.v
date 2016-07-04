// control.v
// Master timing controller for the LTC2385/2386/2387
// One or two lane, DDR mode
// 16 or 18 bits
// 5/10/15MHz output data rate, 5/10/15MHz input clock
// DJS 10/20/15
//
// All timing is controlled by a counter that is clocked by the fast clock clk.
// At certain counter values, the following things happen:
//		cnv_en <= 1			enable external FF to create the rising edge of CNV
//		cnv_en <= 0			cause the falling edge of CNV
//		clk_en <= 1			create pulse on clk_en to send CLK pulses to LTC2387
//		clk_en <= 0
//		LATCH <=1	update data outputs
//		LATCH <=0	falling edge used by DC890B to latch data

module control (
  input wire bits_18,
  input wire two_lane,
  input wire clk,		// high speed master clock
  input wire sync,	// set counter when sync is high
  output reg cnv_en,	// =0 resets the external FF used to retime CLK_IN to make CNV
  output reg clk_en,	// enables CLK pulses to ADC
  output reg LATCH	// signal to latch the data, then latch data to DC890B on falling edge
);

// Local Parameters
parameter [5:0] start_count = 5'd23;	// Initial value for counter. Set when sync is high.
parameter [5:0] tcnvenl = 5'd21;  		// Time for cnv_en to go low; 4 high speed clock cycle after CLKIN rising edge
parameter [5:0] tcnvenh = 5'd4;			// Time for cnv_en to go high; 21 high speed clock cycle after CLKIN rising edge
parameter [5:0] tclkonh = 5'd3;			// Time for clk_en to go high; 22 high speed clock cycle after CLKIN rising edge

reg [5:0] tclkonl;
reg [5:0] tupdateh;
reg [5:0] tupdatel;

always @(clk)
begin
  if(two_lane)
	begin
    if(bits_18)
		  tclkonl = 5'd22;		// Time for clk_en to go low; 3 high speed clock cycle after CLKIN rising edge
	 else
		  tclkonl = 5'd23;		// Time for clk_en to go low; 2 high speed clock cycle after CLKIN rising edge
	 tupdateh = 5'd19;			// Time for LATCH to go high; 6 high speed clock cycle after CLKIN rising edge
	 tupdatel = 5'd16;			// Time for LATCH to go low; 9 high speed clock cycle after CLKIN rising edge
	end
  else
	begin
	 if(bits_18)
		  tclkonl = 5'd18;		// Time for clk_en to go low; 7 high speed clock cycle after CLKIN rising edge  
	 else
		  tclkonl = 5'd19;		// Time for clk_en to go low; 6 high speed clock cycle after CLKIN rising edge
	 tupdateh = 5'd15;			// Time for LATCH to go high; 10 high speed clock cycle after CLKIN rising edge
	 tupdatel = 5'd12;			// Time for LATCH to go low; 13 high speed clock cycle after CLKIN rising edge
	end
end
  
// Local wires and registers
reg [5:0] count;						// master counter

// Main
always @ (posedge clk)
    if (sync)
		  count <= start_count;
	 else 
		  count <= count - 1'b1;		
		
always @ (posedge clk)
	if (count == tcnvenh)
		cnv_en <= 1'b1;
	else if (count == tcnvenl)
		cnv_en <= 1'b0;
	else
		cnv_en <= cnv_en;		
		
always @ (posedge clk)
	if (count == tupdateh)
		LATCH <= 1'b1;
	else if (count == tupdatel)
		LATCH <= 1'b0;
	else
		LATCH <= LATCH;
		
always @ (posedge clk)
	if (count == tclkonh)
		clk_en <= 1'b1;
	else if (count == tclkonl)
		clk_en <= 1'b0;
	else
		clk_en <= clk_en;

endmodule