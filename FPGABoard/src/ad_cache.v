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
//  Revision: 1.1 

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
   reg  [`AD_CHE_DATA_NBIT-1:0] buf_wdata;
   reg  [2:0]                   p_sync;
   reg  [2:0]                   p_spclk;
   reg  [`AD_SP_NBIT-1:0]       spwr_cnt;
   reg  [`AD_SPCLK_NBIT-1:0]    spclk_cnt;
   reg                          cache_wr;
   reg                          cache_wcnt;
   
   always@(posedge wclk) begin
      p_sync  <= {p_sync[1:0],sync};
      p_spclk <= {p_spclk[1:0],spclk};
      
      cache_wr <= `LOW;
      if(wr) begin
         cache_wcnt <= cache_wcnt + 1'b1;
         if(cache_wcnt==1)
            cache_wr  <= ~cache_wr;
         buf_wdata <= {buf_wdata[`AD_CHE_DATA_NBIT-25:0],{{24-`AD_DATA_NBIT{wdata[`AD_DATA_NBIT-1]}},wdata}};
      end
      
      buf_wr    <= `LOW;
      buf_waddr <= {wswitch,waddr};
      if(en) begin
         if(cache_wr&&(spclk_cnt>=`AD_SP_START_IDX)&&(spwr_cnt<`AD_SP_NUM/2)) begin
            buf_wr <= `HIGH;
            spwr_cnt <= spwr_cnt + 1'b1;
         end

         if((p_spclk[2:1]==2'b01) && (spclk_cnt<`AD_SP_START_IDX))
            spclk_cnt <= spclk_cnt + 1'b1;
         
         if(buf_wr) begin
            waddr <= waddr + 1'b1;
            if(waddr == `AD_CHE_DATA_SIZE/(`AD_CHE_DATA_NBIT/16)-1) begin
               waddr   <= 0;
               wswitch <= ~wswitch;
            end
         end
         
         if(p_sync[2:1]==2'b01) begin // reset counter at the posedge of SYNC
            spwr_cnt <= 0;
            spclk_cnt <= 0;
         end
      end
      else begin
         waddr <= 0; // reset switch when re-enable
         spwr_cnt <= {`AD_SP_NBIT{1'b1}};
         spclk_cnt <= 0;
      end
   end
   
   ////////////////// PING PANG BUFFER
   wire   [`AD_CHE_DATA_NBIT-1:0]   buf_rdata;
   
   buffered_ram_tdp #(`AD_CHE_ADDR_NBIT+1,`AD_CHE_DATA_NBIT,
                      `AD_CHE_ADDR_NBIT+1,`AD_CHE_DATA_NBIT)
   pingpang_cache
   (
      .a_inclk     (wclk     ),
      .a_in_wren   (buf_wr   ),
      .a_in_address(buf_waddr),
      .a_in_wrdata (buf_wdata),
      .a_out_rddata(),
      .b_inclk     (rclk     ),
      .b_in_wren   (`LOW     ),
      .b_in_address(buf_raddr),
      .b_in_wrdata (0        ),
      .b_out_rddata(buf_rdata)
   );
   
   ////////////////// READ
   reg  [2:0]                   pp_wswitch;
   reg                          switch;
   reg  [`AD_CHE_ADDR_NBIT-1:0] raddr;
   reg  [1:0]                   cache_rcnt;
   wire [`AD_CHE_ADDR_NBIT:0]   buf_raddr;
   reg  [`AD_CHE_DATA_NBIT-1:0] sf_data;
   reg  [1:0]                   sf_en;
   
   assign buf_raddr = {~pp_wswitch[2],raddr};
   
   always@(posedge rclk) begin
      pp_wswitch <= {pp_wswitch[1:0],wswitch};
      switch <= pp_wswitch[2];
      
      sf_en <= {sf_en[0],rd};
      if(sf_en[1])
         sf_data <= sf_data<<`USB_DATA_NBIT;
         
      if(rd) begin
         cache_rcnt <= cache_rcnt + 1'b1;
         if(cache_rcnt==2'b10)
            cache_rcnt <= 0;
         else if(cache_rcnt==2'b01)
            sf_data <= buf_rdata;
         else if(cache_rcnt==2'b00)
            raddr <= raddr + 1'b1;
      end
      
      if(^pp_wswitch[2:1]) begin
         raddr <= 0;
         cache_rcnt <= 0;
      end
   end

   assign rdata = sf_data[`AD_CHE_DATA_NBIT-1:`AD_CHE_DATA_NBIT-`USB_DATA_NBIT];
         
endmodule