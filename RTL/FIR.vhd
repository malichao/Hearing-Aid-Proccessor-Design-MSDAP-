library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity FIR is port
(
	sclk		: in std_logic;
	dclk		: in std_logic;
	reset_n	: in std_logic;
	frame		: in std_logic;
	load_rj		: in std_logic;
	load_coef	: in std_logic;
	load_data	: in std_logic;
	enable_compute		: in std_logic;
	clr_receive		: in std_logic;
	clr_transmit	: in std_logic;
	clr_rj		: in std_logic;
	clr_coef	: in std_logic;
	clr_voice	: in std_logic;
	clr_fir		: in std_logic;
	sleep	: in std_logic;
	sinput		: in std_logic;
	rj_w_addr 	: in std_logic_vector (3 DOWNTO 0);
	coef_w_addr	: in std_logic_vector (8 DOWNTO 0);
	soutput	: out std_logic;
	output_ready: out std_logic;
	allzeros	: out std_logic
);
end FIR;

architecture RTL of FIR is

component RJMem port
(
	clk		: in std_logic;
	clr		: in std_logic;
	write		: in std_logic;
	r_addr 	: in std_logic_vector (3 DOWNTO 0);
	w_addr 	: in std_logic_vector (3 DOWNTO 0);
	input	: in std_logic_vector (7 DOWNTO 0);
	output	: out std_logic_vector (7 DOWNTO 0)
);
end component;

component CoefMem port
(
	clk		: in std_logic;
	write	: in std_logic;
	clr		: in std_logic;
	r_addr 	: in std_logic_vector (8 DOWNTO 0);
	w_addr 	: in std_logic_vector (8 DOWNTO 0);
	input	: in std_logic_vector (8 DOWNTO 0);
	output	: out std_logic_vector (8 DOWNTO 0)
);
end component;

component VoiceMem port
(
	clk		: in std_logic;
	clr		: in std_logic;
	write	: in std_logic;
	allzeros: out std_logic;
	addr 	: in std_logic_vector (7 DOWNTO 0);
	input	: in std_logic_vector (15 DOWNTO 0);
	output	: out std_logic_vector (15 DOWNTO 0)
);
end component;

component Receiver port
(
	clk		: in std_logic;
	clr		: in std_logic;
	input	: in std_logic;
	output	: out std_logic_vector (15 DOWNTO 0)
);
end component;

component Transmitter  
port
(
	clk		: in std_logic;
	load		: in std_logic;
	frame	: in std_logic;
	reset	: in std_logic;
	input 		: in std_logic_vector (39 DOWNTO 0);
	out_ready: out std_logic;
	output 	: out std_logic
);
end component;

component ALU port
(
	clk     	:in std_logic;
	load  		:in std_logic;
	shift		:in	std_logic;
	clr			:in	std_logic;
	sign_bit	:in std_logic;
	input	:in std_logic_vector (15 DOWNTO 0);
	output	:out std_logic_vector (39 DOWNTO 0)
);
end component;

component ALU_controller  port
(
	Sclk     	:in std_logic;
	enable_compute	:in std_logic;
	clr		:in	std_logic;
	sleep	:in	std_logic;
	frame			:in	std_logic;
	clr_alu		:out std_logic;
	load_alu		:out std_logic;
	shift_alu	:out std_logic;
	load_dataout:out std_logic;
	dataout_ready:out std_logic;
	rj					:in std_logic_vector (7 DOWNTO 0);
	rj_addr		:out std_logic_vector (3 DOWNTO 0);
	coef				:in std_logic_vector (7 DOWNTO 0);
	coef_addr	:out std_logic_vector (8 DOWNTO 0);
	data_addr	:out std_logic_vector (7 DOWNTO 0)
);
end component;


	signal rj_raddr 	:std_logic_vector (3 DOWNTO 0):=X"0";
	signal coef_raddr 	:std_logic_vector (8 DOWNTO 0):='0' & X"00";
	signal data_index 	:std_logic_vector (7 DOWNTO 0):=X"00";
	signal pinput	 	:std_logic_vector (15 DOWNTO 0);
	signal poutput 	:std_logic_vector (39 DOWNTO 0);
	signal rj_reg	 	:std_logic_vector (7 DOWNTO 0);
	signal coef_reg 	:std_logic_vector (8 DOWNTO 0);
	signal input_reg 	:std_logic_vector (15 DOWNTO 0);
	signal sdata_ready	:std_logic;
	signal output_ready_ctrl		:std_logic;
	signal load_p2s		:std_logic;
	signal clr_alu,load_alu,shift_alu:std_logic;

begin

	alu1:ALU port map
		(
			clk     	=>Sclk,
			load  		=>load_alu,
			shift		=>shift_alu,
			clr			=>clr_alu,
			sign_bit		=>coef_reg(8),
			input		=>input_reg,
			output	=>poutput
		);

	alu_ctrl: ALU_controller  port map
	(
		Sclk     	=>Sclk,
		enable_compute	=>enable_compute,
		clr		=>clr_fir,
		sleep	=>sleep,
		frame		=>frame,
		clr_alu		=>clr_alu,
		load_alu	=>load_alu,
		shift_alu	=>shift_alu,
		load_dataout=>load_p2s,
		dataout_ready=>output_ready_ctrl,
		rj			=>rj_reg,
		coef		=>coef_reg(7 downto 0),
		coef_addr	=>coef_raddr,
		rj_addr	=>rj_raddr,
		data_addr	=>data_index
	);
	
	rj_mem:RjMem port map
	(
		clk		=>frame,
		write	=>load_rj,
		clr		=>clr_rj,
		r_addr =>rj_raddr,
		w_addr =>rj_w_addr,
		input	=>pinput(7 downto 0),
		output	=>rj_reg
	);

	coef_mem:CoefMem port map
	(
		clk		=>frame,
		clr		=>clr_coef,
		write	=>load_coef,
		r_addr =>coef_raddr,
		w_addr =>coef_w_addr,
		input	=>pinput(8 downto 0),
		output	=>coef_reg
	);


	voice_mem:VoiceMem port map
	(
		clk		=>frame,
		clr		=>clr_voice,
		write	=>load_data,
		allzeros=>allzeros,
		addr 	=>data_index,
		input	=>pinput,
		output	=>input_reg
	);


	Receiver1:Receiver port map
	(
		clk		=>dclk,
		clr		=>clr_receive,
		input	=>sinput,
		output	=>pinput
	);


	Transmitter1: Transmitter port map 
	(
		clk		=>sclk,
		load	=>load_p2s,
		frame	=>frame,
		reset	=>clr_transmit,
		input 	=>poutput,
		out_ready=>sdata_ready,
		output 	=>soutput
	);


	output_ready<=sdata_ready and output_ready_ctrl;
end RTL;