/////////////////////////// INCLUDE /////////////////////////////
`include "../src/globals.v"

////////////////////////////////////////////////////////////////
//
//  Module  : adc_avg
//  Designer: Hoki
//  Company : HWorks
//  Date    : 2016/8/24 23:13:05
//
////////////////////////////////////////////////////////////////
// 
//  Description: average operation for adc data
//
////////////////////////////////////////////////////////////////
// 
//  Revision: 1.0

/////////////////////////// DEFINE /////////////////////////////

/////////////////////////// MODULE //////////////////////////////
module adc_avg
(
   clk        ,
   rst        ,
   i_strobe   ,
   i_inst_data,
   o_strobe   ,
   o_avg_data
);

   ////////////////// PORT ////////////////////
   input                      clk        ;
   input                      rst        ;
   input                      i_strobe   ;
   input  [`AD_DATA_NBIT-1:0] i_inst_data;
   output                     o_strobe   ;
   output [`AD_DATA_NBIT-1:0] o_avg_data ;

   ////////////////// ARCH ////////////////////
   
   reg  [`AD_DATA_NBIT-1:0]  rg_inst_data[0:2**`AD_AVG_NUM_NBIT-1];
   
   generate
   genvar i;
   for(i=0;i<2**`AD_AVG_NUM_NBIT;i=i+1)
   begin: pipe_avg
      always@(posedge clk) begin
         if(rst) begin
            rg_inst_data[i] <= 0;
         end
         else begin
            if(i_strobe)
               rg_inst_data[i] <= i==0 ? i_inst_data : rg_inst_data[i-1];
         end
      end
   end
   endgenerate
   
   reg  [`AD_AVG_NUM_NBIT-1:0]               avg_cnt=0;
   reg  [`AD_AVG_NUM_NBIT+`AD_DATA_NBIT-1:0] sum_data=0;
   reg                                       o_strobe;
   
   always@(posedge clk) begin
      if(rst) begin
         o_strobe <= `LOW;
         sum_data <= 0;
         avg_cnt  <= 0;
      end
      else begin
         o_strobe <= `LOW;
         if(i_strobe) begin
            avg_cnt  <= avg_cnt + 1'b1;
            sum_data <= avg_cnt==0 ? i_inst_data : sum_data + i_inst_data;
            if(avg_cnt==2**`AD_AVG_NUM_NBIT-1) begin
               o_strobe <= `HIGH;
               avg_cnt  <= 0;
            end
         end
      end
   end
   
   assign o_avg_data = sum_data[`AD_AVG_NUM_NBIT+`AD_DATA_NBIT-1:`AD_AVG_NUM_NBIT];

endmodule