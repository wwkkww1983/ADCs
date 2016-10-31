 ////////////////////////////////////////////////////////////////
 //
 //  Module  : sync_fifo.v
 //  Designer: Hoki
 //  Company : 
 //  Date    : 2015/3/6 15:15:09
 //
 ////////////////////////////////////////////////////////////////
 // 
 //  Description: Synchronous FIFO Design
 //
 ////////////////////////////////////////////////////////////////
 // 
 //  Revision: 1.1 2015/3/31 14:19:27
 
/////////////////////////// MODULE //////////////////////////////
module sync_fifo
(
   clk,
   rst_n,
   wr,
   wdata,
   full,
   rd,
   rdata,
   empty
);
 
   ///////////////// PARAMETER ////////////////
   parameter p_nbit_d = 21;
   parameter p_nbit_a = 4; // assume that depth of fifo is power of 2
   // Optimization Level -- Read clk sync stages,metastability protextion,area,fmax
   // 1: Lowest latency but requires synchronized clocks 1 sync stage
   // 2: minimal setting for unsynchronized clock 2 sync stages
   // 3: Best metastability protection,best fmax,unsynchronized clocks 3 or more sync stages
   parameter p_optlevel = 3; 

   ////////////////// PORT ////////////////////
   input                 clk;
   input                 rst_n;
   input                 wr;
   input [p_nbit_d-1:0]  wdata;
   output                full;
   input                 rd;
   output [p_nbit_d-1:0] rdata;
   output                empty;
   
   ////////////////// ARCH ////////////////////
   
   // read&write pointer
   reg  [p_nbit_a:0] wptr=0; 
   reg  [p_nbit_a:0] rptr=0; 
   wire [p_nbit_a:0] wptrnext; 
   wire [p_nbit_a:0] rptrnext; 
   assign wptrnext = (wr & ~full) ? wptr + 1'b1 : wptr;
   assign rptrnext = (rd & ~empty) ? rptr + 1'b1 : rptr;
   
   always@(posedge clk) begin
      if(~rst_n) begin
         wptr <= 0;
         rptr <= 0;
      end
      else begin
         if(wr & ~full)
            wptr <= wptr + 1'b1;
         else
            wptr <= wptr;
         if(rd & ~empty)
            rptr <= rptr + 1'b1;
         else
            rptr <= rptr;
      end
   end
         
   // address
   wire [p_nbit_a-1:0] waddr;
   wire [p_nbit_a-1:0] raddr;
   assign waddr = wptr[p_nbit_a-1:0];
   assign raddr = rptr[p_nbit_a-1:0];
   
   // Full & Empty Condition
   reg full=1'b0;
   reg empty=1'b1;
   always@(posedge clk) begin
      if(~rst_n) begin
         full  <= 1'b0;
         empty <= 1'b1;
      end
      else begin
         if(wptrnext == {~rptrnext[p_nbit_a],rptrnext[p_nbit_a-1:0]})
            full <= 1'b1;
         else
            full <= 1'b0;
         if(rptrnext == wptrnext)
            empty <= 1'b1;
         else
            empty <= 1'b0;
      end
   end
   
   ////////////////// FIFO Memory   
   wire [p_nbit_d-1:0] mem_rdata;
   fifomem #(p_nbit_d,p_nbit_a,~(p_optlevel==1))
   fifomem_u
   (
      .wclk (clk   ),
      .wr   (wr    ),
      .waddr(waddr ),
      .wdata(wdata ),
      .rclk (clk   ),
      .rd   (rd    ),
      .raddr(raddr ),
      .rdata(mem_rdata)
   );
   
   // Read Data Output Register, Depend on optimization level
   reg [p_nbit_d-1:0] rdata;
   generate
      if(p_optlevel>2)
         always@(posedge clk)
            rdata <= mem_rdata;
      else
         always@*
            rdata <= mem_rdata;
   endgenerate   

endmodule        