
module sdram (
	avalon_mms_address,
	avalon_mms_byteenable_n,
	avalon_mms_chipselect,
	avalon_mms_writedata,
	avalon_mms_read_n,
	avalon_mms_write_n,
	avalon_mms_readdata,
	avalon_mms_readdatavalid,
	avalon_mms_waitrequest,
	in_clk_clk,
	in_rst_reset_n,
	port_addr,
	port_ba,
	port_cas_n,
	port_cke,
	port_cs_n,
	port_dq,
	port_dqm,
	port_ras_n,
	port_we_n);	

	input	[25:0]	avalon_mms_address;
	input	[3:0]	avalon_mms_byteenable_n;
	input		avalon_mms_chipselect;
	input	[31:0]	avalon_mms_writedata;
	input		avalon_mms_read_n;
	input		avalon_mms_write_n;
	output	[31:0]	avalon_mms_readdata;
	output		avalon_mms_readdatavalid;
	output		avalon_mms_waitrequest;
	input		in_clk_clk;
	input		in_rst_reset_n;
	output	[12:0]	port_addr;
	output	[1:0]	port_ba;
	output		port_cas_n;
	output		port_cke;
	output	[1:0]	port_cs_n;
	inout	[31:0]	port_dq;
	output	[3:0]	port_dqm;
	output		port_ras_n;
	output		port_we_n;
endmodule
