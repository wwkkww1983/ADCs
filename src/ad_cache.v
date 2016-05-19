/////////////////////////// INCLUDE /////////////////////////////
`include "./globals.v"

////////////////////////////////////////////////////////////////
//
//  Module  : ad_cache
//  Designer: Hoki
//  Company : HWorks
//  Date    : 2016/5/19 14:21:25
//
////////////////////////////////////////////////////////////////
// 
//  Description: cache data from analog-to-digital converter
//
////////////////////////////////////////////////////////////////
// 
//  Revision: 1.0

/////////////////////////// MODULE //////////////////////////////
module ad_cache
(
   wclk,
   wr,
   wdata,
   rclk,
   rd,
   rdata
);

   ////////////////// PORT ////////////////////
   input                      wclk;
   input                      wr;
   input  [`AD_DATA_NBIT-1:0] wdata;
   input                      rclk;
   input                      rd;
   output [`AD_DATA_NBIT-1:0] rdata;

   ////////////////// ARCH ////////////////////
   
   
   buffered_ram_tdp #(`AD_CHE_NBIT+1,`AD_DATA_NBIT)
   pingpang_cache
   (
      .a_inclk     (wclk),
      .a_in_wren   (wr),
      .a_in_address(),
      .a_in_wrdata (wdata),
      .a_out_rddata(),
      .b_inclk     (rclk),
      .b_in_wren   (),
      .b_in_address(),
      .b_in_wrdata (),
      .b_out_rddata(rdata)
   );   
   
endmodule