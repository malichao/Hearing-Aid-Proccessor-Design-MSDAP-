library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity RjMem is port
(
	clk		: in std_logic;
	write		: in std_logic;
	clr		: in std_logic;
	r_addr 	: in std_logic_vector (3 DOWNTO 0);
	w_addr 	: in std_logic_vector (3 DOWNTO 0);
	input	: in std_logic_vector (7 DOWNTO 0);
	output	: out std_logic_vector (7 DOWNTO 0)
);
end RjMem;

architecture RTL of RjMem is
	type memtype is array (0 to 15) of std_logic_vector (7 DOWNTO 0);
	signal mem :memtype;

	begin
		memory:process(clk,clr)
			begin
				--clear
				if(clr='1')then
					for j in 0 to 15 loop
						mem(j)<="00000000";
					end loop;

				--write
				elsif rising_edge(clk) then
					if(write ='1') then
					 mem(conv_integer(w_addr))<=input;
					end if;
				end if;
			end process;
	--read 
	output <=mem(conv_integer(r_addr));
end RTL;