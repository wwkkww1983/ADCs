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
//   `define DEBUG               1'b1  // using simulate SYNC, SPCLK, AD_CLK, AD_DB
//   `define AD_TIME             1'b1
   
   `define HIGH                1'b1
   `define LOW                 1'b0

   ////////////////// SDRAM
   `define SDRAM_ADDR_NBIT     13
   `define SDRAM_DATA_NBIT     16
   `define SDRAM_DQM_NBIT      2
   `define SDRAM_BA_NBIT       2
   `define SDRAM_NCS_NBIT      1
   `define SDRAM_RA_NBIT       13 // row address width
   `define SDRAM_CA_NBIT       10 // column address width
                            
   //////////////////  USB                   
   `define USB_DATA_NBIT       16
   `define USB_ADDR_NBIT       8   // 256 x 16-BIT
   `define USB_FIFOADR_NBIT    2
   
   `define USB_RD_FIFOADR      `USB_FIFOADR_NBIT'b00 // end point 2
   `define USB_WR_FIFOADR      `USB_FIFOADR_NBIT'b10 // end point 6
   
   ////////////////// BUFFER
   `define BUFFER_BADDR_NBIT   5 // 2^3 X 512bytes  
   `define BUFFER_ADDR_NBIT    `USB_ADDR_NBIT+`BUFFER_BADDR_NBIT
   `define BUFFER_DATA_NBIT    `USB_DATA_NBIT
   
   ////////////////// AD7960
   `define AD_DATA_NBIT        18
   `define AD_CHN_NBIT         3                   // channel 
   `define AD_CHN_NUM          8                   // channel number
   `define AD_CHE_ADDR_NBIT    7                   // cache buffer address width 
   `define AD_CHE_DATA_NBIT    48                  // 24*2 = 16*3
   `define AD_CHE_DATA_SIZE    `USB_ADDR_NBIT'd246 // cache buffer data size
   `define AD_CNT_NWORD        `USB_ADDR_NBIT'd3
   `define AD_CNT_NBIT         `AD_CNT_NWORD*`USB_DATA_NBIT
   `define AD_SP_NBIT          10
   `define AD_SP_NUM           256                 // SAMPLE 256 data after sync
   `define AD_SP_START_IDX     13
   `define AD_MCLK_RATE        100000              // unit(1KHz)
   `define AD_SPCLK_RATE       1000                // unit(1KHz)
   `define AD_SPCLK_DELAY      0                   // unit(1/200MHz)
   
   `define AD_AVG_CNT_NBIT     3
   `define AD_AVG_NUM_NBIT     0                   // 2^N, 0 - one sample, 1 - two samples
   
   `define AD_MODE_REF1        4'b1001 // use REFIN=2.048v OR (REFIN=0v & REF=5v), bandwidth 28MHz
   `define AD_MODE_REF2        4'b1010 // use (REFIN=0v & REF=4.096v), bandwidth 28MHz
   `define AD_MODE_REF3        4'b1101 // use REFIN=2.048v OR (REFIN=0v & REF=5v), bandwidth 9MHz
   `define AD_MODE_REF4        4'b1110 // use (REFIN=0v & REF=4.096v), bandwidth 9MHz
   `define AD_MODE_TEST        4'b0100

   `define AD_MODE_SLEEP       4'b1111
      
   ////////////////// COMMUNICATION, BYTE INVERTED
   `define MSG_STR_NBIT        `USB_DATA_NBIT
      
   `define MSG_HEAD            `MSG_STR_NBIT'h5453  // "ST"
   
   `define MSG_TYPE_HANDSHAKE  `MSG_STR_NBIT'h3030  // "00"
   `define MSG_TYPE_START      `MSG_STR_NBIT'h3130  // "01"
   `define MSG_TYPE_STOP       `MSG_STR_NBIT'h3230  // "02"
   
   `define MSG_PASS            `MSG_STR_NBIT'h3530  // "05"
   `define MSG_FAIL            `MSG_STR_NBIT'h3730  // "07"
   
   `define MSG_END_N           8'h0A  // "\n"
   `define MSG_END_R           8'h0D  // "\r"
   
   `define MSG_FP_CODE_00      `MSG_STR_NBIT'h3030
   
   `define MSG_FP_CODE_01      `MSG_STR_NBIT'h3130
   `define MSG_FP_CODE_02      `MSG_STR_NBIT'h3230
   `define MSG_FP_CODE_03      `MSG_STR_NBIT'h3330
   
   `define MSG_FP_CODE_11      `MSG_STR_NBIT'h3131
   `define MSG_FP_CODE_12      `MSG_STR_NBIT'h3231
   `define MSG_FP_CODE_13      `MSG_STR_NBIT'h3331
   
   `define MSG_FP_CODE_21      `MSG_STR_NBIT'h3132
   `define MSG_FP_CODE_22      `MSG_STR_NBIT'h3232
   `define MSG_FP_CODE_23      `MSG_STR_NBIT'h3332   