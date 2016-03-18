library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity Extender is port
(
	input 		: in std_logic_vector (15 DOWNTO 0);
	sign_bit	: in std_logic;
	output  	: out std_logic_vector (39 DOWNTO 0)
);
end Extender;

architecture RTL of Extender is
signal data : std_logic_vector (39 DOWNTO 0);
signal data_com : std_logic_vector (39 DOWNTO 0);
begin
	extender1:process(input,sign_bit)
		variable temp	:std_logic_vector(15 DOWNTO 0):=X"0000";
		begin
			if (input = X"0000") then
				data <=X"0000000000";
				data_com <=X"0000000000";
			elsif input(15) = '1' then  --negative
				temp := (not (input-'1')) and X"7FFF";
				data <=X"FF" & input & X"0000";
				data_com <=X"00" & temp & X"0000";
			else 
				temp := (not input)+'1';
				data <=X"00" & input & X"0000";
				data_com <=X"FF" & temp & X"0000";
			end if;
		end process;
		output<=data when sign_bit='0' else data_com;
end RTL;
