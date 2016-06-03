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
   OE,
   // SYNC
   IN_SYNC,
   IN_SPCLK,
   OUT_SYNC,
   OUT_SPCLK,
   OUT_DATA,
   // AD7606
   AD_DATA,
   AD_BUSY,
   AD_FIRST_DATA,
   AD_OS,
   AD_CS,
   AD_RD,
   AD_RESET,
   AD_CONVSTAB,
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
   output                         OE;
   
   input                          IN_SYNC; // frame sync input
   input                          IN_SPCLK; // sample clock input, 200KHz
   output                         OUT_SYNC; // simulate frame sync output
   output                         OUT_SPCLK;// simulate sample clock, 200KHz
   output                         OUT_DATA; // simulate data
   
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

   input  [`AD_DATA_NBIT-1:0]     AD_DATA;
   input                          AD_BUSY;
   input                          AD_FIRST_DATA;
   output [2:0]                   AD_OS;
   output                         AD_CS;
   output                         AD_RD;
   output                         AD_RESET;
   output                         AD_CONVSTAB;

   ////////////////// ARCH ////////////////////

   assign OE = `HIGH;

   ////////////////// Clock Generation

	wire   mclk;   // 48MHz
   wire   ad_clk; // 50MHz
   usb_pll	usb_pll_u(
   	.inclk0 (CLK1      ),
   	.c0     (USB_XTALIN),
   	.c1     (USB_IFCLK ),
   	.c2     (ad_clk)
	);

	assign mclk = ~USB_IFCLK;
	
   ////////////////// AD7606 controller
   wire [`AD_DATA_NBIT-1:0]   ad_ch_data[`AD_CHN_NUM-1:0];
   wire                       ad_ch_vd;
   
   ad7606 u_ad7606(
      .clk        (ad_clk       ),
      .rst_n      (`HIGH        ),
      .ad_data    (AD_DATA      ),
      .ad_busy    (AD_BUSY      ),
      .first_data (AD_FIRST_DATA),
      .ad_os      (AD_OS        ),
      .ad_cs      (AD_CS        ),
      .ad_rd      (AD_RD        ),
      .ad_reset   (AD_RESET     ),
      .ad_convstab(AD_CONVSTAB  ),
      .ad_vd      (ad_ch_vd     ),
      .ad_ch1     (ad_ch_data[0]),
      .ad_ch2     (ad_ch_data[1]),
      .ad_ch3     (ad_ch_data[2]),
      .ad_ch4     (ad_ch_data[3]),
      .ad_ch5     (ad_ch_data[4]),
      .ad_ch6     (ad_ch_data[5]),
      .ad_ch7     (ad_ch_data[6]),
      .ad_ch8     (ad_ch_data[7])
   );
   
   reg  [`AD_DATA_NBIT-1:0] ad_cache_wdata;
   reg                      ad_cache_wr;
   wire [`AD_DATA_NBIT-1:0] ad_cache_rdata;
   wire                     ad_cache_switch;
   reg  [1:0]               p_sync;
   reg  [1:0]               p_spclk;

   always@(posedge ad_clk) begin
      p_sync  <= {p_sync[0],IN_SYNC};   // double ff to avoid meta
      p_spclk <= {p_spclk[0],IN_SPCLK}; // double ff to avoid meta
      ad_cache_wr    <= ad_ch_vd;
      ad_cache_wdata <= ad_ch_data[cmdec_ad_chn];
   end

   ad_cache u_ad_cache
   (
      .en    (cmdex_ad_acq_en),
      .sync  (p_sync[1]      ),
      .spclk (p_spclk[1]     ),
      .wclk  (ad_clk         ),
      .wr    (ad_cache_wr    ),
      .wdata (ad_cache_wdata ),
      .rclk  (mclk           ),
      .rd    (cmdec_ad_rd    ),
      .rdata (ad_cache_rdata ),
      .switch(ad_cache_switch)
   );
   
   ////////////////// USB PHY Slave FIFO Controller

   // slave fifo control
   wire                         usb_ctrl_sloe;
   wire                         usb_ctrl_slrd;
   wire                         usb_ctrl_slwr;
   wire                         usb_ctrl_pkend;
   wire [`USB_FIFOADR_NBIT-1:0] usb_ctrl_fifoadr;
   wire                         usb_ctrl_wen;
   wire [`USB_DATA_NBIT-1:0]    usb_ctrl_wdata;
   wire [`USB_DATA_NBIT-1:0]    usb_ctrl_rdata;
   wire                         usb_ctrl_empty;
   wire                         usb_ctrl_full;

   assign USB_DB         =  usb_ctrl_wen ? usb_ctrl_wdata : {`USB_DATA_NBIT{1'bZ}};
   assign USB_SLOE       = ~usb_ctrl_sloe;
   assign USB_SLRD       = ~usb_ctrl_slrd;
   assign USB_SLWR       = ~usb_ctrl_slwr;
   assign USB_PKEND      = ~usb_ctrl_pkend;
   assign USB_FIFOADR    =  usb_ctrl_fifoadr;
   assign usb_ctrl_rdata =  USB_DB;
   assign usb_ctrl_empty = ~USB_FLAGB; // End Point 2 empty flag
   assign usb_ctrl_full  = ~USB_FLAGC; // End Point 6 full flag


   // RX Data From USB PHY
   wire                         rx_cache_vd  ;
   wire [`USB_DATA_NBIT-1:0]    rx_cache_data;
   wire                         rx_cache_sop ;
   wire                         rx_cache_eop ;
   // Send Data to USB PHY
   wire [`USB_ADDR_NBIT-1:0]    tx_cache_addr;
   wire [`USB_DATA_NBIT-1:0]    tx_cache_data;

   usb_slavefifo u_usb_slavefifo
   (
      .ifclk        (mclk            ),
      .sloe         (usb_ctrl_sloe   ),
      .slrd         (usb_ctrl_slrd   ),
      .f_empty      (usb_ctrl_empty  ),
      .rdata        (usb_ctrl_rdata  ),
      .slwr         (usb_ctrl_slwr   ),
      .wen          (usb_ctrl_wen    ),
      .wdata        (usb_ctrl_wdata  ),
      .f_full       (usb_ctrl_full   ),
      .pkend        (usb_ctrl_pkend  ),
      .fifoaddr     (usb_ctrl_fifoadr),
      .rx_cache_vd  (rx_cache_vd     ),
      .rx_cache_data(rx_cache_data   ),
      .rx_cache_sop (rx_cache_sop    ),
      .rx_cache_eop (rx_cache_eop    ),
      .tx_cache_sop (cmdec_tx_eop    ),
      .tx_cache_addr(tx_cache_addr   ),
      .tx_cache_data(tx_cache_data   )
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
      .mclk     (mclk           ),
      .sync     (IN_SYNC        ),
      .ad_rd    (cmdec_ad_rd    ),
      .ad_chn   (cmdec_ad_chn   ),
      .ad_data  (ad_cache_rdata ),
      .ad_switch(ad_cache_switch),
      .ad_acq_en(cmdex_ad_acq_en),
      .rx_vd    (rx_cache_vd    ),
      .rx_data  (rx_cache_data  ),
      .rx_sop   (rx_cache_sop   ),
      .rx_eop   (rx_cache_eop   ),
      .tx_vd    (cmdec_tx_vd    ),
      .tx_addr  (cmdec_tx_addr  ),
      .tx_data  (cmdec_tx_data  ),
      .tx_eop   (cmdec_tx_eop   ),
      .tx_baddr (cmdex_tx_baddr )
   );

   ////////////////// TX BUFFER
   
   wire [`BUFFER_ADDR_NBIT-1:0] tx_buffer_rdata;
   assign tx_buffer_rdata = {cmdex_tx_baddr,tx_cache_addr};

   buffered_ram#(`BUFFER_ADDR_NBIT,`USB_DATA_NBIT,"./tx_buf_2048x16.mif")
   tx_buffer(
      .inclk       (mclk           ),
      .in_wren     (cmdec_tx_vd    ),
      .in_wraddress(cmdec_tx_addr  ),
      .in_wrdata   (cmdec_tx_data  ),
      .in_rdaddress(tx_buffer_rdata),
      .out_rddata  (tx_cache_data  )
   );   
   
   ////////////////// SYNC OUT
   reg  [8:0]  div;
   reg  [7:0]  sync_cnt;
   reg         OUT_SYNC;
   reg         OUT_SPCLK;
   reg         OUT_DATA;
   always@(posedge ad_clk) begin   
      if(div == 9'd499) begin // Sample rate - 50MHz/500 = 100KHz
         div <= 0;
         if(sync_cnt == 8'd136) // 137 samples in one frame sync cycle
            sync_cnt <= 0;
         else
            sync_cnt <= sync_cnt + 1'b1;
      end
      else 
         div <= div + 1'b1;
      
      // sync: 0~8 HIGH; 9~136 LOW
      if(sync_cnt<8'd9)
         OUT_SYNC <= `HIGH;
      else
         OUT_SYNC <= `LOW;
         
      // sample clock
      if(div<8'd249)
         OUT_SPCLK <= `HIGH;
      else
         OUT_SPCLK <= `LOW;
      
      // data: 0~17 +3.3V; 18~136 0V
      if(sync_cnt<8'd18) 
         OUT_DATA <= `HIGH;
      else
         OUT_DATA <= `LOW;
   end
   
endmodule