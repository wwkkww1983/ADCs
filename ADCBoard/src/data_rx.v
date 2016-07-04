// data_rx.v
// Receives serial data from the LTC2385/2386/2387 
// One or two lane, DDR mode
// 16 or 18 bits
// DJS 10/20/15

module data_rx (
  input wire bits_18,		//'high' for 18 bits, 'low' for 16 bits
  input wire two_lane,  	//'high' for two lane operation
  input wire dco,				// Echoed data clock from LTC2385/2386/2387
  input wire da,				// Lane A data from LTC2385/2386/2387
  input wire db,				// Lane B data from LTC2385/2386/2387
  input wire LATCH,			// Update data outputs on rising edge of this clock
  output reg [17:0] dout   // 18-bit conversion result
);

// Local wires and registers
reg [8:0] bits_even;
reg [8:0] bits_odd;
reg [4:0] bits_even_rise;
reg [4:0] bits_odd_rise;
reg [4:0] bits_even_fall;
reg [4:0] bits_odd_fall;

always @ (posedge dco)
begin
	if(bits_18)
	begin
		if(two_lane)
		begin
			bits_odd_rise <= {bits_odd_rise[3:0],da};	//left shift every other value of 'DA' into the array 'bits_odd_rise'  
			bits_even_rise <= {bits_even_rise[3:0],db};	//left shift every other value of 'DB' into the array 'bits_even_rise'
		end
		else
			bits_odd <= {bits_odd[7:0],da};	//left shift the latest value of 'DA' into the array 'bits_odd'		
	end
	else
	begin
		if(two_lane)
		begin
			bits_odd_rise <= {bits_odd_rise[2:0],da};	//left shift every other value of 'DA' into the array 'bits_odd_rise'  
			bits_even_rise <= {bits_even_rise[2:0],db};	//left shift every other value of 'DB' into the array 'bits_even_rise'
		end
		else
			bits_odd <= {bits_odd[6:0],da};	//left shift the latest value of 'DA' into the array 'bits_odd'			
	end
end
  
always @ (negedge dco)
begin
	if(bits_18)
	begin	
		if(two_lane)
		begin
			bits_odd_fall <= {bits_odd_fall[3:0],da};	//left shift every other value of 'DA' into the array 'bits_odd_fall'  
			bits_even_fall <= {bits_even_fall[3:0],db};	//left shift every other value of 'DB' into the array 'bits_even_fall'
		end
		else
			bits_even <= {bits_even[7:0],da};	//left shift the latest value of 'DA' into the array 'bits_even'
	end
	else
	begin	
		if(two_lane)
		begin
			bits_odd_fall <= {bits_odd_fall[2:0],da};	//left shift every other value of 'DA' into the array 'bits_odd_fall'  
			bits_even_fall <= {bits_even_fall[2:0],db};	//left shift every other value of 'DB' into the array 'bits_even_fall'
		end
		else
			bits_even <= {bits_even[6:0],da};	//left shift the latest value of 'DA' into the array 'bits_even'
	end
end

always @ (posedge LATCH) //load the deserialized bits into the parallel bus on the rising edge of 'LATCH'
begin	
  if(bits_18)
  begin
      if(two_lane)
      begin
		    dout[17] <= bits_odd_rise[4];
		    dout[16] <= bits_even_rise[4];
		    dout[15] <= bits_odd_fall[4];
		    dout[14] <= bits_even_fall[4];
		    dout[13] <= bits_odd_rise[3];
		    dout[12] <= bits_even_rise[3];
		    dout[11] <= bits_odd_fall[3];
		    dout[10] <= bits_even_fall[3];
		    dout[9] <= bits_odd_rise[2];
		    dout[8] <= bits_even_rise[2];
		    dout[7] <= bits_odd_fall[2];
		    dout[6] <= bits_even_fall[2];
		    dout[5] <= bits_odd_rise[1];
		    dout[4] <= bits_even_rise[1];
		    dout[3] <= bits_odd_fall[1];
		    dout[2] <= bits_even_fall[1];
		    dout[1] <= bits_odd_rise[0];
		    dout[0] <= bits_even_rise[0];
		  end
		else
      begin
		    dout[17] <= bits_odd[8];
		    dout[16] <= bits_even[8];
		    dout[15] <= bits_odd[7];
		    dout[14] <= bits_even[7];
		    dout[13] <= bits_odd[6];
		    dout[12] <= bits_even[6];
		    dout[11] <= bits_odd[5];
		    dout[10] <= bits_even[5];
		    dout[9] <= bits_odd[4];
		    dout[8] <= bits_even[4];
		    dout[7] <= bits_odd[3];
		    dout[6] <= bits_even[3];
		    dout[5] <= bits_odd[2];
		    dout[4] <= bits_even[2];
		    dout[3] <= bits_odd[1];
		    dout[2] <= bits_even[1];
		    dout[1] <= bits_odd[0];
		    dout[0] <= bits_even[0];
      end		    
  end  
  
  else
  begin
      if(two_lane)
      begin
		    dout[15] <= bits_odd_rise[3];
		    dout[14] <= bits_even_rise[3];
		    dout[13] <= bits_odd_fall[3];
		    dout[12] <= bits_even_fall[3];
		    dout[11] <= bits_odd_rise[2];
		    dout[10] <= bits_even_rise[2];
		    dout[9] <= bits_odd_fall[2];
		    dout[8] <= bits_even_fall[2];
		    dout[7] <= bits_odd_rise[1];
		    dout[6] <= bits_even_rise[1];
		    dout[5] <= bits_odd_fall[1];
		    dout[4] <= bits_even_fall[1];
		    dout[3] <= bits_odd_rise[0];
		    dout[2] <= bits_even_rise[0];
		    dout[1] <= bits_odd_fall[0];
		    dout[0] <= bits_even_fall[0];
		  end
		  else
      begin
		    dout[15] <= bits_odd[7];
		    dout[14] <= bits_even[7];
		    dout[13] <= bits_odd[6];
		    dout[12] <= bits_even[6];
		    dout[11] <= bits_odd[5];
		    dout[10] <= bits_even[5];
		    dout[9] <= bits_odd[4];
		    dout[8] <= bits_even[4];
		    dout[7] <= bits_odd[3];
		    dout[6] <= bits_even[3];
		    dout[5] <= bits_odd[2];
		    dout[4] <= bits_even[2];
		    dout[3] <= bits_odd[1];
		    dout[2] <= bits_even[1];
		    dout[1] <= bits_odd[0];
		    dout[0] <= bits_even[0];
      end		    
  end
end

endmodule