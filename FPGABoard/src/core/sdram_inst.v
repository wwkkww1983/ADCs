	sdram u0 (
		.avalon_mms_address       (<connected-to-avalon_mms_address>),       // avalon_mms.address
		.avalon_mms_byteenable_n  (<connected-to-avalon_mms_byteenable_n>),  //           .byteenable_n
		.avalon_mms_chipselect    (<connected-to-avalon_mms_chipselect>),    //           .chipselect
		.avalon_mms_writedata     (<connected-to-avalon_mms_writedata>),     //           .writedata
		.avalon_mms_read_n        (<connected-to-avalon_mms_read_n>),        //           .read_n
		.avalon_mms_write_n       (<connected-to-avalon_mms_write_n>),       //           .write_n
		.avalon_mms_readdata      (<connected-to-avalon_mms_readdata>),      //           .readdata
		.avalon_mms_readdatavalid (<connected-to-avalon_mms_readdatavalid>), //           .readdatavalid
		.avalon_mms_waitrequest   (<connected-to-avalon_mms_waitrequest>),   //           .waitrequest
		.port_addr                (<connected-to-port_addr>),                //       port.addr
		.port_ba                  (<connected-to-port_ba>),                  //           .ba
		.port_cas_n               (<connected-to-port_cas_n>),               //           .cas_n
		.port_cke                 (<connected-to-port_cke>),                 //           .cke
		.port_cs_n                (<connected-to-port_cs_n>),                //           .cs_n
		.port_dq                  (<connected-to-port_dq>),                  //           .dq
		.port_dqm                 (<connected-to-port_dqm>),                 //           .dqm
		.port_ras_n               (<connected-to-port_ras_n>),               //           .ras_n
		.port_we_n                (<connected-to-port_we_n>),                //           .we_n
		.in_rst_reset_n           (<connected-to-in_rst_reset_n>),           //     in_rst.reset_n
		.in_clk_clk               (<connected-to-in_clk_clk>)                //     in_clk.clk
	);

