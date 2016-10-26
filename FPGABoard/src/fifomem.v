////////////////////////////////////////////////////////////////
//
//  Module  : fifomem
//  Designer: Hoki
//  Company : 
//  Date    : 2015/3/5 15:44:10
//
////////////////////////////////////////////////////////////////
// 
//  Description: Memory used in FIFO design
//
////////////////////////////////////////////////////////////////
// 
//  Revision: 1.0

/////////////////////////// MODULE //////////////////////////////
module fifomem
(
   wclk ,
   wr   ,
   waddr,
   wdata,
   rclk ,
   rd   ,
   raddr,
   rdata
);

   ///////////////// PARAMETER ////////////////
   parameter p_nbit_d = 8;
   parameter p_nbit_a = 4;
   parameter p_output_reg_en = 1'b1;
   
   ////////////////// PORT ////////////////////
   input                 wclk;
   input                 wr;   
   input  [p_nbit_d-1:0] wdata;
   input  [p_nbit_a-1:0] waddr;
   input                 rclk; 
   input                 rd;
   input  [p_nbit_a-1:0] raddr;
   output [p_nbit_d-1:0] rdata; 
   
   ////////////////// ARCH ////////////////////
   
   altsyncram altsyncram_u
   (
      .address_a     (waddr),
      .clock0        (wclk),
      .data_a        (wdata),
      .wren_a        (wr),
      .address_b     (raddr),
      .q_b           (rdata),
      .aclr0         (1'b0),
      .aclr1         (1'b0),
      .addressstall_a(1'b0),
      .addressstall_b(1'b0),
      .byteena_a     (1'b1),
      .byteena_b     (1'b1),
      .clock1        (rclk),
      .clocken0      (1'b1),
      .clocken1      (1'b1),
      .clocken2      (1'b1),
      .clocken3      (1'b1),
      .data_b        ({p_nbit_d{1'b1}}),
      .eccstatus     (),
      .q_a           (),
      .rden_a        (1'b1),
      .rden_b        (rd),
      .wren_b        (1'b0)
   );

   defparam
      altsyncram_u.address_aclr_b         = "NONE",
      altsyncram_u.address_reg_b          = "CLOCK1",
      altsyncram_u.clock_enable_input_a   = "BYPASS",
      altsyncram_u.clock_enable_input_b   = "BYPASS",
      altsyncram_u.clock_enable_output_b  = "BYPASS",
      altsyncram_u.intended_device_family = "Cyclone IV",
      altsyncram_u.lpm_type               = "altsyncram",
      altsyncram_u.numwords_a             = 2**p_nbit_a,
      altsyncram_u.numwords_b             = 2**p_nbit_a,
      altsyncram_u.operation_mode         = "DUAL_PORT",
      altsyncram_u.outdata_aclr_b         = "NONE",
      altsyncram_u.outdata_reg_b          = p_output_reg_en ? "CLOCK1" : "UNREGISTERED",
      altsyncram_u.power_up_uninitialized = "FALSE",
      altsyncram_u.widthad_a              = p_nbit_a,
      altsyncram_u.widthad_b              = p_nbit_a,
      altsyncram_u.width_a                = p_nbit_d,
      altsyncram_u.width_b                = p_nbit_d,
      altsyncram_u.width_byteena_a        = 1,
      altsyncram_u.ram_block_type         = "M9K";
      
endmodule