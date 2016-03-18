library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity ALU_controller is port
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
end ALU_controller;

architecture RTL of ALU_controller is
	type state_type is (s0,s1,s2,s3,s4);
	signal state							: state_type;
	signal rj_count 					:std_logic_vector (3 DOWNTO 0);
	signal coef_count,coef_lim	:std_logic_vector (7 DOWNTO 0);
	signal coef_addr_out				:std_logic_vector (8 DOWNTO 0);
	signal dataout_count				:std_logic_vector (1 DOWNTO 0);
	
begin

	
fsm: process (sclk,clr)
	begin
		if (clr='1') then
			rj_count<="0000";
			coef_count<="00000000";
			coef_addr_out<="000000000";
			coef_lim<="00000000";
			dataout_count<=B"10";
			clr_alu<='1';
			load_alu<='0';
			shift_alu<='0';
			load_dataout<='0';
			dataout_ready<='0';
			state<=s0;
		elsif rising_edge(sclk) then
			if(sleep='1') then
				rj_count<="0000";
				coef_count<="00000000";
				coef_addr_out<="000000000";
				coef_lim<="00000000";
				dataout_count<=B"01";
				clr_alu<='1';
				load_alu<='0';
				shift_alu<='0';
				load_dataout<='0';
				dataout_ready<='0';
				state<=s0;
			elsif (enable_compute='1') then
				case state is
					when s0 =>
						rj_count<="0000";
						coef_count<="00000000";
						coef_addr_out<="000000000";
						coef_lim<="00000000";
						clr_alu<='1';
						load_alu<='0';
						shift_alu<='0';
						load_dataout<='0';
						dataout_ready<='0';
						state<=s1;
					when s1 =>
						rj_count<="0000";
						coef_count<=X"01";
						coef_addr_out<="000000000";
						coef_lim<=rj;
						shift_alu<='0';
						load_dataout<='0';
						if(frame='1') then
							rj_count<="0000";
							load_alu<='1';
							clr_alu<='0';
							state <=s2;
						else 
							rj_count <=rj_count;
							load_alu<='0';
							clr_alu<='1';
							state <=s1;
						end if;
					when s2 =>
						load_alu<='1';
						clr_alu<='0';
						shift_alu<='0';
						load_dataout<='0';
						if(coef_count<coef_lim) then
							rj_count <=rj_count;
							coef_count<=coef_count+1;
							coef_addr_out<=coef_addr_out+1;
							load_alu<='1';
							shift_alu<='0';
							state<=s2;
						else 
							rj_count <=rj_count+1;
							coef_count<=coef_count;
							coef_addr_out<=coef_addr_out;
							load_alu<='0';
							shift_alu<='1';
							state<=s3;
						end if;
					when s3 =>
						rj_count <=rj_count;
						coef_count<=X"01";
						if(coef_lim/=0) then
							coef_addr_out<=coef_addr_out+1;
						end if;
						coef_lim<=rj;
						clr_alu <='0';
						shift_alu<='0';
						load_dataout<='0';
						if(rj_count=X"0") then
							load_alu<='0';
							if(dataout_count=0) then
								dataout_count<=dataout_count;
							else 
								dataout_count<=dataout_count-1;
							end if;
							state<=s4;
						else 
							load_alu <='1';
							dataout_count<=dataout_count;
							state<=s2;
						end if;
					when s4 =>
						rj_count <=rj_count;
						coef_count<=coef_count;
						coef_addr_out<=coef_addr_out;
						coef_lim<=coef_lim;
						clr_alu <='0';
						shift_alu<='0';
						load_alu<='0';
						load_dataout<='1';
						if(dataout_count=0) then
							dataout_ready<='1';
						else 
							dataout_ready<='0';
						end if;
						state <=s1;
					when others =>
						null;
					end case;
				end if;
		end if;
	end process;

	rj_addr<=rj_count;
	coef_addr<=coef_addr_out;
	data_addr<=coef;


end;