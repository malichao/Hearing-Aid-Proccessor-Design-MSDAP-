library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
 
entity main_controller is port
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
end main_controller;

architecture behaviour of main_controller is

type current_state_type is (initilize,wait_rj,receive_rj,wait_coeff,receive_coeff,wait_data,working,clearing,sleeping);
signal current_state :current_state_type;
signal nosignal,allzeros,reset_detect,en_detect:std_logic;
signal reset_receive_counter,en_receive_counter,count_done:std_logic;
signal dataout_ready:std_logic;
signal zero_counter				:std_logic_vector (9 DOWNTO 0);
signal receive_counter,receive_limit 	:std_logic_vector (8 DOWNTO 0);
signal rj_addr 				:std_logic_vector (3 DOWNTO 0);
signal coef_addr 			:std_logic_vector (8 DOWNTO 0);

begin

	main_fsm:process(sclk,start)
	begin
		if (start='1') then
			current_state <=initilize;
		elsif falling_edge(sclk) then 
			case current_state is
			when initilize =>
				inready			<='0';
				outready		<='0';
				load_rj			<='0';
				load_data		<='0';
				load_coef		<='0';
				enable_compute  <='0';
				clr_transmit			<='1';
				clr_receive			<='1';
				clr_rj			<='1';
				clr_coef		<='1';
				clr_voice		<='1';
				clr_fir			<='1';
				sleep		<='0';
				reset_detect  <='1';
				en_detect		<='0';
				receive_limit	<="000000000";
				reset_receive_counter	<='1';
				en_receive_counter		<='0';
				rj_addr		<="0000";
				coef_addr	<="000000000";
				current_state 			<=wait_rj;
			when wait_rj =>
				inready			<='1';
				outready		<='0';
				load_rj			<='0';
				load_data		<='0';
				load_coef		<='0';
				enable_compute  <='0';
				clr_transmit			<='1';
				clr_receive			<='0';
				clr_rj			<='0';
				clr_coef		<='0';
				clr_voice		<='0';
				clr_fir			<='1';
				sleep		<='0';
				reset_detect  <='1';
				en_detect		<='0';
				receive_limit	<='0'&X"0F";
				reset_receive_counter	<='1';
				en_receive_counter		<='0';
				rj_addr		<="0000";
				coef_addr	<=coef_addr;
				if frame ='1' then
					current_state 			<=receive_rj;
				else 	
					current_state 			<=wait_rj;
				end if;
			when receive_rj =>
				inready			<='1';
				outready		<='0';
				load_rj			<='1';
				load_data		<='0';
				load_coef		<='0';
				enable_compute 	<='0';
				clr_transmit		<='1';
				clr_receive			<='0';
				clr_rj			<='0';
				clr_coef		<='0';
				clr_voice	<='0';
				clr_fir		<='1';
				sleep			<='0';
				reset_detect  <='1';
				en_detect		<='0';
				receive_limit	<=receive_limit;
				reset_receive_counter	<='0';
				en_receive_counter		<='1';
				rj_addr		<=receive_counter(3 downto 0);
				coef_addr	<=coef_addr;
				if count_done ='1' then
					reset_receive_counter <='1';
					en_receive_counter		<='0';
					current_state 			<=wait_coeff;
				else 	
					current_state 			<=receive_rj;
				end if;
			when wait_coeff =>
				inready			<='1';
				outready		<='0';
				load_rj			<='0';
				load_data		<='0';
				load_coef		<='0';
				enable_compute  <='0';
				clr_transmit			<='1';
				clr_receive			<='0';
				clr_rj			<='0';
				clr_coef		<='0';
				clr_voice		<='0';
				clr_fir			<='1';
				sleep		<='0';
				reset_detect  <='1';
				en_detect		<='0';
				receive_limit	<="111111111";
				reset_receive_counter	<='1';
				en_receive_counter		<='0';
				rj_addr		<=rj_addr;
				coef_addr	<="000000000";
				if frame ='1' then
					current_state 			<=receive_coeff;
				else 	
					current_state 			<=wait_coeff;
				end if;

			when receive_coeff =>
				inready			<='1';
				outready		<='0';
				load_rj			<='0';
				load_data		<='0';
				load_coef		<='1';
				enable_compute  <='0';
				clr_transmit			<='1';
				clr_receive			<='0';
				clr_rj			<='0';
				clr_coef		<='0';
				clr_voice		<='0';
				clr_fir			<='1';
				sleep		<='0';
				reset_detect  <='1';
				en_detect		<='0';
				receive_limit	<=receive_limit;
				reset_receive_counter	<='0';
				en_receive_counter		<='1';
				rj_addr		<=rj_addr;
				coef_addr	<=receive_counter;
				if count_done ='1' then
					reset_receive_counter <='1';
					en_receive_counter		<='0';
					current_state 			<=wait_data;
				else 	
					current_state 			<=receive_coeff;
				end if;

			when wait_data =>
				inready			<='1';
				outready		<='0';
				load_rj			<='0';
				load_data		<='0';
				load_coef		<='0';
				enable_compute  <='0';
				clr_transmit			<='1';
				clr_receive			<='0';
				clr_rj			<='0';
				clr_coef		<='0';
				clr_voice		<='0';
				clr_fir			<='1';
				sleep		<='0';
				reset_detect  <='1';
				en_detect		<='0';
				receive_limit	<="000000000";
				reset_receive_counter	<='1';
				en_receive_counter		<='0';
				rj_addr		<=rj_addr;
				coef_addr	<=coef_addr;
				if reset_n ='0' then
					current_state 	<=clearing;
				elsif frame ='1' then
					current_state 	<=working;
				else 	
					current_state 	<=wait_data;
				end if;

			when working =>
				inready			<='1';
				outready		<='0';
				load_rj			<='0';
				load_data		<='1';
				load_coef		<='0';
				enable_compute  <='1';
				clr_transmit  <='0';
				clr_receive			<='0';
				clr_rj			<='0';
				clr_coef		<='0';
				clr_voice		<='0';
				clr_fir			<='0';
				sleep		<='0';
				reset_detect  <='0';
				en_detect		<='1';
				receive_limit	<="000000000";
				reset_receive_counter	<='1';
				en_receive_counter		<='0';
				rj_addr		<=rj_addr;
				coef_addr	<=coef_addr;
				if dataout_ready ='1' then
					outready <='1';
				elsif frame ='1' then
					outready<='0';
				end if;
				if reset_n ='0' then
					current_state <=clearing;
				elsif (nosignal='1' and allzeros='1') then
					inready <='0';
					current_state <=sleeping;
				else 	
					current_state <=working;
				end if;
			when clearing =>
				inready			<='0';
				outready		<='0';
				load_rj			<='0';
				load_data		<='0';
				load_coef		<='0';
				enable_compute  <='0';
				clr_transmit			<='1';
				clr_receive			<='1';
				clr_rj			<='0';
				clr_coef		<='0';
				clr_voice		<='1';
				clr_fir			<='1';
				sleep		<='0';
				reset_detect  <='1';
				en_detect		<='0';
				receive_limit	<="000000000";
				reset_receive_counter	<='1';
				en_receive_counter		<='0';
				rj_addr		<=rj_addr;
				coef_addr	<=coef_addr;
				if reset_n ='1' then
					current_state 			<=wait_data;
				else 	
					current_state 			<=clearing;
				end if;
			when sleeping =>
				inready			<='1';
				outready		<='0';
				load_rj			<='0';
				load_data		<='1';
				load_coef		<='0';
				enable_compute  <='0';
				clr_transmit			<='1';
				clr_receive			<='0';
				clr_rj			<='0';
				clr_coef		<='0';
				clr_voice		<='0';
				clr_fir			<='0';
				sleep		<='1';
				reset_detect  <='1';
				en_detect		<='0';
				receive_limit	<="000000000";
				reset_receive_counter	<='1';
				en_receive_counter		<='0';
				rj_addr		<=rj_addr;
				coef_addr	<=coef_addr;
				if reset_n ='0' then
					current_state 		<=clearing;
				elsif allzeros ='0' then
					current_state 		<=working;
				else 	
					current_state 		<=sleeping;
				end if;
			end case;
		end if;
	end process;

	nosignal_detect:process(dclk,reset_detect)
	begin
		if reset_detect='1' then
			nosignal<='0';
			zero_counter<="0000000000";
		elsif  rising_edge(dclk) then
			if frame ='1' and en_detect='1' then
				if allzeros ='1' then
					if zero_counter="1100011111" then
						nosignal<='1';
						zero_counter<=zero_counter;
					else 
						nosignal<='0';
						zero_counter<=zero_counter+1;
					end if;
				else 	
					nosignal<='0';
					zero_counter<="0000000000";
				end if;
			end if;
		end if; 
	end process;

	count_fsm:process(dclk,reset_receive_counter)
	begin
		if reset_receive_counter='1' then
			count_done<='0';
			receive_counter<="000000000";
		elsif rising_edge(dclk) then
			if en_receive_counter='1' and frame='1' then
				if receive_counter = receive_limit then
					count_done<='1';
					receive_counter<=receive_counter;
				else 	
					count_done<='0';
					receive_counter<=receive_counter+'1';
				end if;
			end if;
		end if;
	end process;

	allzeros<=allzeroL and allzeroR;
	dataout_ready<=outready_L and outready_R;
	rj_w_addr<=rj_addr;
	coef_w_addr<=coef_addr;
end behaviour;