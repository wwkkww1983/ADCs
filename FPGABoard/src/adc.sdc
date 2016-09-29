create_clock -name AD_CLK -period 5 [get_keepers {AD7960:AD7960_U|adc_tcyc_cnt[0]}]

create_clock -name {DCO} -period 5 [get_ports {DCO}]

set_clock_groups -exclusive -group [get_clocks {AD_CLK}] -group [get_clocks {adc_pll_ext:adc_pll_u|altpll:altpll_component|adc_pll_ext_altpll1:auto_generated|wire_pll1_clk[0]}]
set_clock_groups -exclusive -group [get_clocks {DCO}] -group [get_clocks {adc_pll_ext:adc_pll_u|altpll:altpll_component|adc_pll_ext_altpll1:auto_generated|wire_pll1_clk[0]}]
set_clock_groups -exclusive -group [get_clocks {AD_CLK}] -group [get_clocks {usb_pll:usb_pll_u|altpll:altpll_component|usb_pll_altpll:auto_generated|wire_pll1_clk[2]}]

set_false_path -from [get_clocks {*}] -to [get_ports {AD_CLK*}]
set_false_path -from [get_clocks {*}] -to [get_ports {CNV*}]

set_input_delay -clock { DCO } -max 1 [get_ports {D}]
set_input_delay -clock { DCO } -min 0 [get_ports {D}]