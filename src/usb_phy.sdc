## Generated SDC file "Z:/USBToMIPI/FPGA/sdc/usb_phy.sdc"

## Copyright (C) 1991-2015 Altera Corporation. All rights reserved.
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, the Altera Quartus Prime License Agreement,
## the Altera MegaCore Function License Agreement, or other 
## applicable license agreement, including, without limitation, 
## that your use is for the sole purpose of programming logic 
## devices manufactured by Altera and sold by Altera or its 
## authorized distributors.  Please refer to the applicable 
## agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 15.1.0 Build 185 10/21/2015 SJ Standard Edition"

## DATE    "Thu Nov 19 13:32:09 2015"

##
## DEVICE  "EP4CE10F17C8"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

 
#**************************************************************
# Create Generated Clock
#**************************************************************


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************


#**************************************************************
# Set Input Delay
#**************************************************************

set_input_delay -clock { usb_pll:usb_pll_u|altpll:altpll_component|usb_pll_altpll:auto_generated|wire_pll1_clk[1] } -clock_fall -max 15 [get_ports {USB_DB[*]}]
set_input_delay -clock { usb_pll:usb_pll_u|altpll:altpll_component|usb_pll_altpll:auto_generated|wire_pll1_clk[1] } -clock_fall -min 0 [get_ports {USB_DB[*]}]
set_input_delay -clock { usb_pll:usb_pll_u|altpll:altpll_component|usb_pll_altpll:auto_generated|wire_pll1_clk[1] } -clock_fall -max 13.5 [get_ports {USB_FLAGB}]
set_input_delay -clock { usb_pll:usb_pll_u|altpll:altpll_component|usb_pll_altpll:auto_generated|wire_pll1_clk[1] } -clock_fall -min 0 [get_ports {USB_FLAGB}]
set_input_delay -clock { usb_pll:usb_pll_u|altpll:altpll_component|usb_pll_altpll:auto_generated|wire_pll1_clk[1] } -clock_fall -max 13.5 [get_ports {USB_FLAGC}]
set_input_delay -clock { usb_pll:usb_pll_u|altpll:altpll_component|usb_pll_altpll:auto_generated|wire_pll1_clk[1] } -clock_fall -min 0 [get_ports {USB_FLAGC}]

#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -clock { usb_pll:usb_pll_u|altpll:altpll_component|usb_pll_altpll:auto_generated|wire_pll1_clk[1] } -clock_fall -max 3.2 [get_ports {USB_DB[*]}]
set_output_delay -clock { usb_pll:usb_pll_u|altpll:altpll_component|usb_pll_altpll:auto_generated|wire_pll1_clk[1] } -clock_fall -min -4.5 [get_ports {USB_DB[*]}]
set_output_delay -clock { usb_pll:usb_pll_u|altpll:altpll_component|usb_pll_altpll:auto_generated|wire_pll1_clk[1] } -clock_fall -max 2.7 [get_ports {USB_SLRD}]
set_output_delay -clock { usb_pll:usb_pll_u|altpll:altpll_component|usb_pll_altpll:auto_generated|wire_pll1_clk[1] } -clock_fall -min -3.7 [get_ports {USB_SLRD}]
set_output_delay -clock { usb_pll:usb_pll_u|altpll:altpll_component|usb_pll_altpll:auto_generated|wire_pll1_clk[1] } -clock_fall -max 2.1 [get_ports {USB_SLWR}]
set_output_delay -clock { usb_pll:usb_pll_u|altpll:altpll_component|usb_pll_altpll:auto_generated|wire_pll1_clk[1] } -clock_fall -min -3.6 [get_ports {USB_SLWR}]
set_output_delay -clock { usb_pll:usb_pll_u|altpll:altpll_component|usb_pll_altpll:auto_generated|wire_pll1_clk[1] } 0 [get_ports {USB_IFCLK}]
set_output_delay -clock { usb_pll:usb_pll_u|altpll:altpll_component|usb_pll_altpll:auto_generated|wire_pll1_clk[0] } 0 [get_ports {USB_XTALIN}]
set_output_delay -clock { usb_pll:usb_pll_u|altpll:altpll_component|usb_pll_altpll:auto_generated|wire_pll1_clk[1] } -clock_fall -max 5 [get_ports {USB_FIFOADR[*]}]
set_output_delay -clock { usb_pll:usb_pll_u|altpll:altpll_component|usb_pll_altpll:auto_generated|wire_pll1_clk[1] } -clock_fall -min -10 [get_ports {USB_FIFOADR[*]}]

set_max_delay -from [get_ports {USB_SLOE}] -to [get_ports {USB_DB[*]}] 10.5
set_min_delay -from [get_ports {USB_SLOE}] -to [get_ports {USB_DB[*]}] 0

set_max_delay -from [get_ports {USB_FIFOADR[*]}] -to [get_ports {USB_FLAGB}] 10.7

#**************************************************************
# Set Clock Groups
#**************************************************************

#**************************************************************
# Set False Path
#**************************************************************

set_false_path -from [get_ports {USB_FLAGB}] -to {USB_SLOE}
set_false_path -from [get_ports {USB_FLAGB}] -to {USB_SLRD}
set_false_path -from [get_ports {USB_FLAGC}] -to {USB_SLOE}
set_false_path -from {usb_slavefifo:u_usb_slavefifo|slwr} -to [get_ports {USB_FIFOADR[1]}]
set_false_path -from {usb_slavefifo:u_usb_slavefifo|tx_st.*} -to [get_ports {USB_DB[*]}]
set_false_path -from {USB_FLAGC} -to [get_ports {USB_DB[*]}]
set_false_path -from {USB_FLAGC} -to [get_ports {USB_DB[*]}]
set_false_path -from {buffered_ram:tx_buffer|altsyncram:buffered_ram_altsyncram|altsyncram_76s1:auto_generated|q_b[*]} -to [get_ports {USB_DB[*]}]
set_false_path -from {usb_slavefifo:u_usb_slavefifo|tx_st.001} -to [get_ports {USB_FIFOADR[1]}]
set_false_path -from {USB_FLAGC} -to {USB_SLRD}
set_false_path -from [get_ports {USB_FLAGB}] -to [get_ports {USB_FIFOADR[*]}]
set_false_path -from {usb_slavefifo:u_usb_slavefifo|tx_st.000} -to {USB_FIFOADR[1]}

#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

