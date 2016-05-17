////////////////////////////////////////////////////////////////
//
//  Module  : globals
//  Designer: Hoki
//  Company : HWorks
//  Date    : 2015/11/13 
//
////////////////////////////////////////////////////////////////
// 
//  Description: global definition, macro, variables
//
////////////////////////////////////////////////////////////////
// 
//  Revision: 1.0

   `define HIGH 1'b1
   `define LOW  1'b0

   ////////////////// SDRAM
   `define SDRAM_ADDR_NBIT  13
   `define SDRAM_DATA_NBIT  16
   `define SDRAM_DQM_NBIT   2
   `define SDRAM_BA_NBIT    2
   `define SDRAM_NCS_NBIT   1
   `define SDRAM_RA_NBIT    13 // row address width
   `define SDRAM_CA_NBIT    10 // column address width
                            
   //////////////////  USB                   
   `define USB_DATA_NBIT    16
   `define USB_ADDR_NBIT    8   // 256 x 16-BIT
   `define USB_FIFOADR_NBIT 2
   
   `define USB_RD_FIFOADR   `USB_FIFOADR_NBIT'b00 // end point 2
   `define USB_WR_FIFOADR   `USB_FIFOADR_NBIT'b10 // end point 6
   
   ////////////////// BUFFER
   `define BUFFER_ADDR_NBIT `USB_ADDR_NBIT
   `define BUFFER_DATA_NBIT `USB_DATA_NBIT
   
   ////////////////// COMMUNICATION, BYTE INVERTED
   `define MSG_STR_NBIT     `USB_DATA_NBIT
   
   ////////////////// AD7606
   `define AD_DATA_NBIT     16
      