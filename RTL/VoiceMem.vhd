library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity VoiceMem is port
(
	clk		: in std_logic;
	clr		: in std_logic;
	write	: in std_logic;
	allzeros: out std_logic;
	addr 	: in std_logic_vector (7 DOWNTO 0);
	input	: in std_logic_vector (15 DOWNTO 0);
	output	: out std_logic_vector (15 DOWNTO 0)
);
end VoiceMem;

architecture RTL of VoiceMem is
	type memtype is array (0 to 255) of std_logic_vector (15 DOWNTO 0);
	signal mem :memtype;
	signal write_addr:	std_logic_vector(8 downto 0);
	signal read_addr:	std_logic_vector(8 downto 0);

	begin
		memory:process(clk,clr)
			begin
				--clear
				if(clr='1')then
					for j in 0 to 255 loop
						mem(j)<=X"0000";
					end loop;
					write_addr<="000000000";
					allzeros<='0';

				--write
				elsif rising_edge(clk) then
					if(write ='1') then
					 mem(conv_integer(write_addr)mod 256)<=input;
					 if input=X"0000" then
					 	allzeros<='1';
					 else
					 	allzeros<='0';
					 end if;
					 write_addr<=write_addr+1;
					end if;
				end if;
			end process;
	--read 
	read_addr<=(write_addr-1 -addr);
	output <=mem(conv_integer(read_addr) mod 256);
end RTL;