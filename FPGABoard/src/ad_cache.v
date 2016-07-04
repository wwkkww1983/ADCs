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
   en,
   sync,
   spclk,
   wclk,
   wr,
   wdata,
   rclk,
   rd,
   rdata,
   switch
);

   ////////////////// PORT ////////////////////
   input                       en;
   input                       sync;
   input                       spclk;
   input                       wclk;
   input                       wr;
   input  [`AD_DATA_NBIT-1:0]  wdata;
   input                       rclk;
   input                       rd;
   output [`USB_DATA_NBIT-1:0] rdata;
   output                      switch;

   ////////////////// ARCH ////////////////////

   ////////////////// WRITE   
   reg  [`AD_CHE_ADDR_NBIT-1:0] waddr;
   reg                          wswitch;
   reg                          buf_wr;
   reg  [`AD_CHE_ADDR_NBIT:0]   buf_waddr;
   reg  [`USB_DATA_NBIT*2-1:0]  buf_wdata;
   reg                          prev_sync;
   reg                          prev_spclk;
   reg  [`AD_SP_NBIT-1:0]       spwr_cnt;
   reg  [`AD_SP_NBIT-1:0]       spclk_cnt;
   
   always@(posedge wclk) begin
      prev_sync <= sync;
      prev_spclk<= spclk;
      buf_wr    <= `LOW;
      buf_waddr <= {wswitch,waddr};
      buf_wdata <= {{`USB_DATA_NBIT*2-`AD_DATA_NBIT{wdata[`AD_DATA_NBIT-1]}},wdata};
      if(en) begin
         if(wr&&(spclk_cnt>=`AD_SP_START_IDX)&&(spwr_cnt<`AD_SP_NUM)) begin
            buf_wr <= `HIGH;
            spwr_cnt <= spwr_cnt + 1'b1;
         end
         
         if((spclk&~prev_spclk) && (spclk_cnt<`AD_SP_START_IDX))
            spclk_cnt <= spclk_cnt + 1'b1;
            
         if(sync&~prev_sync) begin// reset counter at the posedge of SYNC
            spwr_cnt <= 0;
            spclk_cnt <= 0;
         end
         
         if(buf_wr) begin
            waddr <= waddr + 1'b1;
            if(waddr == `AD_CHE_DATA_SIZE-1) begin
               waddr <= 0;
               wswitch <= ~wswitch;
            end
         end
      end
      else begin
         waddr <= 0;
         spwr_cnt <= {`AD_SP_NBIT{1'b1}};
         spclk_cnt <= 0;
      end
   end
   
   ////////////////// PING PANG BUFFER   
   buffered_ram_tdp #(`AD_CHE_ADDR_NBIT+1,`USB_DATA_NBIT*2,
                      `AD_CHE_ADDR_NBIT+2,`USB_DATA_NBIT)
   pingpang_cache
   (
      .a_inclk     (wclk),
      .a_in_wren   (buf_wr),
      .a_in_address(buf_waddr),
      .a_in_wrdata (buf_wdata),
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
   reg  [`AD_CHE_ADDR_NBIT:0]   raddr;
   wire [`AD_CHE_ADDR_NBIT+1:0] buf_raddr;
   assign buf_raddr = {~pp_wswitch[2],raddr};
   
   always@(posedge rclk) begin
      pp_wswitch <= {pp_wswitch[1:0],wswitch};
      switch <= ^pp_wswitch[2:1];
      
      if(switch)
         raddr <= 0;
      else if(rd) 
         raddr <= raddr + 1'b1;
   end
   
endmodule