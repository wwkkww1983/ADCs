/////////////////////////// INCLUDE /////////////////////////////
`include "./globals.v"

////////////////////////////////////////////////////////////////
//
//  Module  : top
//  Designer: Hoki
//  Company : HWorks
//  Date    : 2016/5/17 9:12:48
//
////////////////////////////////////////////////////////////////
//
//  Description: top module of ADCs DEMO project
//
////////////////////////////////////////////////////////////////
//
//  Revision: 1.0

module top
(
   // Clock Source
   CLK1,
	CLK2,
   OE,
   // SYNC
   IN_SYNC,
   IN_SPCLK,
   OUT_SYNC,
   OUT_SPCLK,
   OUT_DATA,
   // LTC2387
   OUT_AD_CLK,
   AD_DB,
   IN_AD_CLK,
   // USB
   USB_XTALIN,
   USB_FLAGB,
   USB_FLAGC,
   USB_IFCLK,
   USB_DB,
   USB_SLOE,
   USB_SLWR,
   USB_SLRD,
   USB_PKEND,
   USB_FIFOADR
);

   ////////////////// PORT ////////////////////
   input                          CLK1; // 48MHz
	input								    CLK2; // 50MHz
   output                         OE;
   
   input                          IN_SYNC;    // frame sync input
   input                          IN_SPCLK;   // sample clock input, 200KHz
   output                         OUT_SYNC;   // simulate frame sync output
   output                         OUT_SPCLK;  // simulate sample clock, 200KHz
   output                         OUT_DATA;   // simulate data
   
   output                         USB_XTALIN; // USB PHY CPU clock, 24MHz
   input                          USB_FLAGB;  // USB PHY EP2 empty flag
   input                          USB_FLAGC;  // USB PHY EP6 full flag
   output                         USB_IFCLK;  // USB PHY IF clock
   inout  [`USB_DATA_NBIT-1:0]    USB_DB;     // USB PHY data
   output                         USB_SLOE;   // USB PHY sloe
   output                         USB_SLWR;   // USB PHY slwr
   output                         USB_SLRD;   // USB PHY slrd
   output                         USB_PKEND;  // USB PHY pktend
   output [`USB_FIFOADR_NBIT-1:0] USB_FIFOADR;// USB PHY fifoadr

   output                         OUT_AD_CLK; // clock output for LT2387
   input  [`AD_DATA_NBIT-1:0]     AD_DB;      // LT2387 data input
   input                          IN_AD_CLK;  // LT2387 data valid input

   ////////////////// ARCH ////////////////////

   assign OE = `HIGH;

   ////////////////// Clock Generation
   
   // PLL for USB
	wire   usb_clk;   // 48MHz
   usb_pll	usb_pll_u(
   	.inclk0 (CLK1      ),
   	.c0     (USB_XTALIN),
   	.c1     (USB_IFCLK )
	);
	
	assign usb_clk = ~USB_IFCLK;
	
	// PLL for ADC
   wire   OUT_AD_CLK; // 15MHz
   wire   mclk;       // 100MHz
   adc_pll adc_pll_u(
   	.inclk0(CLK2),
   	.c0    (OUT_AD_CLK),
   	.c1    (mclk));	
	
   ////////////////// LTC2387 controller
   
   wire [`AD_DATA_NBIT-1:0]  ad_cache_wdata;
   reg                       ad_cache_wr;
   wire [`USB_DATA_NBIT-1:0] ad_cache_rdata;
   wire                      ad_cache_switch;
   wire                      ad_cache_sync;
   wire                      ad_cache_spclk;
	wire                      ad_cache_wclk;
	reg  [7:0]                sd_cnt;

`ifdef DEBUG
   reg  [`AD_DATA_NBIT-1:0]  wdata;
	
	assign ad_cache_sync  = OUT_SYNC;
	assign ad_cache_spclk = OUT_SPCLK;
	assign ad_cache_wclk  = OUT_AD_CLK;
	assign ad_cache_wdata = wdata;
   
   reg  [2:0]              p_ad_cache_spclk;
   always@(posedge ad_cache_wclk) begin
      p_ad_cache_spclk <= {p_ad_cache_spclk[1:0],ad_cache_spclk};
      if(ad_cache_wr&&(p_ad_cache_spclk[2:1]==2'b01))
         wdata <= wdata + 1'b1;
   end
`else 
   assign ad_cache_sync  = IN_SYNC;
	assign ad_cache_spclk = IN_SPCLK;
	assign ad_cache_wclk  = IN_AD_CLK;
	assign ad_cache_wdata = AD_DB;
`endif

   always@(posedge ad_cache_wclk) begin
      sd_cnt <= sd_cnt + 1'b1;
      if(sd_cnt==15000/`AD_SAMPLE_RATE-1)
         sd_cnt <= 0;
      ad_cache_wr <= `HIGH;
   end
   
   ad_cache u_ad_cache
   (
      .en    (cmdex_ad_acq_en),
      .sync  (ad_cache_sync  ),
      .spclk (ad_cache_spclk ),
      .wclk  (ad_cache_wclk  ),
      .wr    (ad_cache_wr    ),
      .wdata (ad_cache_wdata ),
      .rclk  (mclk           ),
      .rd    (cmdec_ad_rd    ),
      .rdata (ad_cache_rdata ),
      .switch(ad_cache_switch)
   );
   
   ////////////////// USB PHY Slave FIFO Controller

   // slave fifo control
   wire                          usb_ctrl_sloe;
   wire                          usb_ctrl_slrd;
   wire                          usb_ctrl_slwr;
   wire                          usb_ctrl_pkend;
   wire [`USB_FIFOADR_NBIT-1:0]  usb_ctrl_fifoadr;
   wire                          usb_ctrl_wen;
   wire [`USB_DATA_NBIT-1:0]     usb_ctrl_wdata;
   wire [`USB_DATA_NBIT-1:0]     usb_ctrl_rdata;
   wire                          usb_ctrl_empty;
   wire                          usb_ctrl_full;

   assign USB_DB              =  usb_ctrl_wen ? usb_ctrl_wdata : {`USB_DATA_NBIT{1'bZ}};
   assign USB_SLOE            = ~usb_ctrl_sloe;
   assign USB_SLRD            = ~usb_ctrl_slrd;
   assign USB_SLWR            = ~usb_ctrl_slwr;
   assign USB_PKEND           = ~usb_ctrl_pkend;
   assign USB_FIFOADR         =  usb_ctrl_fifoadr;
   assign usb_ctrl_rdata      =  USB_DB;
   assign usb_ctrl_empty      = ~USB_FLAGB; // End Point 2 empty flag
   assign usb_ctrl_full       = ~USB_FLAGC; // End Point 6 full flag


   // RX Data From USB PHY
   wire                          usb_rx_cache_vd  ;
   wire [`USB_DATA_NBIT-1:0]     usb_rx_cache_data;
   wire                          usb_rx_cache_sop ;
   wire                          usb_rx_cache_eop ;
   // Send Data to USB PHY       
   wire [`USB_ADDR_NBIT-1:0]     usb_tx_cache_addr;
   wire [`USB_DATA_NBIT-1:0]     usb_tx_cache_data;
   reg                           usb_tx_cache_sop;
   
   reg  [`BUFFER_BADDR_NBIT-1:0] usb_tx_cache_baddr;
   reg  [2:0]                    p_cmdec_tx_eop;
   
   always@(posedge usb_clk) begin
      p_cmdec_tx_eop   <= {p_cmdec_tx_eop[1:0],cmdec_tx_eop};
      usb_tx_cache_sop <= `LOW;
      if(p_cmdec_tx_eop[2:1]==2'b01) begin
         if(cmdex_tx_baddr==0) begin // handshake
            usb_tx_cache_sop   <= `HIGH;
            usb_tx_cache_baddr <= `BUFFER_BADDR_NBIT'd0;
         end
         else if(~usb_ctrl_full) begin
            usb_tx_cache_sop   <= `HIGH;
            usb_tx_cache_baddr <= usb_tx_cache_baddr + 1'b1;
            if(usb_tx_cache_baddr==0 || usb_tx_cache_baddr=={`BUFFER_BADDR_NBIT{1'b1}})
               usb_tx_cache_baddr <= `BUFFER_BADDR_NBIT'd1;
         end
      end
   end

   usb_slavefifo u_usb_slavefifo
   (
      .ifclk        (usb_clk          ),
      .sloe         (usb_ctrl_sloe    ),
      .slrd         (usb_ctrl_slrd    ),
      .f_empty      (usb_ctrl_empty   ),
      .rdata        (usb_ctrl_rdata   ),
      .slwr         (usb_ctrl_slwr    ),
      .wen          (usb_ctrl_wen     ),
      .wdata        (usb_ctrl_wdata   ),
      .f_full       (usb_ctrl_full    ),
      .pkend        (usb_ctrl_pkend   ),
      .fifoaddr     (usb_ctrl_fifoadr ),
      .rx_cache_vd  (usb_rx_cache_vd  ),
      .rx_cache_data(usb_rx_cache_data),
      .rx_cache_sop (usb_rx_cache_sop ),
      .rx_cache_eop (usb_rx_cache_eop ),
      .tx_cache_sop (usb_tx_cache_sop ),
      .tx_cache_addr(usb_tx_cache_addr),
      .tx_cache_data(usb_tx_cache_data)
   );
   
   ////////////////// command decode
   wire                          cmdec_ad_rd;
   wire [`AD_CHN_NBIT-1:0]       cmdec_ad_chn;
   wire                          cmdec_tx_vd  ;
   wire [`BUFFER_ADDR_NBIT-1:0]  cmdec_tx_addr;
   wire [`USB_DATA_NBIT-1:0]     cmdec_tx_data;
   wire                          cmdec_tx_eop ;
   wire [`BUFFER_BADDR_NBIT-1:0] cmdex_tx_baddr;
   wire                          cmdex_ad_acq_en;
   
   cmd_decode u_cmd_decode
   (
      .mclk     (mclk             ),
      .ad_rd    (cmdec_ad_rd      ),
      .ad_chn   (cmdec_ad_chn     ),
      .ad_data  (ad_cache_rdata   ),
      .ad_switch(ad_cache_switch  ),
      .ad_acq_en(cmdex_ad_acq_en  ),
      .rx_clk   (usb_clk          ),
      .rx_vd    (usb_rx_cache_vd  ),
      .rx_data  (usb_rx_cache_data),
      .rx_sop   (usb_rx_cache_sop ),
      .rx_eop   (usb_rx_cache_eop ),
      .tx_vd    (cmdec_tx_vd      ),
      .tx_addr  (cmdec_tx_addr    ),
      .tx_data  (cmdec_tx_data    ),
      .tx_eop   (cmdec_tx_eop     ),
      .tx_baddr (cmdex_tx_baddr   )
   );

   ////////////////// TX BUFFER
   
   wire [`BUFFER_ADDR_NBIT-1:0] tx_buffer_raddr;
   assign tx_buffer_raddr = {usb_tx_cache_baddr,usb_tx_cache_addr};

   buffered_ram_tdp #(`BUFFER_ADDR_NBIT,`USB_DATA_NBIT,
                      `BUFFER_ADDR_NBIT,`USB_DATA_NBIT,
                      "./tx_buf_2048x16.mif")
   tx_buffer (
      .a_inclk     (mclk           ),
      .a_in_wren   (cmdec_tx_vd    ),
      .a_in_address(cmdec_tx_addr  ),
      .a_in_wrdata (cmdec_tx_data  ),
      .a_out_rddata(),
      .b_inclk     (usb_clk        ),
      .b_in_wren   (`LOW           ),
      .b_in_address(tx_buffer_raddr),
      .b_in_wrdata (0),
      .b_out_rddata(usb_tx_cache_data)
   );
      
   ////////////////// SYNC OUT
   reg  [15:0]             div;
   reg  [`AD_SP_NBIT-1:0]  sync_cnt;
   reg                     OUT_SYNC;
   reg                     OUT_SPCLK;
   reg                     OUT_DATA;
   always@(posedge mclk) begin   
      if(div == 100000/`AD_SPCLK_RATE-1) begin
         div <= 0;
         if(sync_cnt == 511)
            sync_cnt <= 0;
         else
            sync_cnt <= sync_cnt + 1'b1;
      end
      else 
         div <= div + 1'b1;
      
      // sample clock
      if(div<100000/`AD_SPCLK_RATE/2)
         OUT_SPCLK <= `HIGH;
      else
         OUT_SPCLK <= `LOW;

      // sync: 0~8 HIGH; 9~136 LOW
      if(sync_cnt<9)
         OUT_SYNC <= `HIGH;
      else
         OUT_SYNC <= `LOW;
      
      // data: 0~127 +3.3V; 128~255 0V
      if(sync_cnt<255) 
         OUT_DATA <= `HIGH;
      else
         OUT_DATA <= `LOW;
   end
   
endmodule