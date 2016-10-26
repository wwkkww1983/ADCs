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
   // AD7960 LVDS
   DCO,
   D,
   CNV,
   AD_CLK,
   AD_EN,
   AD_PG,
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
   input                          CLK2; // 50MHz
   output                         OE;
   
   input                          IN_SYNC;    // frame sync input
   input                          IN_SPCLK;   // sample clock input, 200KHz
   output                         OUT_SYNC;   // simulate frame sync output
   output                         OUT_SPCLK;  // simulate sample clock, 200KHz
   output                         OUT_DATA;   // simulate data
   
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

   // LVDS inputs
   input                          DCO;        // DCO from A/D (DCO- on schematic)
   input                          D;          // Lane A data from A/D (DA- on schematic)
   // LVDS outputs                            
   output                         AD_CLK;     // Serial clock to A/D (CLK- on schematic)
   output                         CNV;
   // ADC Enable
   output [3:0]                   AD_EN;      // AD7960 Enable
   output                         AD_PG;
   
   ////////////////// ARCH ////////////////////

   assign OE    = `HIGH;
   assign AD_PG = `HIGH; // Enable +12V -> +5V, +12V -> +7V
   
   ////////////////// Clock Generation
   
   // PLL for USB
   wire   usb_clk;   // 48MHz
   wire   mclk;      // 120MHz
   usb_pll  usb_pll_u(
      .inclk0 (CLK1      ),
      .c0     (USB_XTALIN),
      .c1     (USB_IFCLK ),
      .c2     (mclk      ),
      .c3     (SDRAM_CLK )
   );
   
   assign usb_clk = ~USB_IFCLK;
   
   // PLL for ADC
   wire   ad_fast_clk; // 300MHz
   
   adc_pll_ext adc_pll_u(
      .inclk0(CLK2       ),
      .c0    (ad_fast_clk)
   );

   ////////////////// AD7960 controller

   wire [`USB_DATA_NBIT-1:0] ad_cache_rdata;
   wire                      ad_cache_switch;
   wire                      ad_cache_sync;
   wire                      ad_cache_spclk;
   wire                      ad_cache_wclk;
   wire                      ad_cache_start;
   wire [`AD_CNT_NBIT-1:0]   ad_cache_cnt;

