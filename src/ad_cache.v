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
   rdata,
   switch
);

   ////////////////// PORT ////////////////////
   input                      wclk;
   input                      wr;
   input  [`AD_DATA_NBIT-1:0] wdata;
   input                      rclk;
   input                      rd;
   output [`AD_DATA_NBIT-1:0] rdata;
   output                     switch;

   ////////////////// ARCH ////////////////////

   ////////////////// WRITE   
   reg  [`AD_CHE_ADDR_NBIT-1:0] waddr;
   reg                          wswitch;
   always@(posedge wclk) begin
      waddr <= waddr + 1'b1;
      if(waddr == `AD_CHE_DATA_SIZE-1) bwgin
         waddr <= 0;
         wswitch <= ~wswitch;
      end
   end
   
   reg  [`AD_CHE_ADDR_NBIT-1:0] buf_waddr;
   assign buf_waddr = {wswitch,waddr};

   ////////////////// PING PANG BUFFER   
   buffered_ram_tdp #(`AD_CHE_NBIT+1,`AD_DATA_NBIT)
   pingpang_cache
   (
      .a_inclk     (wclk),
      .a_in_wren   (wr),
      .a_in_address(buf_waddr),
      .a_in_wrdata (wdata),
      .a_out_rddata(),
      .b_inclk     (rclk),
      .b_in_wren   (`LOW),
      .b_in_address(buf_raddr),
      .b_in_wrdata (0),
      .b_out_rddata(rdata)
   );
   
   ////////////////// READ
   reg  [2:0]                   pp_wswitch;
   reg                          switch;
   reg  [`AD_CHE_ADDR_NBIT-1:0] raddr;
   wire [`AD_CHE_ADDR_NBIT:0]   buf_raddr;
   assign buf_raddr = {~pp_switch[2],raddr};
   
   always@(posedge rclk) begin   
      pp_wswitch <= {pp_switch[1:0],wswitch};
      switch <= ^pp_switch[2:1];
      
      if(switch)
         raddr <= 0;
      else if(rd) 
         raddr <= raddr + 1'b1;
   end
   
endmodule