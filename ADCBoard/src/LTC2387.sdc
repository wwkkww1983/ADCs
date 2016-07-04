## Generated SDC file "ltc2387basic.sdc"

## Copyright (C) 1991-2013 Altera Corporation
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, Altera MegaCore Function License 
## Agreement, or other applicable license agreement, including, 
## without limitation, that your use is for the sole purpose of 
## programming logic devices manufactured by Altera and sold by 
## Altera or its authorized distributors.  Please refer to the 
## applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus II"
## VERSION "Version 13.1.0 Build 162 10/23/2013 SJ Web Edition"

## DATE    "Tue Jan 06 10:57:00 2015"

##
## DEVICE  "EP3C5F256C6"
##

#**************************************************************
# Time Information
#**************************************************************
set_time_format -unit ns -decimal_places 3

#**************************************************************
# Create Clock
#**************************************************************
create_clock -name clk_in -period 66.666 -waveform { 0.000 33.333 } [get_ports {CLK_IN}]
#derive_clocks -period 66.666	

#the following statement includes an assumed delay of 2.222nsec
create_clock -period 66.666 -waveform { 30.000 38.000 } -name latch control:ucontrol|LATCH

#**************************************************************
# Create Generated Clock
#**************************************************************
#derive_pll_clocks
create_generated_clock -name clk_360 -source [get_pins {upll|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 24 -master_clock {clk_in} [get_pins {upll|altpll_component|auto_generated|pll1|clk[0]}] 
create_generated_clock -name sync_v -source [get_pins {upll|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 4.000 -multiply_by 1 -divide_by 1 -phase 3.75 -master_clock {clk_in} [get_pins {upll|altpll_component|auto_generated|pll1|clk[1]}] 

#assume a delay of 2.3 nsec through the ADC
create_generated_clock -name dco_n -source [get_ports {CLK_ADC_n}] -edges {1 2 3} -edge_shift {2.3 2.3 2.3} [get_ports {DCO_n}]

#**************************************************************
# Set Clock Latency
#**************************************************************

#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty

#**************************************************************
# Set Input Delay
#**************************************************************
set_input_delay -add_delay -max -clock [get_clocks {dco_n}]  0.050 [get_ports {DA_n}]
set_input_delay -add_delay -min -clock [get_clocks {dco_n}]  -0.050 [get_ports {DA_n}]
set_input_delay -add_delay -max -clock_fall -clock [get_clocks {dco_n}]  0.050 [get_ports {DA_n}]
set_input_delay -add_delay -min -clock_fall -clock [get_clocks {dco_n}]  -0.050 [get_ports {DA_n}]

set_input_delay -add_delay -max -clock [get_clocks {dco_n}]  0.050 [get_ports {DB_n}]
set_input_delay -add_delay -min -clock [get_clocks {dco_n}]  -0.050 [get_ports {DB_n}]
set_input_delay -add_delay -max -clock_fall -clock [get_clocks {dco_n}]  0.050 [get_ports {DB_n}]
set_input_delay -add_delay -min -clock_fall -clock [get_clocks {dco_n}]  -0.050 [get_ports {DB_n}]

#**************************************************************
# Set Output Delay
#**************************************************************
set_output_delay -add_delay  -clock_fall -clock [get_clocks {latch}]  0.050 [get_ports {DATA[0]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {latch}]  0.050 [get_ports {DATA[1]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {latch}]  0.050 [get_ports {DATA[2]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {latch}]  0.050 [get_ports {DATA[3]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {latch}]  0.050 [get_ports {DATA[4]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {latch}]  0.050 [get_ports {DATA[5]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {latch}]  0.050 [get_ports {DATA[6]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {latch}]  0.050 [get_ports {DATA[7]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {latch}]  0.050 [get_ports {DATA[8]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {latch}]  0.050 [get_ports {DATA[9]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {latch}]  0.050 [get_ports {DATA[10]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {latch}]  0.050 [get_ports {DATA[11]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {latch}]  0.050 [get_ports {DATA[12]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {latch}]  0.050 [get_ports {DATA[13]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {latch}]  0.050 [get_ports {DATA[14]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {latch}]  0.050 [get_ports {DATA[15]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {latch}]  0.050 [get_ports {DATA[16]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {latch}]  0.050 [get_ports {DATA[17]}]

#**************************************************************
# Set Clock Groups
#**************************************************************

#**************************************************************
# Set False Path
#**************************************************************
set_false_path -from {dco_n} -to {latch}

#the following statements eliminate "unconstrained input path" warnings
set_false_path -from [get_ports {bits_18}] -to [get_clocks *]
set_false_path -from [get_ports {two_lane}] -to [get_clocks *]

#the following statements eliminate "unconstrained output path" warnings
set_false_path -from [get_clocks *] -to [get_ports {CNV_EN}]
set_false_path -from [get_clocks *] -to [get_ports {LATCH}]
set_false_path -from [get_clocks *] -to [get_ports {CLK_ADC_n}]
set_false_path -from [get_clocks *] -to [get_ports {CLK_ADC_n(n)}]

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