`ifdef DEBUG
   reg                       ad_cache_wr;   
   wire [`AD_DATA_NBIT-1:0]  ad_cache_wdata;
   reg  [`AD_DATA_NBIT-1:0]  wdata;
   
   assign ad_cache_sync  = OUT_SYNC;
   assign ad_cache_spclk = OUT_SPCLK;
   assign ad_cache_wclk  = ad_fast_clk;
   assign ad_cache_wdata = wdata;
   
   always@(posedge ad_cache_wclk) begin
      ad_cache_wr    <= ad_cache_start;
      if(cmdex_ad_acq_en) begin
         if(ad_cache_start)
            wdata <= wdata + 1'b1;
      end
      else
         wdata <= 0;
   end
`else 
   wire                      ad_cache_wr;   
   wire [`AD_DATA_NBIT-1:0]  ad_cache_wdata;
   wire                      ad_dv;
   wire [`AD_DATA_NBIT-1:0]  ad_db;
   
   assign ad_cache_sync  = IN_SYNC;
   assign ad_cache_spclk = IN_SPCLK;
   assign ad_cache_wclk  = ad_fast_clk;
   assign ad_cache_wr    = ad_dv;
   assign ad_cache_wdata = ad_db;

   AD7960 AD7960_U
   (
      .fast_clk_i   (ad_fast_clk   ),
      .reset_n_i    (`HIGH         ),
      .start_i      (ad_cache_start),
      .en_i         (`AD_MODE_REF2 ),
      .d_pos_i      (D             ),
      .dco_pos_i    (DCO           ),
      .en_o         (AD_EN         ),           
      .cnv_pos_o    (CNV           ),
      .cnv_neg_o    (),
      .clk_pos_o    (AD_CLK        ),
      .clk_neg_o    (),
      .data_rd_rdy_o(ad_dv         ),
      .data_o       (ad_db         )
   );
`endif
   
   // Data Cache
   ad_cache u_ad_cache
   (
      .en    (cmdex_ad_acq_en),
      .sync  (ad_cache_sync  ),
      .spclk (ad_cache_spclk ),
      .wclk  (ad_cache_wclk  ),
      .wstart(ad_cache_start ),
      .wr    (ad_cache_wr    ),
      .wdata (ad_cache_wdata ),
      .rclk  (mclk           ),
      .rd    (cmdec_ad_rd    ),
      .rcnt  (ad_cache_cnt   ),
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
      .tx_cache_data(tx_buffer_rdata  )
   );
   
   ////////////////// COMMAND DECODE
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
      .ad_cnt   (ad_cache_cnt     ),
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

   ////////////////// SDRAM Controller
   wire                         sdram_wren ;
   wire [`BUFFER_ADDR_NBIT-1:0] sdram_waddr;
   wire [`BUFFER_DATA_NBIT-1:0] sdram_wdata;
   wire                         sdram_wstatus;
   
   assign sdram_wren  = cmdec_tx_vd&(cmdec_tx_addr!=0); 
   assign sdram_waddr = cmdec_tx_addr;
   assign sdram_wdata = cmdec_tx_data;
   
   reg                          sdram_rd     ;
   reg  [`BUFFER_ADDR_NBIT-1:0] sdram_raddr  ;
   wire [`BUFFER_DATA_NBIT-1:0] sdram_rdata  ;
   wire                         sdram_rdv    ;
   wire                         sdram_rstatus;   
   
   sdram_ctrl #(`USB_DATA_NBIT,`BUFFER_ADDR_NBIT)
   sdram_ctrl_u(
      .clk       (mclk          ),
      .rst_n     (`HIGH         ),
      .wren      (sdram_wren    ),
      .waddr     (sdram_waddr   ),
      .wdata     (sdram_wdata   ),
      .wstatus   (sdram_wstatus ),
      .rd        (sdram_rd      ),
      .raddr     (sdram_raddr   ),
      .rdata     (sdram_rdata   ),
      .rdv       (sdram_rdv     ),
      .rstatus   (sdram_rstatus ),
		.port_addr (SDRAM_A       ),
		.port_ba   (SDRAM_BA      ),
		.port_cas_n(SDRAM_NCAS    ),
		.port_cke  (SDRAM_CKE     ),
		.port_cs_n (SDRAM_NCS     ),
		.port_dq   (SDRAM_D       ),
		.port_dqm  (SDRAM_DQM     ),
		.port_ras_n(SDRAM_NRAS    ),
		.port_we_n (SDRAM_NWE     )
   );
	
   ////////////////// TX BUFFER   
   wire                      tx_buffer_wr   ;
   reg  [`USB_ADDR_NBIT:0]   tx_buffer_waddr;
   wire [`USB_DATA_NBIT-1:0] tx_buffer_wdata;
   
   assign tx_buffer_wr    = sdram_rdv;
   assign tx_buffer_wdata = sdram_rdata;
   
   wire [`USB_ADDR_NBIT:0]   tx_buffer_raddr;
   reg                       usb_tx_cache_sop;
   reg                       usb_tx_cache_baddr;
   wire [`USB_DATA_NBIT-1:0] tx_buffer_rdata;
   
   assign tx_buffer_raddr = {usb_tx_cache_baddr,usb_tx_cache_addr};

   buffered_ram_tdp #(`USB_ADDR_NBIT+1,`USB_DATA_NBIT,
                      `USB_ADDR_NBIT+1,`USB_DATA_NBIT,
                      "./tx_buf_2048x16.mif")
   tx_buffer (
      .a_inclk     (mclk           ),
      .a_in_wren   (tx_buffer_wr   ),
      .a_in_address(tx_buffer_addr ),
      .a_in_wrdata (tx_buffer_data ),
      .a_out_rddata(),
      .b_inclk     (usb_clk        ),
      .b_in_wren   (`LOW           ),
      .b_in_address(tx_buffer_raddr),
      .b_in_wrdata (0),
      .b_out_rddata(tx_buffer_rdata)
   );

   ////////////////// DATA Flow Control
   //
   // ADC ACQ --> CMD DEC --> SDRAM --> TX BUFFER --> USB CTRL
   //
   //////////////////
   
   `define ST_IDLE   2'b00 
   `define ST_CMD    2'b01
   `define ST_SDRAM  2'b11
   `define ST_TXBUF  2'b10
   
   reg  [1:0]  st;
   reg         prev_sdram_wstatus;
   reg         prev_sdram_rstatus;
   
   always@(posedge mclk) begin
      prev_sdram_wstatus <= sdram_wstatus;
      prev_sdram_rstatus <= sdram_rstatus;
      usb_tx_cache_sop <= `LOW;
      sdram_rd <= `LOW;
      case(st) 
         `ST_IDLE: begin
            sdram_raddr <= {`BUFFER_BADDR_NBIT'd0,{`USB_ADDR_NBIT{1'b1}}};
            if(cmdec_tx_vd)
               st <= `ST_CMD;
         end
         `ST_CMD: begin // DATA: CMD DEC --> SDRAM
            if(cmdex_tx_baddr!=0) begin
               if(sdram_wstatus&~prev_sdram_wstatus) begin
                  st <= `ST_SDRAM;
                  sdram_rd    <= `HIGH;
                  sdram_raddr <= sdram_raddr + 1'b1;
               end
               usb_tx_cache_baddr <= `HIGH;
            end
            else begin
               st <= `ST_TXBUF;
               usb_tx_cache_baddr <= `LOW;
            end
         end
         `ST_SDRAM: begin // DATA: SDRAM --> TX BUFFER
            // read data from sdram
            if(sdram_raddr[`USB_ADDR_NBIT-1:0]!={`USB_ADDR_NBIT{1'b1}}) begin
               sdram_rd    <= `HIGH;
               sdram_raddr <= sdram_raddr + 1'b1;
            end
            
            if(sdram_rdv)
               tx_buffer_waddr <= tx_buffer_waddr + 1'b1;
               
            if(sdram_rstatus&~prev_sdram_rstatus) begin
               st <= `ST_TXBUF;
            end
         end
         `ST_TXBUF: begin // TX BUFFER --> USB CTRL
            usb_tx_cache_sop <= `HIGH;
            if(cmdex_tx_baddr!=0) begin
               st <= `ST_SDRAM;
               if(cmdex_tx_baddr==sdram_raddr[`BUFFER_ADDR_NBIT-1:`USB_ADDR_NBIT])
                  st <= `ST_IDLE;
            end
            else
               st <= `ST_IDLE;
         end
         default:
            st <= `ST_IDLE;
      endcase
   end
         
   ////////////////// SYNC OUT
   reg  [15:0]             div;
   reg  [`AD_SP_NBIT-1:0]  sync_cnt;
   reg  [`AD_SP_NBIT-1:0]  spclk_cnt;
   reg                     OUT_SYNC;
   reg                     OUT_SPCLK;
   reg                     OUT_DATA;
   always@(posedge mclk) begin   
      if(div == `AD_MCLK_RATE/`AD_SPCLK_RATE-1) begin
         div <= 0;
         if(spclk_cnt == 511) begin
            spclk_cnt <= 0;
            sync_cnt <= sync_cnt + 1'b1;
            if(sync_cnt==104)
               sync_cnt <= 0;
         end
         else
            spclk_cnt <= spclk_cnt + 1'b1;
      end
      else 
         div <= div + 1'b1;
      
      // sample clock
      if(div<`AD_MCLK_RATE/`AD_SPCLK_RATE/2)
         OUT_SPCLK <= `HIGH;
      else
         OUT_SPCLK <= `LOW;

      // sync: 0~8 HIGH; 9~136 LOW
      if(spclk_cnt<1) begin
         OUT_SYNC <= `HIGH;
         if(sync_cnt>=100)
            OUT_SYNC <= `LOW;
      end
      else
         OUT_SYNC <= `LOW;
      
      // data: 0~127 +3.3V; 128~255 0V
      if(spclk_cnt<270) 
         OUT_DATA <= `HIGH;
      else
         OUT_DATA <= `LOW;
   end
   
endmodule