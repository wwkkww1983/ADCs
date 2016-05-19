/////////////////////////// INCLUDE /////////////////////////////
`include "./globals.v"

////////////////////////////////////////////////////////////////
//
//  Module  : cmd_decode
//  Designer: Hoki
//  Company : HWorks
//  Date    : 2016/5/18 21:40:10
//
////////////////////////////////////////////////////////////////
// 
//  Description: - decode the received command
//               - send tx command
//
////////////////////////////////////////////////////////////////
// 
//  Revision: 1.0

/////////////////////////// MODULE //////////////////////////////
module cmd_decode
(
   mclk,
   
   ad_clk,
   ad_data,
   ad_chn,
   
   rx_vd,
   rx_data,
   rx_sop,
   rx_eop ,
   tx_vd,
   tx_addr,
   tx_data,
   tx_eop
); 

   ////////////////// PORT ////////////////////
   input                         mclk;    // main clock 48MHz
   
   input                         ad_clk; // adc clock 50MHz
   input  [`AD_DATA_NBIT-1:0]    ad_data;
   output [`AD_CHN_NBIT-1:0]     ad_chn;

   input                         rx_vd  ;
   input  [`USB_DATA_NBIT-1:0]   rx_data;
   input                         rx_sop ;
   input                         rx_eop ;
                                 
   output                        tx_vd;
   output [`USB_ADDR_NBIT:0]     tx_addr;
   output [`USB_DATA_NBIT-1:0]   tx_data;
   output                        tx_eop;

   ////////////////// ARCH ////////////////////

   ////////////////// RX STATEMENT
   `define ST_MSG_IDLE   3'b000
   `define ST_MSG_HEAD   3'b001
   `define ST_MSG_TYPE   3'b010
   `define ST_MSG_CHADDR 3'b100
   `define ST_MSG_DATA   3'b101
   `define ST_MSG_PF     3'b011
   `define ST_PF_CODE    3'b110
   `define ST_MSG_END    3'b111
   
   // RX Message Structure: {HEAD,TYPE,CHANNEL_ADDRESS}
   reg [`MSG_STR_NBIT-1:0]       ascii_rx_type;  // "00": handshake; "01": start; "02": stop
   reg [`MSG_STR_NBIT-1:0]       ascii_rx_ch_addr;
   reg [`MSG_STR_NBIT/2-1:0]     rx_ch_addr;     // "00" ~ "07"
   
   reg [2:0]                     fsm_rx_st;
   reg                           fsm_rx_err;
   reg                           fsm_rx_eop;

   // convert rx data(DATA Region) from char to int
   wire [`USB_DATA_NBIT/2-1:0] atoi_rx_data;
   wire                        atoi_err;
   atoi#(`USB_DATA_NBIT/2) atoi_u 
   (
      .i_char({rx_data[`USB_DATA_NBIT/2-1:0],
               rx_data[`USB_DATA_NBIT-1:`USB_DATA_NBIT/2]}), // invert h and l
      .o_int (atoi_rx_data),
      .o_err (atoi_err    )
   );   
   
   // decode rx command
   always@(posedge mclk) begin: rx_fsm   
      // Statement
      fsm_rx_eop <= `LOW;
      case(fsm_rx_st)
         `ST_MSG_IDLE : begin
            if(rx_sop) begin
               fsm_rx_st          <= `ST_MSG_HEAD;
               ascii_rx_type  <= 0;
               rx_ch_addr     <= 0;
               fsm_rx_err     <= `LOW;
               ascii_rx_ch_addr <= 0;
            end
         end
         `ST_MSG_HEAD: begin
            // Detect HEAD
            if(rx_vd&rx_data==`MSG_HEAD) begin
               fsm_rx_st <= `ST_MSG_TYPE;
            end
         end
         `ST_MSG_TYPE: begin
            if(rx_vd) begin
               // Three TYPE Supported:
               // - "00": HANDSHAKE
               // - "01": START
               // - "02": STOP
               ascii_rx_type  <= rx_data;
               fsm_rx_st      <= `ST_MSG_CHADDR;
            end
         end
         `ST_MSG_CHADDR: begin
            if(rx_vd) begin
               fsm_rx_st        <= `ST_MSG_END;
               ascii_rx_ch_addr <= rx_data;
               rx_ch_addr       <= atoi_rx_data;
               if(rx_data[`MSG_STR_NBIT/2-1:0]==`MSG_END_N || rx_data[`MSG_STR_NBIT/2-1:0]==`MSG_END_R)
                  fsm_rx_err       <= atoi_err;
               else   
                  fsm_rx_err       <= `HIGH;
            end
         end
         `ST_MSG_END: begin
            if(rx_eop) begin
               fsm_rx_eop <= `HIGH;
               fsm_rx_st  <= `ST_MSG_IDLE;
            end
         end
         default:
            fsm_rx_st <= `ST_MSG_IDLE;
      endcase
   end
   
   ////////////////// Instruction Execute
   reg  [`MSG_STR_NBIT-1:0]       tx_msg_type;
   reg  [`MSG_STR_NBIT-1:0]       tx_msg_pf;
   reg  [`MSG_STR_NBIT-1:0]       tx_pf_code;
   reg                            tx_buf_baddr; // base address of BUFFER
                             
   reg proc_handshake_start;
   reg proc_ad_acq;

   always@(posedge mclk) begin: ins_exe
      proc_handshake_start <= `LOW;
      case(ascii_rx_type)
         `MSG_TYPE_HANDSHAKE: begin
            tx_buf_baddr <= `LOW;
            tx_msg_type  <= `MSG_TYPE_HANDSHAKE;
            tx_msg_pf    <= `MSG_PASS;
            tx_pf_code   <= `MSG_FP_CODE_01; // pass code 01: handshake succeed
            proc_handshake_start <= fsm_rx_eop;
         end
         `MSG_TYPE_START: begin
            tx_buf_baddr <= `HIGH;
            tx_msg_type  <= `MSG_TYPE_START;
            tx_msg_pf    <= fsm_rx_err ? `MSG_FAIL       : `MSG_PASS;
            tx_pf_code   <= fsm_rx_err ? `MSG_FP_CODE_02 : `MSG_FP_CODE_01; 
            proc_ad_acq  <= `HIGH;
         end
         `MSG_TYPE_STOP: begin
            tx_buf_baddr <= `HIGH;
            tx_msg_type  <= `MSG_TYPE_STOP;
            tx_msg_pf    <= fsm_rx_err ? `MSG_FAIL       : `MSG_PASS;
            tx_pf_code   <= fsm_rx_err ? `MSG_FP_CODE_12 : `MSG_FP_CODE_11;
            proc_ad_acq  <= `LOW;
         end
         default:;
      endcase
   end
            
   ////////////////// TX STATEMENT         
   
   wire   tx_msg_sop;
   assign tx_msg_sop = proc_handshake_start;
   
   reg                       tx_vd;
   reg [`USB_DATA_NBIT-1:0]  tx_data;
   reg                       tx_eop;

   reg  [`USB_ADDR_NBIT-1:0] tx_buf_addr; // low address of BUFFER
   wire [`USB_ADDR_NBIT:0]   tx_addr;
   assign tx_addr = {tx_buf_baddr,tx_buf_addr};

   reg [2:0] tx_st=`ST_MSG_IDLE;
   
   reg [`MSG_DATA_MAX_NBIT-1:0] tx_msg_data;
   reg [`USB_ADDR_NBIT-1:0]     tx_msg_addr;

   // convert tx data(DATA Region) from int to char
   wire [`USB_DATA_NBIT/2-1:0] int_tx_data;
   wire [`USB_DATA_NBIT-1:0]   char_tx_data;
   assign int_tx_data = tx_msg_data[`MSG_DATA_MAX_NBIT-1:`MSG_DATA_MAX_NBIT-`USB_DATA_NBIT/2];
   itoa#(`USB_DATA_NBIT/2) itoa_u
   (
      .i_int (int_tx_data),
      .o_char({char_tx_data[`USB_DATA_NBIT/2-1:0],
               char_tx_data[`USB_DATA_NBIT-1:`USB_DATA_NBIT/2]}) // invert h and l
   );
   
   always@(posedge mclk) begin: tx_fsm
      tx_vd  <= `LOW;
      tx_eop <= `LOW;
      case(tx_st) 
         `ST_MSG_IDLE: begin
            tx_buf_addr <= 0;
            tx_msg_addr <= 0;
            if(tx_msg_sop)
               tx_st <= `ST_MSG_HEAD;
         end
         `ST_MSG_HEAD: begin
            tx_vd <= `HIGH;
            tx_buf_addr <= 0;
            tx_data <= `MSG_HEAD;
            tx_st <= `ST_MSG_TYPE;
         end
         `ST_MSG_TYPE: begin
            tx_vd <= `HIGH;
            tx_buf_addr <= tx_buf_addr + 1'b1;
            tx_data <= tx_msg_type;
            tx_st <= `ST_MSG_PF;
         end
         `ST_MSG_PF: begin
            tx_vd   <= `HIGH;
            tx_buf_addr <= tx_buf_addr + 1'b1;
            tx_data <= tx_msg_pf;
            tx_st   <= `ST_PF_CODE;
         end
         `ST_PF_CODE: begin
            tx_vd       <= `HIGH;
            tx_data     <= tx_pf_code;
            tx_buf_addr <= tx_buf_addr + 1'b1;
            tx_st       <= `ST_MSG_CHADDR;
            if(tx_msg_type==`MSG_TYPE_HANDSHAKE) begin
               tx_st   <= `ST_MSG_IDLE;
               tx_eop  <= `HIGH;
            end
         end
         `ST_MSG_CHADDR: begin
            tx_vd       <= `HIGH;
            tx_data     <= ascii_rx_ch_addr;
            tx_buf_addr <= tx_buf_addr + 1'b1;
            tx_st       <= `ST_MSG_DATA;
                
         end
         `ST_MSG_DATA: begin
            
            
            tx_vd       <= `HIGH;
            tx_buf_addr <= tx_buf_addr + 1'b1;
            tx_data     <= char_tx_data;
            if(tx_msg_addr==0)
               tx_st <= `ST_MSG_END;
         end
         `ST_MSG_END: begin
            tx_vd   <= `HIGH;
            tx_buf_addr <= tx_buf_addr + 1'b1;
            
            tx_msg_addr <= 0;
            if(tx_msg_addr=={`USB_ADDR_NBIT{1'b1}})
               tx_data <= {`MSG_END_N,`MSG_END_R};
            else begin
               tx_data <= 0; // clean TX BUFFER
               if(tx_buf_addr=={`USB_ADDR_NBIT{1'b1}}) begin
                  tx_vd  <= `LOW;
                  tx_st  <= `ST_MSG_IDLE;
                  tx_eop <= `HIGH;
               end
            end
         end
         default:
            tx_st <= `ST_MSG_IDLE;
      endcase
   end
   
endmodule

////////////////////////////////////////////////////////////////
//
//  Module  : atoi
//  Designer: Hoki
//  Company : HWorks
//  Date    : 2015/11/27 
//
////////////////////////////////////////////////////////////////
// 
//  Description: convert ascii char to hexadecimal integer  
//
////////////////////////////////////////////////////////////////
// 
//  Revision: 1.0

/////////////////////////// MODULE //////////////////////////////
module atoi
(
   i_char,
   o_int,
   o_err
);

   ///////////////// PARAMETER ////////////////
   parameter  p_int_nbit =8;
   localparam p_char_nbit=p_int_nbit*2;
   
   ////////////////// PORT ////////////////////
   input  [p_char_nbit-1:0]  i_char; 
   output [p_int_nbit-1:0]   o_int;  
   output                    o_err;
   
   ////////////////// ARCH ////////////////////
   wire [7:0] char[0:p_int_nbit/4-1];
   reg  [7:0] char_offset[0:p_int_nbit/4-1];
   wire [7:0] t_int[0:p_int_nbit/4-1];
   reg  [p_int_nbit/4-1:0] char_err;
   
   generate
   genvar i;
      for(i=0;i<p_int_nbit/4;i=i+1)
      begin: u
         assign char[i] = i_char[8*i+7:8*i];
         
         always@* begin
            char_err[i] <= `LOW;
            
            // ASCII "0" ~ "9" -- INT 0 ~ 9
            if(char[i]>="0" && char[i]<="9")
               char_offset[i] <= "0";
            // ASCII "a" ~ "f" -- INT 10 ~ 15
            else if(char[i]>="a" && char[i]<="f")
               char_offset[i] <= "a" - 8'd10;
            // ASCII "A" ~ "F" -- INT 10 ~ 15
            else if(char[i]>="A" && char[i]<="F")
               char_offset[i] <= "A" - 8'd10;
            else begin
               char_offset[i] <= 0;
               char_err[i] <= `HIGH;
            end
         end
         
         assign t_int[i] = char[i] - char_offset[i];
         
         assign o_int[4*i+3:4*i] = t_int[i][3:0];
      end
   endgenerate
   
   assign o_err = |char_err;
      
endmodule

////////////////////////////////////////////////////////////////
//
//  Module  : itoa
//  Designer: Hoki
//  Company : HWorks
//  Date    : 2015/11/27 
//
////////////////////////////////////////////////////////////////
// 
//  Description: convert hexadecimal integer to ascii char
//
////////////////////////////////////////////////////////////////
// 
//  Revision: 1.0

/////////////////////////// MODULE //////////////////////////////
module itoa
(
   i_int,
   o_char
);

   ///////////////// PARAMETER ////////////////
   parameter  p_int_nbit=8;
   localparam p_char_nbit = p_int_nbit*2;
   
   ////////////////// PORT ////////////////////
   input  [p_int_nbit-1:0]  i_int;
   output [p_char_nbit-1:0] o_char;
   
   ////////////////// ARCH ////////////////////
   wire [3:0] t_int[0:p_int_nbit/4-1];
   reg  [7:0] char_offset[0:p_int_nbit/4-1];
   wire [7:0] char[0:p_int_nbit/4-1];

   generate
   genvar i;
      for(i=0;i<p_int_nbit/4;i=i+1)
      begin: u
         assign t_int[i] = i_int[4*i+3:4*i];
         
         always@* begin
            // INT 0 ~ 9 -- ASCII "0" ~ "9"
            if(t_int[i]>=0 && t_int[i]<=9)
               char_offset[i] <= "0";
            // INT 10 ~ 15 -- ASCII "A" ~ "F"
            else
               char_offset[i] <= "A" - 8'd10;
         end
         
         assign char[i] = {4'h0,t_int[i]} + char_offset[i];
         
         assign o_char[8*i+7:8*i] = char[i];
      end
   endgenerate
   
endmodule