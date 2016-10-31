/////////////////////////// INCLUDE /////////////////////////////
`include "./globals.v"

////////////////////////////////////////////////////////////////
//
//  Module  : avalon2memwr
//  Designer: Hoki
//  Company : HWroks
//  Date    : 2016/7/28 17:02:59
//
////////////////////////////////////////////////////////////////
// 
//  Description: Convert avalon bus interface to standard 
//               internal memory write&read interface
//
////////////////////////////////////////////////////////////////
// 
//  Revision: 1.0

/////////////////////////// DEFINE /////////////////////////////

/////////////////////////// MODULE //////////////////////////////
module avalon2memwr
(
   inb_address,
   inb_write,
   inb_wdata,
   inb_read,
   inb_rdata,
   inb_datavalid,
   inb_initdone,
   avalon_address,
   avalon_byteenable_n,
   avalon_chipselect,
   avalon_writedata,
   avalon_read_n,
   avalon_write_n,
   avalon_readdata,
   avalon_readdatavalid,
   avalon_waitrequest
);

   ///////////////// PARAMETER ////////////////
   parameter P_DATA_NBIT = 32;
   parameter P_ADDR_NBIT = 16;

   ////////////////// PORT ////////////////////
   output [23:0]               avalon_address;
   output [3:0]                avalon_byteenable_n;
   output                      avalon_chipselect;
   output [31:0]               avalon_writedata;
   output                      avalon_read_n;
   output                      avalon_write_n;
   input  [31:0]               avalon_readdata;
   input                       avalon_readdatavalid;
   input                       avalon_waitrequest;
   
   input  [P_ADDR_NBIT-1:0]    inb_address;
   input                       inb_write;
   input  [P_DATA_NBIT-1:0]    inb_wdata;
   input                       inb_read;
   output [P_DATA_NBIT-1:0]    inb_rdata;
   output                      inb_datavalid;
   output                      inb_initdone;
   
   ////////////////// ARCH ////////////////////
   
   assign avalon_address      = {{24-P_ADDR_NBIT{1'b0}},inb_address};
   assign avalon_byteenable_n = {{4-P_DATA_NBIT/8{1'b1}},{P_DATA_NBIT/8{1'b0}}};
   assign avalon_chipselect   = inb_write|inb_read;  
   assign avalon_writedata    = {{32-P_DATA_NBIT{1'b0}},inb_wdata};
   assign avalon_read_n       = ~inb_read;
   assign avalon_write_n      = ~inb_write;
   assign inb_rdata           = avalon_readdata[P_DATA_NBIT-1:0];
   assign inb_datavalid       = avalon_readdatavalid;
   assign inb_initdone        = ~avalon_waitrequest;

endmodule   