library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity Adder is port 
(		
		a 			: in std_logic_vector (39 DOWNTO 0);
		b 			: in std_logic_vector (39 DOWNTO 0);
		output	: out std_logic_vector (39 DOWNTO 0)
);
end Adder;

architecture RTL of Adder is
begin
	output <= (a + b);
end RTL;

