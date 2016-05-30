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
   sync,
   ad_rd,
   ad_data,
   ad_switch,
   ad_chn,
   ad_acq_en,
   
   rx_vd,
   rx_data,
   rx_sop,
   rx_eop ,
   tx_vd,
   tx_addr,
   tx_data,
   tx_eop,
   tx_baddr
); 

   ////////////////// PORT ////////////////////
   input                           mclk;   // main clock 48MHz
   input                           sync;
   output                          ad_rd;
   input  [`AD_DATA_NBIT-1:0]      ad_data;
   input                           ad_switch;
   output [`AD_CHN_NBIT-1:0]       ad_chn;
   output                          ad_acq_en;
                                   
   input                           rx_vd  ;
   input  [`USB_DATA_NBIT-1:0]     rx_data;
   input                           rx_sop ;
   input                           rx_eop ;
                                   
   output                          tx_vd;
   output [`BUFFER_ADDR_NBIT-1:0]  tx_addr;
   output [`USB_DATA_NBIT-1:0]     tx_data;
   output                          tx_eop;
   output [`BUFFER_BADDR_NBIT-1:0] tx_baddr;

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
   reg [`MSG_STR_NBIT-1:0]       ascii_ch_addr;
   reg [`MSG_STR_NBIT/2-1:0]     rx_ch_addr;     // "00" ~ "07"
	reg									ad_acq_en;
   
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
               fsm_rx_err     <= `LOW;
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
               ascii_rx_type <= rx_data;
               fsm_rx_st     <= `ST_MSG_CHADDR;
            end
         end
         `ST_MSG_CHADDR: begin
            if(rx_vd) begin
               fsm_rx_st     <= `ST_MSG_END;
               fsm_rx_err    <= atoi_err;
               rx_ch_addr    <= atoi_rx_data;
               ascii_ch_addr <= rx_data;
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
   reg  [`AD_CNT_NBIT-1:0]        tx_adc_cnt;
   reg  [2:0]                     p_sync;
   reg                            tx_sync_en;
   reg  [`AD_CHN_NBIT-1:0]        ad_chn;
                             
   reg proc_handshake_start;

   always@(posedge mclk) begin: ins_exe
      p_sync <= {p_sync[1:0],sync};
      proc_handshake_start <= `LOW;
      case(ascii_rx_type)
         `MSG_TYPE_HANDSHAKE: begin
            tx_msg_type  <= `MSG_TYPE_HANDSHAKE;
            tx_msg_pf    <= `MSG_PASS;
            tx_pf_code   <= `MSG_FP_CODE_01; // pass code 01: handshake succeed
            proc_handshake_start <= fsm_rx_eop;
         end
         `MSG_TYPE_START: begin
            tx_msg_type  <= `MSG_TYPE_START;
            tx_msg_pf    <= fsm_rx_err ? `MSG_FAIL       : `MSG_PASS;
            tx_pf_code   <= fsm_rx_err ? `MSG_FP_CODE_02 : `MSG_FP_CODE_01; 
            if(ad_switch) begin
            	tx_adc_cnt <= tx_adc_cnt + 1'b1;
            end
            //ad_acq_en <= `HIGH;
            if(p_sync[2:1]==2'b01)
               ad_acq_en <= `HIGH;
            ad_chn    <= rx_ch_addr[`AD_CHN_NBIT-1:0];
         end
         `MSG_TYPE_STOP: begin
            tx_msg_type  <= `MSG_TYPE_STOP;
            tx_msg_pf    <= fsm_rx_err ? `MSG_FAIL       : `MSG_PASS;
            tx_pf_code   <= fsm_rx_err ? `MSG_FP_CODE_12 : `MSG_FP_CODE_11;
            ad_acq_en    <= `LOW;
            tx_adc_cnt   <= 0;
         end
         default:;
      endcase      
   end
            
   ////////////////// TX STATEMENT         
   
   wire                          tx_msg_sop;
   reg  [2:0]                    tx_st=`ST_MSG_IDLE;
   reg                           tx_vd;
   reg  [`USB_DATA_NBIT-1:0]     tx_data;
   reg                           tx_eop;
   reg  [`BUFFER_BADDR_NBIT-1:0] tx_buf_baddr; // Base address of BUFFER
                                               // 2'b00: Hadshake
                                               // 2'b01: Reserved
                                               // 2'b10: ADC Data Ping Buffer
                                               // 2'b11: ADC Data Pang Buffer
   reg  [`USB_ADDR_NBIT-1:0]     tx_buf_addr;  // low address of BUFFER
   reg  [`USB_ADDR_NBIT-1:0]     tx_cnt;
   reg                           ad_rd;
   reg  [`BUFFER_BADDR_NBIT-1:0] tx_baddr;
   reg  [`AD_CNT_NBIT-1:0]       p_adc_cnt;

   assign tx_msg_sop = proc_handshake_start |
                      (ad_acq_en & ad_switch);
   assign tx_addr    = {tx_buf_baddr,tx_buf_addr};
   
   always@(posedge mclk) begin: tx_fsm
      tx_vd  <= `LOW;
      tx_eop <= `LOW;
      ad_rd  <= `LOW;
      case(tx_st) 
         `ST_MSG_IDLE: begin
            tx_buf_addr <= 0;
            tx_cnt <= 0;
            if(tx_msg_sop)
               tx_st <= `ST_MSG_HEAD;
         end
         `ST_MSG_HEAD: begin
            tx_vd <= `HIGH;
            tx_buf_addr <= 0;
            tx_data <= `MSG_HEAD;
            tx_st <= `ST_MSG_TYPE;
            if(tx_msg_type == `MSG_TYPE_HANDSHAKE)
               tx_buf_baddr <= 0;
            else if(tx_msg_type == `MSG_TYPE_START) begin
               if(tx_buf_baddr==`BUFFER_BADDR_NBIT'd0 || tx_buf_baddr=={`BUFFER_BADDR_NBIT{1'b1}})
                  tx_buf_baddr <= `BUFFER_BADDR_NBIT'd1;
               else
                  tx_buf_baddr <= tx_buf_baddr + 1'b1;
            end
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
            tx_st       <= `ST_MSG_DATA;
            tx_cnt      <= `AD_CHE_DATA_SIZE + `AD_CNT_NWORD + 1'b1;
            if(tx_msg_type==`MSG_TYPE_HANDSHAKE) begin // when handshake, gg
               tx_st   <= `ST_MSG_IDLE;
               tx_eop  <= `HIGH;
               tx_baddr<= tx_buf_baddr;
            end
         end
         `ST_MSG_DATA: begin
            tx_vd       <= `HIGH;
            tx_buf_addr <= tx_buf_addr + 1'b1;
            if(tx_cnt==`AD_CHE_DATA_SIZE + `AD_CNT_NWORD + 1'b1)
            	tx_data <= ascii_ch_addr;
            else if(tx_cnt==`AD_CHE_DATA_SIZE + `AD_CNT_NWORD) begin
            	p_adc_cnt <= tx_adc_cnt<<`USB_DATA_NBIT;
            	tx_data   <= {tx_adc_cnt[`AD_CNT_NBIT-`USB_DATA_NBIT/2-1:`AD_CNT_NBIT-`USB_DATA_NBIT],tx_adc_cnt[`AD_CNT_NBIT-1:`AD_CNT_NBIT-`USB_DATA_NBIT/2]};
            end
            else if(tx_cnt<`AD_CHE_DATA_SIZE + `AD_CNT_NWORD && tx_cnt>`AD_CHE_DATA_SIZE) begin
            	p_adc_cnt <= p_adc_cnt<<`USB_DATA_NBIT;
            	tx_data   <= {p_adc_cnt[`AD_CNT_NBIT-`USB_DATA_NBIT/2-1:`AD_CNT_NBIT-`USB_DATA_NBIT],p_adc_cnt[`AD_CNT_NBIT-1:`AD_CNT_NBIT-`USB_DATA_NBIT/2]};
            end
            else begin
               ad_rd   <= `HIGH;
               tx_data <= {ad_data[`USB_DATA_NBIT/2-1:0],ad_data[`USB_DATA_NBIT-1:`USB_DATA_NBIT/2]};
            end
            tx_cnt      <= tx_cnt - 1'b1;
            if(tx_cnt==0) begin
               ad_rd <= `LOW;
               tx_st <= `ST_MSG_END;
            end
         end
         `ST_MSG_END: begin
            tx_cnt     <= 0;
            if(tx_cnt=={`USB_ADDR_NBIT{1'b1}})
               tx_data <= {`MSG_END_N,`MSG_END_R};
            else
               tx_data <= 0; // clean TX BUFFER
            tx_vd       <= `HIGH;
            tx_buf_addr <= tx_buf_addr + 1'b1;
            if(tx_buf_addr=={`USB_ADDR_NBIT{1'b1}}) begin
               tx_vd   <= `LOW;
               tx_st   <= `ST_MSG_IDLE;
               tx_eop  <= `HIGH;
               tx_baddr<= tx_buf_baddr;
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