set_false_path -from {ad7606:u_ad7606|ad_convstab} -to [get_ports {AD_CONVSTAB}]
set_false_path -from {ad7606:u_ad7606|ad_cs} -to [get_ports {AD_CS}] 
set_false_path -from {ad7606:u_ad7606|ad_rd} -to [get_ports {AD_RD}] 
set_false_path -from {ad7606:u_ad7606|ad_reset} -to [get_ports {AD_RESET}]
set_false_path -from [get_ports {AD_BUSY}] -to {ad7606:u_ad7606|i[*]}
set_false_path -from [get_ports {AD_BUSY}] -to {ad7606:u_ad7606|state.*}
set_false_path -from [get_ports {AD_DATA[*]}] -to {ad7606:u_ad7606|ad_ch*[*]}
set_false_path -from {OUT_SYNC~reg0} -to [get_ports {OUT_SYNC}]