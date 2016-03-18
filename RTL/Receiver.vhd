library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity Receiver is port
(
	clk		: in std_logic;
	clr		: in std_logic;
	input	: in std_logic;
	output	: out std_logic_vector (15 DOWNTO 0)
);
end Receiver;

architecture RTL of Receiver is

signal temp:std_logic_vector(15 downto 0);
begin
	process(clk,clr)
	begin
		if (clr='1') then
			temp<=(others=>'0');
		elsif (falling_edge(clk)) then
			temp <= input & temp(15 downto 1);
		end if;
	end process;

	output<=temp;

end RTL;