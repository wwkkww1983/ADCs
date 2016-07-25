create_clock -name {IN_AD_CLK} -period 6.667 [get_ports {IN_AD_CLK}]

set_clock_groups -exclusive -group [get_clocks {adc_pll:adc_pll_u|altpll:altpll_component|adc_pll_altpll:auto_generated|wire_pll1_clk[1]}] -group [get_clocks {IN_AD_CLK}]

set_output_delay -clock { adc_pll:adc_pll_u|altpll:altpll_component|adc_pll_altpll:auto_generated|wire_pll1_clk[0] } 0 [get_ports {OUT_AD_CLK}]

set_false_path -from [get_ports {AD_DB[*]}] -to {ad_cache:u_ad_cache|buf_wdata[*]}
set_false_path -from [get_ports {IN_SPCLK}] -to {ad_cache:u_ad_cache|p_spclk[0]}
set_false_path -from [get_ports {IN_SYNC}] -to {ad_cache:u_ad_cache|p_sync[0]}
set_false_path -from {OUT_SYNC~reg0} -to [get_ports {OUT_SYNC}]
