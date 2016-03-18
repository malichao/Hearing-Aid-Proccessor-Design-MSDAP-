library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity ALU is port
(
		clk     	:in std_logic;
		load  		:in std_logic;
		shift		:in	std_logic;
		clr			:in	std_logic;
		sign_bit	:in std_logic;
		input		:in std_logic_vector (15 DOWNTO 0);
		output		:out std_logic_vector (39 DOWNTO 0)
);
end ALU;

architecture RTL of ALU is
	signal adder_out		:std_logic_vector (39 DOWNTO 0);
	signal adder_in			:std_logic_vector (39 DOWNTO 0);
	signal shift_out		:std_logic_vector (39 DOWNTO 0):=X"0000000000";
	
	component Extender port
	(
		input 		: in std_logic_vector (15 DOWNTO 0);
		sign_bit	: in std_logic;
		output  	: out std_logic_vector (39 DOWNTO 0)
	);
	end component;
	
	component Adder port 
	(		
		a 			: in std_logic_vector (39 DOWNTO 0);
		b 			: in std_logic_vector (39 DOWNTO 0);
		output	: out std_logic_vector (39 DOWNTO 0)
	);
	end component;
	
	component Shifter port 
	(
		clk		: in std_logic;
		clr		: in std_logic;
		shift	: in std_logic;
		load		: in std_logic;
		input 	: in std_logic_vector (39 DOWNTO 0);
		output : out std_logic_vector (39 DOWNTO 0)
	);
	end component;
	


begin
-- Instantiate
	extender1:Extender
	port map
	(
		input 		=>input,
		sign_bit	=>sign_bit,
		output		=>adder_in
	);
	
	adder1 :Adder
	  port map
	  (
			a 			=>adder_in,
			b 			=>shift_out,
			output		=>adder_out
		);
			
	shifter1:Shifter
		port map
		(
			input 	=>adder_out,
			clk		=>clk,
			load		=>load,
			shift	=>shift,
			clr		=>clr,
			output	=>shift_out
		);

	output<=shift_out;
end RTL;