/////////////////////////// INCLUDE /////////////////////////////
`include "../src/globals.v"

////////////////////////////////////////////////////////////////
//
//  Module  : sdram_ctrl
//  Designer: Hoki
//  Company : HWorks
//  Date    : 2016/10/26 10:42:34
//
////////////////////////////////////////////////////////////////
// 
//  Description: SDRAM Controller
//
////////////////////////////////////////////////////////////////
// 
//  Revision: 1.0

/////////////////////////// DEFINE /////////////////////////////

/////////////////////////// MODULE //////////////////////////////
module sdram_ctrl
(
   clk       ,
   rst_n     ,
   wren      ,
   waddr     ,
   wdata     ,
   wstatus   ,
   rd        ,
   raddr     ,
   rdata     ,
   rdv       ,
   rstatus   ,
   port_addr ,
   port_ba   ,
   port_cas_n,
   port_cke  ,
   port_cs_n ,
   port_dq   ,
   port_dqm  ,
   port_ras_n,
   port_we_n 
);
   ///////////////// PARAMETER ////////////////
   parameter P_DATA_NBIT = 16;
   parameter P_ADDR_NBIT = 16;

   ////////////////// PORT ////////////////////

   input                    clk;
   input                    rst_n;

   input                    wren;       // write enable
   input  [P_ADDR_NBIT-1:0] waddr;      // write address
   input  [P_DATA_NBIT-1:0] wdata;      // write data
   output                   wstatus;    // write buffer status, HIGH - empty
   
   input                    rd;
   input  [P_ADDR_NBIT-1:0] raddr;
   output [P_DATA_NBIT-1:0] rdata;
   output                   rdv;
   output                   rstatus;
   
	output [12:0]            port_addr ; 
	output [1:0]             port_ba   ;   
	output                   port_cas_n;
	output                   port_cke  ;  
	output [1:0]             port_cs_n ;
	inout  [31:0]            port_dq   ;
	output [3:0]             port_dqm  ;
	output                   port_ras_n;
	output                   port_we_n ;

   ////////////////// ARCH ////////////////////

   ////////////////// WRITE Buffer
   wire                                 wr_buf_empty;
   wire                                 wr_buf_rd;
   wire  [P_ADDR_NBIT+P_DATA_NBIT-1:0]  wr_buf_q;     
   
   assign wr_buf_rd = ~wr_buf_empty&(sdram_initdone&prev_initdone);
   
   asyn_fifo #(P_DATA_NBIT+P_ADDR_NBIT,8,1)
   write_buffer (
     .wclk  (clk),
     .wrst_n(rst_n),
     .wr    (wren),
     .wdata ({waddr,wdata}),
     .wfull (),
     .rclk  (clk),
     .rrst_n(rst_n),
     .rd    (wr_buf_rd),
     .rdata (wr_buf_q),
     .rempty(wr_buf_empty)
   );
   
   ////////////////// READ Buffer
   wire                     rd_buf_empty;
   wire                     rd_buf_rd;
   wire  [P_ADDR_NBIT-1:0]  rd_buf_q;     
   
   assign rd_buf_rd = ~rd_buf_empty&(sdram_initdone&prev_initdone);
   
   asyn_fifo #(P_ADDR_NBIT,8,1)
   read_buffer (
     .wclk  (clk),
     .wrst_n(rst_n),
     .wr    (rd),
     .wdata (raddr),
     .wfull (),
     .rclk  (clk),
     .rrst_n(rst_n),
     .rd    (rd_buf_rd),
     .rdata (rd_buf_q),
     .rempty(rd_buf_empty)
   );
      
   //////////////////    
   wire                      sdram_initdone;
   wire [P_ADDR_NBIT-1:0]    sdram_address;
   wire                      sdram_write;
   wire [P_DATA_NBIT-1:0]    sdram_wdata;
   wire                      sdram_read;
   reg                       sdram_read_en;
   wire [P_DATA_NBIT-1:0]    sdram_rdata;
   wire                      sdram_datavalid;
   reg                       sdram_write_en;
   reg                       prev_initdone;
   reg                       wstatus;
   reg  [P_ADDR_NBIT-1:0]    prev_waddr;
   reg  [P_ADDR_NBIT-1:0]    current_waddr;
   reg                       rstatus;
   reg  [P_ADDR_NBIT-1:0]    prev_raddr;                 
   reg  [P_ADDR_NBIT-1:0]    current_raddr;
   
   assign sdram_address = sdram_read ? rd_buf_q : wr_buf_q[P_ADDR_NBIT+P_DATA_NBIT-1:P_DATA_NBIT];
   assign sdram_read    = sdram_read_en &sdram_initdone;
   assign sdram_write   = sdram_write_en&sdram_initdone;
   assign sdram_wdata   = wr_buf_q[P_DATA_NBIT-1:0];
   
   assign rdata = sdram_rdata;
   assign rdv   = sdram_datavalid;

   always@(posedge clk or negedge rst_n) begin
      if(~rst_n) begin
         sdram_write_en <= `LOW;
         current_waddr <= 0;
         prev_waddr <= 0;
         wstatus <= `LOW;
         sdram_read_en <= `LOW;
         current_raddr <= 0;
         prev_raddr <= 0;
         rstatus <= `LOW;
      end
      else begin
         prev_initdone <= sdram_initdone;
         
         // write enable
         if(wr_buf_rd)
            sdram_write_en <= `HIGH;
         else if(sdram_write)
            sdram_write_en <= `LOW;
         // write status
         if(sdram_write)
            current_waddr <= current_waddr + 1'b1;
         if(wren)
            prev_waddr <= prev_waddr + 1'b1;
         if(wr_buf_empty&&(prev_waddr==current_waddr))
            wstatus <= `HIGH;
         else
            wstatus <= `LOW;
            
         // read enable   
         if(rd_buf_rd)
            sdram_read_en <= `HIGH;
         else if(sdram_read)
            sdram_read_en <= `LOW;
         // read status
         if(sdram_read)
            current_raddr <= current_raddr + 1'b1;
         if(sdram_datavalid)
            prev_raddr <= prev_raddr + 1'b1;
         if(rd_buf_empty&&(prev_raddr==current_raddr))
            rstatus <= `HIGH;
         else
            rstatus <= `LOW;
      end
   end
   
   ////////////////// Avalon to Local Bus
   avalon2memwr #(P_DATA_NBIT,P_ADDR_NBIT)
   avalon2memwr_u
   (
      .inb_address         (sdram_address           ),
      .inb_write           (sdram_write             ),
      .inb_wdata           (sdram_wdata             ),
      .inb_read            (sdram_read              ),
      .inb_rdata           (sdram_rdata             ),
      .inb_datavalid       (sdram_datavalid         ),
      .inb_initdone        (sdram_initdone          ),
      .avalon_address      (avalon_mms_address      ),
      .avalon_byteenable_n (avalon_mms_byteenable_n ),
      .avalon_chipselect   (avalon_mms_chipselect   ),
      .avalon_writedata    (avalon_mms_writedata    ),
      .avalon_read_n       (avalon_mms_read_n       ),
      .avalon_write_n      (avalon_mms_write_n      ),
      .avalon_readdata     (avalon_mms_readdata     ),
      .avalon_readdatavalid(avalon_mms_readdatavalid),
      .avalon_waitrequest  (avalon_mms_waitrequest  )
   );
   
   ////////////////// SDRAM    
	wire [25:0] avalon_mms_address      ;     
	wire [3:0]  avalon_mms_byteenable_n ;
	wire        avalon_mms_chipselect   ;  
	wire [31:0] avalon_mms_writedata    ;   
	wire        avalon_mms_read_n       ;      
	wire        avalon_mms_write_n      ;     
	wire [31:0] avalon_mms_readdata     ;    
	wire        avalon_mms_readdatavalid;
	wire        avalon_mms_waitrequest  ; 

   sdram sdram_u (
		.avalon_mms_address      (avalon_mms_address      ),
		.avalon_mms_byteenable_n (avalon_mms_byteenable_n ),
		.avalon_mms_chipselect   (avalon_mms_chipselect   ),
		.avalon_mms_writedata    (avalon_mms_writedata    ),
		.avalon_mms_read_n       (avalon_mms_read_n       ),
		.avalon_mms_write_n      (avalon_mms_write_n      ),
		.avalon_mms_readdata     (avalon_mms_readdata     ),
		.avalon_mms_readdatavalid(avalon_mms_readdatavalid),
		.avalon_mms_waitrequest  (avalon_mms_waitrequest  ),
		.in_clk_clk              (clk                     ),
		.in_rst_reset_n          (rst_n                   ),
		.port_addr               (port_addr               ),
		.port_ba                 (port_ba                 ),
		.port_cas_n              (port_cas_n              ),
		.port_cke                (port_cke                ),
		.port_cs_n               (port_cs_n               ),
		.port_dq                 (port_dq                 ),
		.port_dqm                (port_dqm                ),
		.port_ras_n              (port_ras_n              ),
		.port_we_n               (port_we_n               )
	);

endmodule