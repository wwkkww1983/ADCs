`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////
//
//  Module  : ad7606
//  Designer: Kyle Hu
//  Company : Phase Motion Control Ningbo Co,Ltd.
//  Date    : 2016/5/17 9:22:59
//
////////////////////////////////////////////////////////////////
// 
//  Description: AD7606 controller
//
////////////////////////////////////////////////////////////////
// 
//  Revision: 1.0

module ad7606(
   clk,
   rst_n,
   ad_data,
   ad_busy,
   first_data,
   ad_os,
   ad_cs,
   ad_rd,
   ad_reset,
   ad_convstab,
   ad_ch1,
   ad_ch2,
   ad_ch3,
   ad_ch4,
   ad_ch5,
   ad_ch6,
   ad_ch7,
   ad_ch8,
   ad_vd
);

   ///////////////// PARAMETER ////////////////
   parameter IDLE      = 4'd0 ;
   parameter AD_CONV   = 4'd1 ;
   parameter Wait_1    = 4'd2 ;
   parameter Wait_busy = 4'd3 ;
   parameter READ_CH1  = 4'd4 ;
   parameter READ_CH2  = 4'd5 ;
   parameter READ_CH3  = 4'd6 ;
   parameter READ_CH4  = 4'd7 ;
   parameter READ_CH5  = 4'd8 ;
   parameter READ_CH6  = 4'd9 ;
   parameter READ_CH7  = 4'd10;
   parameter READ_CH8  = 4'd11;
   parameter READ_DONE = 4'd12;

   ////////////////// PORT ////////////////////
   input                      clk        ; //50mhz
   input                      rst_n      ;
   input  [`AD_DATA_NBIT-1:0] ad_data    ; //ad7606 data
   input                      ad_busy    ; //ad7606 busy flag 
   input                      first_data ; //ad7606 first data flag        
   output [2:0]               ad_os      ; //ad7606 oversample
   output                     ad_cs      ; //ad7606 AD cs
   output                     ad_rd      ; //ad7606 AD data read
   output                     ad_reset   ; //ad7606 AD reset
   output                     ad_convstab; //ad7606 AD convert start

   output [`AD_DATA_NBIT-1:0] ad_ch1     ; //AD channel 1 data
   output [`AD_DATA_NBIT-1:0] ad_ch2     ; //AD channel 2 data
   output [`AD_DATA_NBIT-1:0] ad_ch3     ; //AD channel 3 data
   output [`AD_DATA_NBIT-1:0] ad_ch4     ; //AD channel 4 data
   output [`AD_DATA_NBIT-1:0] ad_ch5     ; //AD channel 5 data
   output [`AD_DATA_NBIT-1:0] ad_ch6     ; //AD channel 6 data
   output [`AD_DATA_NBIT-1:0] ad_ch7     ; //AD channel 7 data
   output [`AD_DATA_NBIT-1:0] ad_ch8     ; //AD channel 8 data   
   output                     ad_vd      ; //AD data valid

   ////////////////// ARCH ////////////////////

   assign ad_os=3'b000;

   ////////////////// AD RESET
   reg [15:0] cnt;
   
   always@(posedge clk) begin
      if(cnt<16'hffff) begin
        cnt<=cnt+1'b1;
        ad_reset<=1'b1;
      end
      else
        ad_reset<=1'b0;       
   end

   ////////////////// FSM
   reg [5:0]               i;
   reg [3:0]               state;
   reg                     ad_cs      ; //AD cs
   reg                     ad_rd      ; //AD data read
   reg                     ad_reset   ; //AD reset
   reg                     ad_convstab; //AD convert start
   reg [`AD_DATA_NBIT-1:0] ad_ch1     ; //AD channel 1 data
   reg [`AD_DATA_NBIT-1:0] ad_ch2     ; //AD channel 2 data
   reg [`AD_DATA_NBIT-1:0] ad_ch3     ; //AD channel 3 data
   reg [`AD_DATA_NBIT-1:0] ad_ch4     ; //AD channel 4 data
   reg [`AD_DATA_NBIT-1:0] ad_ch5     ; //AD channel 5 data
   reg [`AD_DATA_NBIT-1:0] ad_ch6     ; //AD channel 6 data
   reg [`AD_DATA_NBIT-1:0] ad_ch7     ; //AD channel 7 data
   reg [`AD_DATA_NBIT-1:0] ad_ch8     ; //AD channel 8 data   
   reg                     ad_vd      ;
   reg [8:0]               ad_sp_cnt  ; // 0 ~ 249
   
   always @(posedge clk) begin
      if (ad_reset==1'b1) begin 
         state<=IDLE; 
         ad_ch1<=0;
         ad_ch2<=0;
         ad_ch3<=0;
         ad_ch4<=0;
         ad_ch5<=0;
         ad_ch6<=0;
         ad_ch7<=0;
         ad_ch8<=0;
         ad_cs<=1'b1;
         ad_rd<=1'b1; 
         ad_convstab<=1'b1;
         i<=0;
         ad_vd<=1'b0;
         ad_sp_cnt <= 0;
      end      
      else begin
         ad_vd <= 1'b0;
         ad_sp_cnt <= ad_sp_cnt + 1'b1;
         case(state)
         IDLE: begin
            ad_cs<=1'b1;
            ad_rd<=1'b1; 
            ad_convstab<=1'b1;
            if(i==20) begin
               i<=0;          
               state<=AD_CONV;
            end
            else 
               i<=i+1'b1;
         end
         AD_CONV: begin     
            if(i==2) begin                        //�ȴ�2��clock
               i<=0;          
               state<=Wait_1;
               ad_convstab<=1'b1;                  
            end
            else begin
               i<=i+1'b1;
               ad_convstab<=1'b0;                     //����ADת��
            end
         end
         Wait_1: begin            
            if(i==5) begin                           //�ȴ�5��clock, �ȴ�busy�ź�Ϊ��
               i<=0;
               state<=Wait_busy;
            end
            else 
               i<=i+1'b1;
         end     
         Wait_busy: begin            
             if(ad_busy==1'b0) begin                    //�ȴ�busy�ź�Ϊ��
                i<=0;          
                state<=READ_CH1;
             end
         end
         READ_CH1: begin 
             ad_cs<=1'b0;                              //cs�ź���Ч    
             if(i==3) begin
                ad_rd<=1'b1;
                i<=0;
                ad_ch1<=ad_data;                        //��CH1
                state<=READ_CH2;           
             end
             else begin
                ad_rd<=1'b0;  
                i<=i+1'b1;
             end
         end
         READ_CH2: begin 
             if(i==3) begin
                ad_rd<=1'b1;
                i<=0;
                ad_ch2<=ad_data;                        //��CH2
                state<=READ_CH3;           
             end
             else begin
                ad_rd<=1'b0;  
                i<=i+1'b1;
             end
         end
         READ_CH3: begin 
             if(i==3) begin
                ad_rd<=1'b1;
                i<=0;
                ad_ch3<=ad_data;                        //��CH3
                state<=READ_CH4;           
             end
             else begin
                ad_rd<=1'b0;  
                i<=i+1'b1;
             end
         end
         READ_CH4: begin 
             if(i==3) begin
                ad_rd<=1'b1;
                i<=0;
                ad_ch4<=ad_data;                        //��CH4
                state<=READ_CH5;           
             end
             else begin
                ad_rd<=1'b0;  
                i<=i+1'b1;
             end
         end
         READ_CH5: begin 
             if(i==3) begin
                ad_rd<=1'b1;
                i<=0;
                ad_ch5<=ad_data;                        //��CH5
                state<=READ_CH6;           
             end
             else begin
                ad_rd<=1'b0;  
                i<=i+1'b1;
             end
         end
         READ_CH6: begin 
             if(i==3) begin
                ad_rd<=1'b1;
                i<=0;
                ad_ch6<=ad_data;                        //��CH6
                state<=READ_CH7;           
             end
             else begin
                ad_rd<=1'b0;  
                i<=i+1'b1;
             end
         end
         READ_CH7: begin 
             if(i==3) begin
                ad_rd<=1'b1;
                i<=0;
                ad_ch7<=ad_data;                        //��CH7
                state<=READ_CH8;           
             end
             else begin
                ad_rd<=1'b0;  
                i<=i+1'b1;
             end
         end
         READ_CH8: begin 
             if(i==3) begin
                ad_rd<=1'b1;
                i<=0;
                ad_ch8<=ad_data;                        //��CH8
                state<=READ_DONE;             
             end
             else begin
                ad_rd<=1'b0;  
                i<=i+1'b1;
             end
         end
         READ_DONE:begin
            if(ad_sp_cnt>=9'd249) begin
               ad_sp_cnt <= 0;
               ad_rd<=1'b1;   
               ad_cs<=1'b1;
               state<=IDLE;
               ad_vd<=1'b1;
            end
         end    
         default:  state<=IDLE;
         endcase   
      end    
   end

endmodule
