create_generated_clock -name DCK_CLK -source [get_ports {AD_CLK}] -edges {1 2 3} -edge_shift {5 5 5} [get_ports {DCO}]

set_input_delay -clock { DCK_CLK } -max  0.05 [get_ports {D D(n)}]
set_input_delay -clock { DCK_CLK } -min -0.05 [get_ports {D D(n)}]

set_false_path -from [get_clocks *] -to [get_ports {CNV}]
set_false_path -from [get_clocks *] -to [get_ports {AD_CLK}]
set_false_path -from [get_clocks *] -to [get_ports {AD_CLK(n)}]