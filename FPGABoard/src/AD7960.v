/////////////////////////// INCLUDE /////////////////////////////
`include "../src/globals.v"

////////////////////////////////////////////////////////////////
//
//  Module  : AD7960
//  Designer: Hoki
//  Company : HWorks
//  Date    : 2016/9/24 16:10:03
//
////////////////////////////////////////////////////////////////
// 
//  Description: AD7960 controller
//
////////////////////////////////////////////////////////////////
// 
//  Revision: 1.0

`timescale 1ns / 1ps

/////////////////////////// MODULE //////////////////////////////
module AD7960
    (
        input           fast_clk_i,                 // Maximum 300 MHz Clock, used for serial transfer
        input           reset_n_i,                  // Reset signal, active low
        input           start_i,                    // Start signal, active high
        input   [ 3:0]  en_i,                       // Enable pins input
        input           d_pos_i,                    // Data In, Positive Pair
        input           dco_pos_i,                  // Echoed Clock In, Positive Pair
        output  [ 3:0]  en_o,                       // Enable pins output
        output          cnv_pos_o,                  // Convert Out, Positive Pair
        output          cnv_neg_o,                  // Convert Out, Negative Pair
        output          clk_pos_o,                  // Clock Out, Positive Pair
        output          clk_neg_o,                  // Clock Out, Negative Pair
        output          data_rd_rdy_o,              // Signals that new data is available
        output  [17:0]  data_o                      // Read Data
    );

//------------------------------------------------------------------------------
//----------- Local Parameters -------------------------------------------------
//------------------------------------------------------------------------------
// FPGA Clock Frequency
parameter real FPGA_CLOCK_FREQ = 200; // MHz

// Conversion signal generation
parameter real TCYC            = 0.200; // ms
parameter real TCNVH           = 0.030; // ms
parameter real TMSB            = 0.180; // ms

`ifndef AD_TIME
parameter [8:0]  ADC_CYC_CNT  = FPGA_CLOCK_FREQ * TCYC - 1;
parameter [8:0]  ADC_CNVH_CNT = FPGA_CLOCK_FREQ * TCNVH - 1;
parameter [8:0]  ADC_MSB_CNT  = FPGA_CLOCK_FREQ * TMSB - 1;
`else
reg  [8:0]  ADC_CYC_CNT  = FPGA_CLOCK_FREQ * TCYC - 1;
reg  [8:0]  ADC_CNVH_CNT = FPGA_CLOCK_FREQ * TCNVH - 1;
reg  [8:0]  ADC_MSB_CNT  = FPGA_CLOCK_FREQ * TMSB - 1;

// Initialize time parameter of AD7960
wire        ad_time_wr;
reg  [1:0]  ad_time_addr;
wire [8:0]  ad_time_data;
ad_time  ad_time_u (
   .address(ad_time_addr),
   .clock  (fast_clk_i  ),
   .q      (ad_time_data)
);
always@(posedge fast_clk_i) begin
   ad_time_addr <= ad_time_addr + 1'b1;
   if(ad_time_addr==2)
      ADC_CYC_CNT <= ad_time_data;
   if(ad_time_addr==3)
      ADC_CNVH_CNT <= ad_time_data;
   if(ad_time_addr==0)
      ADC_MSB_CNT <= ad_time_data;
