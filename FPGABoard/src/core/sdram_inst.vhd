	component sdram is
		port (
			avalon_mms_address       : in    std_logic_vector(23 downto 0) := (others => 'X'); -- address
			avalon_mms_byteenable_n  : in    std_logic_vector(3 downto 0)  := (others => 'X'); -- byteenable_n
			avalon_mms_chipselect    : in    std_logic                     := 'X';             -- chipselect
			avalon_mms_writedata     : in    std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
			avalon_mms_read_n        : in    std_logic                     := 'X';             -- read_n
			avalon_mms_write_n       : in    std_logic                     := 'X';             -- write_n
			avalon_mms_readdata      : out   std_logic_vector(31 downto 0);                    -- readdata
			avalon_mms_readdatavalid : out   std_logic;                                        -- readdatavalid
			avalon_mms_waitrequest   : out   std_logic;                                        -- waitrequest
			port_addr                : out   std_logic_vector(12 downto 0);                    -- addr
			port_ba                  : out   std_logic_vector(1 downto 0);                     -- ba
			port_cas_n               : out   std_logic;                                        -- cas_n
			port_cke                 : out   std_logic;                                        -- cke
			port_cs_n                : out   std_logic;                                        -- cs_n
			port_dq                  : inout std_logic_vector(31 downto 0) := (others => 'X'); -- dq
			port_dqm                 : out   std_logic_vector(3 downto 0);                     -- dqm
			port_ras_n               : out   std_logic;                                        -- ras_n
			port_we_n                : out   std_logic;                                        -- we_n
			in_rst_reset_n           : in    std_logic                     := 'X';             -- reset_n
			in_clk_clk               : in    std_logic                     := 'X'              -- clk
		);
	end component sdram;

	u0 : component sdram
		port map (
			avalon_mms_address       => CONNECTED_TO_avalon_mms_address,       -- avalon_mms.address
			avalon_mms_byteenable_n  => CONNECTED_TO_avalon_mms_byteenable_n,  --           .byteenable_n
			avalon_mms_chipselect    => CONNECTED_TO_avalon_mms_chipselect,    --           .chipselect
			avalon_mms_writedata     => CONNECTED_TO_avalon_mms_writedata,     --           .writedata
			avalon_mms_read_n        => CONNECTED_TO_avalon_mms_read_n,        --           .read_n
			avalon_mms_write_n       => CONNECTED_TO_avalon_mms_write_n,       --           .write_n
			avalon_mms_readdata      => CONNECTED_TO_avalon_mms_readdata,      --           .readdata
			avalon_mms_readdatavalid => CONNECTED_TO_avalon_mms_readdatavalid, --           .readdatavalid
			avalon_mms_waitrequest   => CONNECTED_TO_avalon_mms_waitrequest,   --           .waitrequest
			port_addr                => CONNECTED_TO_port_addr,                --       port.addr
			port_ba                  => CONNECTED_TO_port_ba,                  --           .ba
			port_cas_n               => CONNECTED_TO_port_cas_n,               --           .cas_n
			port_cke                 => CONNECTED_TO_port_cke,                 --           .cke
			port_cs_n                => CONNECTED_TO_port_cs_n,                --           .cs_n
			port_dq                  => CONNECTED_TO_port_dq,                  --           .dq
			port_dqm                 => CONNECTED_TO_port_dqm,                 --           .dqm
			port_ras_n               => CONNECTED_TO_port_ras_n,               --           .ras_n
			port_we_n                => CONNECTED_TO_port_we_n,                --           .we_n
			in_rst_reset_n           => CONNECTED_TO_in_rst_reset_n,           --     in_rst.reset_n
			in_clk_clk               => CONNECTED_TO_in_clk_clk                --     in_clk.clk
		);

