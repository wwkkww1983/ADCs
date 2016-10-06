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

   ////////////////// Average
   wire                         avg_wr  ;
   wire [`AD_DATA_NBIT-1:0]     avg_data;
   wire                         avg_rst;
   
   assign avg_rst = p_sync[2:1]==2'b01;
   
   generate
      if(`AD_AVG_EN) begin: ad_average
         adc_avg adc_avg_u
         (
            .clk        (wclk    ),
            .rst        (avg_rst ),
            .i_strobe   (wr      ),
            .i_inst_data(wdata   ),
            .o_strobe   (avg_wr  ),
            .o_avg_data (avg_data)
         );
      end
      else begin: ad_instant
         assign avg_wr   = wr;
         assign avg_data = wdata;
      end
   endgenerate
   
   ////////////////// WRITE   
   reg  [`AD_CHE_ADDR_NBIT-1:0] waddr;
   reg                          wswitch;
   reg                          buf_wr;
   reg  [`AD_CHE_ADDR_NBIT:0]   buf_waddr;
   reg  [`AD_CHE_DATA_NBIT-1:0] buf_wdata;
   reg  [2:0]                   p_sync;
//   reg  [`AD_SPCLK_DELAY+3:0]   p_spclk;
   reg  [`AD_SP_NBIT-1:0]       spclk_cnt;
   reg                          cache_wr;
   reg                          cache_wcnt;
   reg                          cache_en;
   
   always@(posedge wclk) begin
      p_sync  <= {p_sync[1:0],sync};
      cache_wr <= `LOW;
      if(avg_wr) begin
//         p_spclk <= {p_spclk[`AD_SPCLK_DELAY+2:0],spclk};
//         if((p_spclk[`AD_SPCLK_DELAY+3:`AD_SPCLK_DELAY+2]==2'b01)) begin
            spclk_cnt <= spclk_cnt + 1'b1;
            if((spclk_cnt>=`AD_SP_START_IDX)&&(spclk_cnt<`AD_SP_START_IDX+`AD_SP_NUM)) begin
               buf_wdata <= {buf_wdata[`AD_CHE_DATA_NBIT-25:0],{{24-`AD_DATA_NBIT{avg_data[`AD_DATA_NBIT-1]}},avg_data}};
               cache_wcnt <= cache_wcnt + 1'b1;
               if(cache_wcnt==1)
                  cache_wr  <= `HIGH;
            end
            else if(spclk_cnt==`AD_SP_START_IDX+`AD_SP_NUM) begin
               spclk_cnt <= spclk_cnt;
            end
//         end
      end
      
      if(p_sync[2:1]==2'b01) begin // reset counter at the posedge of SYNC
         spclk_cnt  <= 0;
         cache_wr   <= `LOW;
         cache_wcnt <= 0;
         cache_en   <= en;
         buf_wdata  <= 0;
      end
      
      buf_wr    <= `LOW;
      buf_waddr <= {wswitch,waddr};
      if(cache_en) begin
         if(cache_wr) begin
            buf_wr <= `HIGH;
            waddr  <= waddr + 1'b1;
            if(waddr == `AD_CHE_DATA_SIZE/(`AD_CHE_DATA_NBIT/16)-1) begin
               waddr   <= 0;
               wswitch <= ~wswitch;
            end
         end
      end
      else begin
         waddr <= 0; // reset switch when re-enable
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