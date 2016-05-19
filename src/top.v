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
   // SDRAM
   SDRAM_A,
   SDRAM_D,
   SDRAM_DQM,
   SDRAM_BA,
   SDRAM_NCS,
   SDRAM_CKE,
   SDRAM_NRAS,
   SDRAM_NWE,
   SDRAM_CLK,
   SDRAM_NCAS,
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

   output                         USB_XTALIN; // 24MHz
   input                          USB_FLAGB;  // EP2 Empty
   input                          USB_FLAGC;  // EP6 Full
   output                         USB_IFCLK;
   inout  [`USB_DATA_NBIT-1:0]    USB_DB;
   output                         USB_SLOE;
   output                         USB_SLWR;
   output                         USB_SLRD;
   output                         USB_PKEND;
   output [`USB_FIFOADR_NBIT-1:0] USB_FIFOADR;

   input  [`AD_DATA_NBIT-1:0]     AD_DATA;
   input                          AD_BUSY;
   input                          AD_FIRST_DATA;
   output [2:0]                   AD_OS;
   output                         AD_CS;
   output                         AD_RD;
   output                         AD_RESET;
   output                         AD_CONVSTAB;

   output [`SDRAM_ADDR_NBIT-1:0]  SDRAM_A;
   inout  [`SDRAM_DATA_NBIT-1:0]  SDRAM_D;
   output [`SDRAM_DQM_NBIT-1:0]   SDRAM_DQM;
   output [`SDRAM_BA_NBIT-1:0]    SDRAM_BA;
   output [`SDRAM_NCS_NBIT-1:0]   SDRAM_NCS;
   output                         SDRAM_CKE;
   output                         SDRAM_NRAS;
   output                         SDRAM_NWE;
   output                         SDRAM_CLK;
   output                         SDRAM_NCAS;

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
   
   wire [`AD_DATA_NBIT-1:0]   ad_data;
   wire                       ad_vd;
   assign ad_data = ad_ch_data[ad_chn];
   assign ad_vd   = ad_ch_vd;

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
   wire [`AD_CHN_NBIT-1:0]   ad_chn;
   wire                      cmdec_tx_vd  ;
   wire [`USB_ADDR_NBIT:0]   cmdec_tx_addr;
   wire [`USB_DATA_NBIT-1:0] cmdec_tx_data;
   wire                      cmdec_tx_eop ;
   cmd_decode u_cmd_decode
   (
      .mclk   (mclk         ),
      .ad_clk (ad_clk       ),
      .ad_data(ad_data      ),
      .ad_chn (ad_chn       ),
      .rx_vd  (rx_cache_vd  ),
      .rx_data(rx_cache_data),
      .rx_sop (rx_cache_sop ),
      .rx_eop (rx_cache_eop ),
      .tx_vd  (cmdec_tx_vd  ),
      .tx_addr(cmdec_tx_addr),
      .tx_data(cmdec_tx_data),
      .tx_eop (cmdec_tx_eop )
   );       

   ////////////////// TX BUFFER
   
   wire [`USB_DATA_NBIT:0] tx_buffer_rdata;
   assign tx_buffer_rdata = {cmdec_tx_addr[`USB_ADDR_NBIT],tx_cache_addr};

   buffered_ram#(`USB_ADDR_NBIT+1,`USB_DATA_NBIT,"./tx_buf_512x16.mif")
   tx_buffer(
      .inclk       (mclk           ),
      .in_wren     (cmdec_tx_vd    ),
      .in_wraddress(cmdec_tx_addr  ),
      .in_wrdata   (cmdec_tx_data  ),
      .in_rdaddress(tx_buffer_rdata),
      .out_rddata  (tx_cache_data  )
   );   

endmodule