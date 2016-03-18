library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity MSDAP_RTL is port
(
	Sclk		: in std_logic;
	Dclk		: in std_logic;
	Start		: in std_logic;
	Reset_n	: in std_logic;
	Frame		: in std_logic;
	InputL		: in std_logic;
	InputR		: in std_logic;
	Inready 	: out std_logic;
	Outready : out std_logic;
	OutputL 	: out std_logic;
	OutputR 	: out std_logic
);
end MSDAP_RTL;

architecture RTL of MSDAP_RTL is

component FIR  port
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
end component;

component main_controller port
(
	sclk		: in std_logic;
	dclk		: in std_logic;
	start		: in std_logic;
	reset_n	: in std_logic;
	frame		: in std_logic;
	allzeroL	: in std_logic;
	allzeroR	: in std_logic;
	outready_L	: in std_logic;
	outready_R	: in std_logic;
	load_rj		: out std_logic;
	load_coef	: out std_logic;
	load_data	: out std_logic;
	enable_compute		: out std_logic;
	sleep				: out std_logic;
	inready 		: out std_logic;
	outready 	: out std_logic;
	clr_receive		: out std_logic;
	clr_transmit	: out std_logic;
	clr_rj		: out std_logic;
	clr_coef	: out std_logic;
	clr_voice	: out std_logic;
	clr_fir		: out std_logic;
	rj_w_addr	: out std_logic_vector (3 DOWNTO 0);
	coef_w_addr	: out std_logic_vector (8 DOWNTO 0)
);
end component;

signal outready_L,outready_R:std_logic;
signal allzeroL,allzeroR:std_logic;
signal load_rj,load_coef,load_data:std_logic;
signal clear_receive,clr_transmit:std_logic;
signal clr_rj,clr_coef,clr_voice,clr_fir:std_logic;
signal enable_compute,sleep:std_logic;
signal rj_w_addr:std_logic_vector (3 DOWNTO 0);
signal coef_w_addr:std_logic_vector (8 DOWNTO 0);


begin
main_ctrl:main_controller port map
(
	sclk		=>sclk,
	dclk		=>dclk,
	start		=>start,
	reset_n	=>reset_n,
	frame		=>frame,
	allzeroL	=>allzeroL,
	allzeroR	=>allzeroR,
	outready_L	=>outready_L,
	outready_R	=>outready_R,
	load_rj		=>load_rj,
	load_coef	=>load_coef,
	load_data	=>load_data,
	enable_compute		=>enable_compute,
	clr_receive		=>clear_receive,
	clr_transmit		=>clr_transmit,
	clr_rj		=>clr_rj,
	clr_coef	=>clr_coef,
	clr_voice	=>clr_voice,
	clr_fir		=>clr_fir,
	sleep	=>sleep,
	rj_w_addr	=>rj_w_addr,
	coef_w_addr	=>coef_w_addr,
	inready 	=>inready,
	outready 	=>outready
);

FIR_L :FIR port map 
(
	sclk		=>sclk,
	dclk		=>dclk,
	reset_n		=>reset_n,
	frame		=>frame,
	load_rj		=>load_rj,
	load_coef	=>load_coef,
	load_data	=>load_data,
	enable_compute		=>enable_compute,
	clr_receive		=>clear_receive,
	clr_transmit		=>clr_transmit,
	clr_rj		=>clr_rj,
	clr_coef	=>clr_coef,
	clr_voice	=>clr_voice,
	clr_fir		=>clr_fir,
	sleep	=>sleep,
	sinput		=>InputL,
	rj_w_addr 	=>rj_w_addr,
	coef_w_addr	=>coef_w_addr,
	soutput	=>outputL,
	output_ready=>outready_L,
	allzeros	=>allzeroL
);

FIR_R :FIR port map 
(
	sclk		=>sclk,
	dclk		=>dclk,
	reset_n		=>reset_n,
	frame		=>frame,
	load_rj		=>load_rj,
	load_coef	=>load_coef,
	load_data	=>load_data,
	enable_compute		=>enable_compute,
	clr_receive		=>clear_receive,
	clr_transmit		=>clr_transmit,
	clr_rj		=>clr_rj,
	clr_coef	=>clr_coef,
	clr_voice	=>clr_voice,
	clr_fir		=>clr_fir,
	sleep	=>sleep,
	sinput		=>InputR,
	rj_w_addr 	=>rj_w_addr,
	coef_w_addr	=>coef_w_addr,
	soutput	=>outputR,
	output_ready=>outready_R,
	allzeros	=>allzeroR
);


end RTL;