end
`endif
      
// Serial Interface
parameter               SERIAL_IDLE_STATE       = 3'b001;
parameter               SERIAL_READ_STATE       = 3'b010;
parameter               SERIAL_DONE_STATE       = 3'b100; 
 
//------------------------------------------------------------------------------
//----------- Registers Declarations -------------------------------------------
//------------------------------------------------------------------------------ 
reg  [ 8:0]  adc_tcyc_cnt;
reg  [ 2:0]  serial_present_state;
reg  [ 2:0]  serial_next_state;
reg  [ 4:0]  sclk_cnt;
reg  [ 4:0]  sclk_echo_cnt;
reg  [17:0]  serial_buffer;
reg          serial_read_done_s;

//------------------------------------------------------------------------------
//----------- Wires Declarations -----------------------------------------------
//------------------------------------------------------------------------------
wire         cnv_s; 
wire         tmsb_done_s;
wire         buffer_reset_s;
wire         clk_s;
wire         sclk_s;
wire         sdi_s; 

//------------------------------------------------------------------------------
//----------- Assign/Always Blocks ---------------------------------------------
//------------------------------------------------------------------------------
assign clk_s            = ((serial_present_state == SERIAL_READ_STATE)&&(sclk_cnt > 5'd0)&&(buffer_reset_s != 1'b1)) ? 1'b1 : 1'b0;  
assign data_rd_rdy_o    = serial_read_done_s; 
assign cnv_s            = (adc_tcyc_cnt >= (ADC_CYC_CNT-ADC_CNVH_CNT)) ? 1'b1 : 1'b0;
assign tmsb_done_s      = (adc_tcyc_cnt == (ADC_CYC_CNT-ADC_MSB_CNT))  ? 1'b1 : 1'b0;
assign buffer_reset_s   = (adc_tcyc_cnt == (ADC_CYC_CNT-ADC_MSB_CNT+1))  ? 1'b1 : 1'b0;
assign en_o             = en_i;

// Update conversion timing counters 
always @(posedge fast_clk_i)
begin
    if(reset_n_i == 1'b0)
    begin
        adc_tcyc_cnt <= ADC_CYC_CNT;
    end
    else
    begin
        if(adc_tcyc_cnt != 0) begin
            adc_tcyc_cnt <= adc_tcyc_cnt - 1'd1;
        end
        else if(start_i) begin
            adc_tcyc_cnt <= ADC_CYC_CNT;
        end
    end
end 

// State Switch Logic
always @(serial_present_state, tmsb_done_s, sclk_cnt, sclk_echo_cnt)
begin
    serial_next_state <= serial_present_state;
    case(serial_present_state)
        SERIAL_IDLE_STATE:
            begin
                if(tmsb_done_s == 1'b1)
                begin
                    serial_next_state <= SERIAL_READ_STATE;
                end
            end
        SERIAL_READ_STATE:
            begin
                if((sclk_echo_cnt == 5'd0)&&(sclk_cnt == 5'd0))
                begin
                    serial_next_state <= SERIAL_DONE_STATE;
                end
            end
        SERIAL_DONE_STATE:
            begin
                serial_next_state <= SERIAL_IDLE_STATE;
            end 
        default:
            begin
                serial_next_state <= SERIAL_IDLE_STATE;
            end
    endcase
end

// State Output Logic
always @(posedge fast_clk_i)
begin
    if(reset_n_i == 1'b0)
    begin
        serial_read_done_s      <= 1'b0;
        serial_present_state    <= SERIAL_IDLE_STATE;
    end
    else
    begin
        serial_present_state <= serial_next_state;
        case(serial_present_state)
            SERIAL_IDLE_STATE:
                begin
                    serial_read_done_s <= 1'b0;
                end
            SERIAL_READ_STATE:
                begin
                    serial_read_done_s <= 1'b0;
                end
            SERIAL_DONE_STATE:
                begin
                    serial_read_done_s <= 1'b1;
                end
            default: 
                begin   
                    serial_read_done_s <= 1'b0;
                end
        endcase
    end
end

// Count SCLK signals Out
always @(posedge fast_clk_i)
begin
    if(buffer_reset_s == 1'b1)
    begin  
        sclk_cnt <= 5'd18; 
    end
    else if ((sclk_cnt > 5'd0)&&(clk_s == 1'b1))
    begin
        sclk_cnt <= sclk_cnt - 5'd1;
    end
end

// Shift Data In

// Data In LVDS -> Single
assign sdi_s  = d_pos_i;

// Serial Clock In LVDS -> Single
assign sclk_s = dco_pos_i;

always @(posedge sclk_s or posedge buffer_reset_s)
begin
    if(buffer_reset_s == 1'b1)
    begin
        serial_buffer <= 18'b111111111111111111;
        sclk_echo_cnt <= 5'd18; 
    end
    else if(sclk_echo_cnt > 5'd0)
    begin
        sclk_echo_cnt <= sclk_echo_cnt - 5'd1;
        serial_buffer <= {serial_buffer[16:0], sdi_s};
    end
end
   
assign data_o = serial_buffer;
   
// Conversion Out Single -> LVDS
ALT_OUTBUF_DIFF #(.io_standard("LVDS_E_3R"))
lvds_cnv (
   .i   (cnv_s    ),
   .o   (cnv_pos_o),
   .obar(cnv_neg_o)
);

// Clock Out Single -> LVDS    
ALT_OUTBUF_DIFF #(.io_standard("LVDS_E_3R"))
lvds_clk (
   .i   (fast_clk_i & clk_s),
   .o   (clk_pos_o),
   .obar(clk_neg_o)
);

endmodule