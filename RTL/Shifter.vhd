library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity Shifter is port
(
		clk		: in std_logic;
		clr		: in std_logic;
		shift	: in std_logic;
		load		: in std_logic;
		input 	: in std_logic_vector (39 DOWNTO 0);
		output : out std_logic_vector (39 DOWNTO 0)
);
end Shifter;

architecture RTL of Shifter is

signal temp:std_logic_vector(39 downto 0);
begin
	process(clk,clr)
	begin
		if clr='1' then
			temp<=(others=>'0');
		elsif rising_edge(clk) then
			if load='1' then
				temp<=input;
			elsif shift='1' then
				temp<=temp(39)&temp(39 downto 1);
			end if;
		end if;  
	end process;
	output<=temp;
end RTL;