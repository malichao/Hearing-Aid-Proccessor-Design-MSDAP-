library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity Transmitter is 
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
end Transmitter;

architecture RTL of Transmitter is

signal ready,send:std_logic;
signal temp	:std_logic_vector(39 downto 0);
signal i 	:std_logic_vector(5 downto 0);


begin 

	shift:process(clk,reset)
	begin
		if reset='1' then
			temp<=(others=>'0');
			output<='0';
		elsif rising_edge(clk) then
			if load ='1' then
				output<='0';
				temp<=input;
			elsif send='1' then
				output<=temp(0);
				temp<='0' & temp(39 downto 1) ;
			end if;
		end if; 
	end process; 

	shiftclk:process(clk,reset)
	begin
		if reset='1' then
			i<=(others=>'0');
			send<='0';
			ready<='0';
		elsif rising_edge(clk) then
			if frame='1' and send='0' then
				i<=B"101000";
				send<='1';
				ready<='0';
			else
				if i > B"000000" then
					i<=i-1;
					send<='1';
					ready<='1';
				else 
					i<=i;
					send<='0';
					ready<='0';
				end if;
			end if;
		end if;
	end process;

	out_ready<=ready;

end RTL;