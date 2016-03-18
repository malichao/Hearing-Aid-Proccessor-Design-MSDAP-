-------------------------------------------------
--
--Entity         : MSDAP_BEH
--
--Architecture   : Behavioral
--
--Testbench file : testbench.vhd
--
--Author         : Zhenyan Nan & Lichao Ma 
--
--Title          : ASIC Mid-term Project 
--
--Date           : 10/17/15
--
-------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity MSDAP_BEH is
	port(
		sclk				:in std_logic; 
		dclk 				:in std_logic;
		start				:in std_logic;
		reset_n				:in std_logic;
		frame				:in std_logic;
		inputL				:in std_logic;
		inputR				:in std_logic;
		outputL				:out std_logic:='0';
		outputR				:out std_logic:='0';
		inready				:out std_logic;
		outready 			:out std_logic
		);
end MSDAP_BEH;

architecture Behavioral of MSDAP_BEH is 
	type state_type is 
	(initilize,wait_rj,receive_rj,wait_coeff,receive_coeff,wait_data,working,clearing,sleeping);
	signal current_state,next_state : state_type;
	signal nosignal			: std_logic:='0';
	signal is_zeroL,is_zeroR: std_logic:='0';
	signal zero_counter     : integer;
	signal rj_receive_done	: std_logic:='0';
	signal coef_receive_done	: std_logic :='0';
	signal dataout_ready	: std_logic:='0';
	signal inputcount		: integer :=0;
	signal tempL,tempR		:std_logic_vector(15 DOWNTO 0)   :=X"1111";
	signal tempL_tp,tempR_tp:std_logic_vector(15 DOWNTO 0):=X"0000";
	
	
	type rj_array_type is array (0 to 15) of std_logic_vector (15 DOWNTO 0);
	signal rjL_array,rjR_array 		: rj_array_type; 
	type coef_array_type is array (0 to 511) of std_logic_vector (15 DOWNTO 0);
	signal coefL_array,coefR_array 	: coef_array_type; 
	type voice_array_type is array (0 to 255) of std_logic_vector (39 DOWNTO 0);
	signal voiceL_array,voiceR_array 	: voice_array_type; 
	signal voiceCL_array,voiceCR_array 	: voice_array_type;
	signal i,jL,jR,kL,kR,p			: integer := 0;
	signal buffer_head		: integer := 0;
	signal buffer_circle		: std_logic:='0';
	signal new_voice		: std_logic:='0';
	signal compute_complte	: std_logic:='1';
	signal sleeping_counter : integer := 0;
	signal enable_compute		: std_logic:='0';
	signal enable_send			: std_logic:='0';
	signal send_complete			: std_logic:='1';
	signal keep_reset			: std_logic:='0';
	signal voice_outL :std_logic_vector (39 DOWNTO 0):=X"0000000000";
	signal voice_outR :std_logic_vector (39 DOWNTO 0):=X"0000000000";
	signal voice_tp :std_logic_vector (39 DOWNTO 0):=X"0000000000";
	signal test_point1 : integer := 0;
	signal test_point2 : integer := 0;
	signal test_point3 : integer := 0;
	signal test_point4 : integer := 0;
	signal test_point5 : integer := 0;
	signal output_count : integer := 0;
	signal tp1,tp2,tp3 : std_logic := '0';
	signal clear_buffer :std_logic:='0';
	signal load_rj:std_logic:='0';
	--signal tp_coef :std_logic_vector (15 DOWNTO 0);

	type compute_state_type is (s0,s1,s2,s3,s4,s5,s6,s7);
	signal current_compute_state,next_compute_state: compute_state_type:=s0;
	type send_state_type is (s0,s1,s2,s3);
	signal current_send_state: send_state_type:=s0;
	type uj_array_type is array (0 to 15) of std_logic_vector (39 DOWNTO 0);
	signal ujL,ujR :uj_array_type;

	signal sumL,sumR 	:std_logic_vector (39 DOWNTO 0):=X"0000000000";
	signal rj_countL,rj_nL	:integer:=0;
	signal rj_countR,rj_nR	:integer:=0;
	signal frame_count:integer:=2;

	begin	
	determine_state: process
	(current_state,sclk,dclk,start,reset_n,frame)
		begin
			case current_state is
			when initilize     => 
				inready 		<=	'1';
				outready		<=	'0';
				load_rj<='0';

				next_state		<=	wait_rj;
			if (start='1') then
				next_state <=initilize;
			end if;	
			when wait_rj       =>
				inready			<=	'1';
				outready		<=	'0';
				
				if start = '1' then
					next_state <= initilize;
				elsif frame = '1' then 
					next_state <= receive_rj;
					load_rj<='1';
				else
					next_state <= current_state;
				end if;
			if (start='1') then
				next_state <=initilize;
			end if;	
			when receive_rj	   =>
				inready			<=	'1';
				outready		<=	'0';
				
				if start = '1' then 
					next_state <= initilize;
				elsif rj_receive_done = '1' then 
					next_state <= wait_coeff;
					inready		<=	'1';
				else 
					next_state <= current_state;
					inready			<=	'1';
				end if;
			if (start='1') then
				next_state <=initilize;
			end if;	
			when wait_coeff    => 
				inready			<=	'1';
				outready		<=	'0';
				load_rj<='0';
				
				if start = '1' then
					next_state <= initilize;
				elsif frame = '1' then 
					next_state <= receive_coeff;
				else
					next_state <= current_state;
					inready			<=	'1';
				end if;
			if (start='1') then
				next_state <=initilize;
			end if;	
			when receive_coeff =>
				inready			<=	'1';
				outready		<=	'0';
				
				if start = '1' then 
					next_state <= initilize;
				elsif coef_receive_done = '1' then 
					next_state <= wait_data;
					inready		<=	'1';
				else 
					next_state <= current_state;
					inready			<=	'1';
				end if;
			
       when wait_data     => 
				inready			<=	'1';
				outready		<=	'0';

				
				if start = '1' then
					next_state <= initilize;
				elsif reset_n = '0' then 
					next_state <= clearing;
				elsif frame = '1' then 
					next_state <= working;
				else
					next_state <= current_state;
				end if;	
			if (start='1') then
				next_state <=initilize;
			end if;	
			when working       =>
				inready			<=	'1';
				
				if dataout_ready = '1' then 
					outready <= '1';
				else
					outready <= '0';
				end if; 
				
				if start = '1' then 
					next_state <= initilize;
				--elsif reset_n = '0' then 
					--next_state <= clearing;
				elsif nosignal = '1' then 
					next_state <= sleeping;
				else	
					next_state <= current_state;
				end if;
			if (start='1') then
				next_state <=initilize;
			end if;	
			when clearing      => 
				inready			<=	'0';
				outready		<=	'0';
				
				if start = '1' then 
					next_state <= initilize;
				elsif reset_n = '1' then 
					next_state <= wait_data;
				else	
					next_state <= current_state;
				end if;
			if (start='1') then
				next_state <=initilize;
			end if;	
			when sleeping	   => 
				inready			<=	'1';
				outready		<=	'0';
				
				if start = '1' then 
					next_state <= initilize;
				elsif reset_n = '0' then
					next_state <= working;
				elsif nosignal = '0' then 
					next_state <= working;
				else
					next_state <= current_state;
				end if;
			if (start='1') then
				next_state <=initilize;
			end if;	
			when others	   => next_state <= initilize;
			end case;
		end process;
		
	change_state : process(sclk,start)
		begin 
		if start = '1' then 
			current_state <= initilize;
		elsif rising_edge(sclk) then
			current_state <= next_state;
		end if;
		end process;
		
	nosignal_detect : process (sclk,new_voice,start)	--800 succesive zeros means no signal
		begin 
			if start = '1' then 
				nosignal <= '0';
				zero_counter <= 0;
				test_point5<=1;
			end if;
			

			if rising_edge(new_voice) then 
				if zero_counter >= 800 then
					nosignal <= '1';
					--test_point5<=3;
				elsif is_zeroL ='1' and is_zeroR ='1' then
					zero_counter <=zero_counter +1;
					--test_point5<=4;
				else 
					zero_counter <=0;
					nosignal <= '0';
					--test_point5<=5;
				end if;
			end if;

			if rising_edge(sclk) then	
				if nosignal ='1' then
					if inputL ='1' or inputR ='1' then
						nosignal <='0';
						zero_counter <= 0;
						--test_point5<=2;
					end if;
				end if;
			end if;
		end process;	

	compute_enable_control: process(dclk,nosignal)
		begin
		if current_state =working then
			enable_compute <='1';
		end if;
		if rising_edge(dclk) then
			if nosignal ='1' and enable_compute ='1' then
				sleeping_counter <=sleeping_counter +1;
			end if;
			if sleeping_counter >=16 then
				sleeping_counter <=0;
				enable_compute <= '0';
			end if;
			if nosignal ='0' and current_state =sleeping then
				enable_compute <='1';
			end if;
		end if;
		end process;


	
	recieve_data: process (dclk,start,reset_n,frame)
		variable temp	:std_logic_vector(15 DOWNTO 0):="0000000000000000";
		begin
		case current_state is
			when wait_rj		=>
				if rising_edge(frame) then
					if inputcount <= 15 then					--recieving data
						tempL <=inputL & tempL(15 downto 1);	--data in right shift manner
						tempR <=inputR & tempR(15 downto 1) ;
						inputcount<=0;
					end if;
					i <=0;
				end if;
			when receive_rj		=>
				if rising_edge(dclk) then
					if inputcount <= 15 then					--recieving data
						tempL <=inputL & tempL(15 downto 1);	--data in right shift manner
						tempR <=inputR & tempR(15 downto 1) ;
						inputcount <= inputcount+1;
					end if;
					if inputcount = 15 then
						rjL_array(i) <=tempL;
						rjR_array(i) <=tempR;
						i <=i+1;
						inputcount <= 0;
						if i = 15 then
							rj_receive_done <='1';
							i <=0;
							inputcount <=0;
						end if;
					end if;
				end if;
			when wait_coeff		=>
				if rising_edge(frame) then
					if inputcount <= 15 then					--recieving data
						tempL <=inputL & tempL(15 downto 1);	--data in right shift manner
						tempR <=inputR & tempR(15 downto 1) ;
						inputcount<=0;
					end if;
					i <=0;
				end if;
			when receive_coeff	=>
				if rising_edge(dclk) then
					if inputcount <= 15 then					--recieving data
						tempL <=inputL & tempL(15 downto 1) ;	--data in right shift manner
						tempR <=inputR & tempR(15 downto 1) ;
						inputcount <= inputcount+1;
					end if;
					if inputcount = 15 then
						coefL_array(i) <=tempL;
						coefR_array(i) <=tempR;
						i <=i+1;
						inputcount <=0;
						if i = 511 then
							coef_receive_done <='1';
							i <=0;
							inputcount <=0;
						end if;
					end if;
				end if;
			when working 		=>
				if rising_edge(dclk) then
					if inputcount <= 15 then					--recieving data
						tempL <=inputL & tempL(15 downto 1) ;	--data in right shift manner
						tempR <=inputR & tempR(15 downto 1) ;
						inputcount <= inputcount+1;
						new_voice <='0';
						if reset_n='0' then
							tempL <=X"0000";
							tempR <=X"0000";
						end if;
					end if;
					if inputcount = 15 then  --start to extend the data
							if tempL =X"0000" then is_zeroL <='1';
							else is_zeroL<='0';
							end if;
							if tempR =X"0000" then is_zeroR <='1';
							else is_zeroR <='0';
							end if;
							

							if tempL(15) = '1' then  --negative
								temp := (not (tempL-1)) and X"7FFF";
								VoiceL_array(buffer_head) <=X"FF" & tempL & X"0000";
								VoiceCL_array(buffer_head) <=X"00" & temp & X"0000";
							else 
								temp := (not tempL)+1;
								VoiceL_array(buffer_head) <=X"00" & tempL & X"0000";
								VoiceCL_array(buffer_head) <=X"FF" & temp & X"0000";
								if tempL = X"0000" then
									VoiceCL_array(buffer_head) <=X"00" & temp & X"0000";
								end if;
							end if;
							if tempR(15) = '1' then
								temp := (not (tempR-1)) and X"7FFF";
								VoiceR_array(buffer_head) <=X"FF" & tempR & X"0000";
								VoiceCR_array(buffer_head) <=X"00" & temp & X"0000";
							else 
								temp := (not tempR)+1;
								VoiceR_array(buffer_head) <=X"00" & tempR & X"0000";
								VoiceCR_array(buffer_head) <=X"FF" & temp & X"0000";
								if tempR = X"0000" then
									VoiceCR_array(buffer_head) <=X"00" & temp & X"0000";
								end if;
							end if;
							
							new_voice <='1';
							buffer_head <=buffer_head+1;
							inputcount <=0;
							if buffer_head = 255 then
								buffer_head <=0;	--circle buffer
								buffer_circle<='1';	
							end if;

							tempL_tp<=tempL;
							tempR_tp<=tempR;

						end if;
						if keep_reset='1' then
							if frame='1' then
								keep_reset<='0';
							else
								keep_reset<='1';
							end if;
							inputcount<=0;
						end if;
						if frame='1' then
							frame_count<=frame_count+1;
						end if;
				end if;
			when sleeping		=>
				if rising_edge(dclk) then
					new_voice <='0';
					if inputcount <= 15 then					--recieving data
						tempL <=inputL & tempL(15 downto 1) ;	--data in right shift manner
						tempR <=inputR & tempR(15 downto 1) ;
						inputcount <= inputcount+1;
					end if;
					if inputcount = 15 then  --start to extend the data
						new_voice <='1';
						if tempL =X"0000" then is_zeroL <='1';
						else is_zeroL<='0';
						end if;
						if tempR =X"0000" then is_zeroR <='1';
						else is_zeroR <='0';
						end if;
						inputcount <=0;
					end if;
					if frame='1' then
						inputcount<=0;
					end if;
				end if;
			when others	   		=> 
		end case;
				test_point4<=1;
		if reset_n='0' then
			buffer_head <=0;	--circle buffer
			if start='0' then
				keep_reset<='1';
				frame_count<=0;
			else
				frame_count<=0;
				keep_reset<=keep_reset;
			end if;
			tempL <=X"0000";
			tempR <=X"0000";
			VoiceL_array(0) <=X"0000000000";
			VoiceCL_array(0) <=X"0000000000";
			VoiceR_array(0) <=X"0000000000";
			VoiceCR_array(0) <=X"0000000000";
			buffer_circle<='0';	
			test_point4<=2;
		end if;
		if start='1' then
			buffer_head <=0;	--circle buffer
			inputcount<=0;
			frame_count<=1;
			tempL <=X"0000";
			tempR <=X"0000";
			VoiceL_array(0) <=X"0000000000";
			VoiceCL_array(0) <=X"0000000000";
			VoiceR_array(0) <=X"0000000000";
			VoiceCR_array(0) <=X"0000000000";
			buffer_circle<='0';	
			rj_receive_done<='0';
			coef_receive_done<='0';
			test_point4<=3;
		end if;
	end process;

	compute_data: process (sclk)
	variable jj,kk,pp		: integer := 0;
	variable tp_coef :std_logic_vector (15 DOWNTO 0);
	variable sL,sR	:std_logic_vector (39 DOWNTO 0):=X"0000000000";
	variable is_negative : std_logic:='0';
	variable buffer_pointer:integer;
	begin
	if rising_edge(sclk) then
		case current_compute_state is
			when s0 =>
				if new_voice ='1' then
					next_compute_state <= s1;
				else 
					next_compute_state <=s0;
				end if;
				enable_send<='0';
			when s1 =>
				-------------Left-------------
				ujL(0) <= X"0000000000";
				ujL(1) <= X"0000000000";
				ujL(2) <= X"0000000000";
				ujL(3) <= X"0000000000";
				ujL(4) <= X"0000000000";
				ujL(5) <= X"0000000000";
				ujL(6) <= X"0000000000";
				ujL(7) <= X"0000000000";
				ujL(8) <= X"0000000000";
				ujL(9) <= X"0000000000";
				ujL(10) <= X"0000000000";
				ujL(11) <= X"0000000000";
				ujL(12) <= X"0000000000";
				ujL(13) <= X"0000000000";
				ujL(14) <= X"0000000000";
				ujL(15) <= X"0000000000";
				sumL   <= X"0000000000";
				sL 	   := X"0000000000";
				jL <=0;
				jj:=0;
				rj_countL <=conv_integer(rjL_array(0));
				kL <=conv_integer(coefL_array(0) (7 downto 0));
				p <=0;
				pp :=0;

				-------------Right-------------
				ujR(0) <= X"0000000000";
				ujR(1) <= X"0000000000";
				ujR(2) <= X"0000000000";
				ujR(3) <= X"0000000000";
				ujR(4) <= X"0000000000";
				ujR(5) <= X"0000000000";
				ujR(6) <= X"0000000000";
				ujR(7) <= X"0000000000";
				ujR(8) <= X"0000000000";
				ujR(9) <= X"0000000000";
				ujR(10) <= X"0000000000";
				ujR(11) <= X"0000000000";
				ujR(12) <= X"0000000000";
				ujR(13) <= X"0000000000";
				ujR(14) <= X"0000000000";
				ujR(15) <= X"0000000000";
				sumR   <= X"0000000000";
				sR 	   := X"0000000000";
				jR <=0;
				rj_countR <=conv_integer(rjR_array(0));
				

				--if current_state =sleeping then
				if enable_compute ='0' then 
					next_compute_state <= s0;
					voice_outL <= X"0000000000";
					voice_outR <= X"0000000000";
				else 
					next_compute_state <= s2;
				end if;
				if reset_n='0' or start='1' then
					next_compute_state <=s0;
				end if;
			when s2	=>
				if pp <512 then
					-----------------------Left----------------------
					kk :=conv_integer(coefL_array(pp) (7 downto 0));
					kL<=kk;
					tp_coef:=coefL_array(pp) (15 downto 0);
					if buffer_circle ='0' then--buffer not full
						buffer_pointer:=buffer_head-1-kk;
						if buffer_pointer >=0 then
							is_negative :='0';
						else 
							is_negative :='1';
						end if;
					else 		--buffer full,re-calculate pointer
						buffer_pointer:=buffer_head-1-kk;
						if buffer_head =0 then
							buffer_pointer :=255-kk;
						elsif buffer_pointer <0 then
							buffer_pointer:=buffer_head-1-kk+256;
						end if;
						is_negative :='0';
					end if;

					test_point3 <=buffer_pointer;
					--if voiceL_array(buffer_pointer) = X"0000000000" then
					  --test_point4 <=0 ;
					--else test_point4 <=1;
					--end if;
					if(tp_coef(8)='1') then --negative coef
						if(is_negative = '0') then
							ujL(jL) <=ujL(jL)+ voiceCL_array(buffer_pointer);
							voice_tp <= voiceCL_array(buffer_pointer);
							tp2<='1';
						else 
							ujL(jL) <=ujL(jL)+ X"0000000000";
		 				end if;
					else 
						if(is_negative = '0') then
							ujL(jL) <=ujL(jL)+ voiceL_array(buffer_pointer);
							voice_tp <= voiceL_array(buffer_pointer);
							tp2<='0';
						else 
							ujL(jL) <=ujL(jL)+ X"0000000000";
						end if;
					end if;

					if is_negative = '0' then tp1 <='1';
					else tp1 <='0';
					end if;

					p <=p+1;
					--pp :=pp+1;
					if p+2 >rj_countL then
						if jL<15 then
							rj_countL<=rj_countL+conv_integer(rjL_array(jL+1));
						end if;
						jL<=jL+1;
					end if;


					-----------------------Right----------------------
					kk :=conv_integer(coefR_array(pp) (7 downto 0));
					kR<=kk;
					tp_coef:=coefR_array(pp) (15 downto 0);
					if buffer_circle ='0' then--buffer not full
						buffer_pointer:=buffer_head-1-kk;
						if buffer_pointer >=0 then
							is_negative :='0';
						else 
							is_negative :='1';
						end if;
					else 		--buffer full,re-calculate pointer
						buffer_pointer:=buffer_head-1-kk;
						if buffer_head =0 then
							buffer_pointer :=255-kk;
						elsif buffer_pointer <0 then
							buffer_pointer:=buffer_head-1-kk+256;
						end if;
						is_negative :='0';
					end if;

					test_point3 <=buffer_pointer;
					--if voiceL_array(buffer_pointer) = X"0000000000" then
					  --test_point4 <=0 ;
					--else test_point4 <=1;
					--end if;
					if(tp_coef(8)='1') then --negative coef
						if(is_negative = '0') then
							ujR(jR) <=ujR(jR)+ voiceCR_array(buffer_pointer);
							voice_tp <= voiceCR_array(buffer_pointer);
							tp2<='1';
						else 
							ujR(jR) <=ujR(jR)+ X"0000000000";
		 				end if;
					else 
						if(is_negative = '0') then
							ujR(jR) <=ujR(jR)+ voiceR_array(buffer_pointer);
							voice_tp <= voiceR_array(buffer_pointer);
							tp2<='0';
						else 
							ujR(jR) <=ujR(jR)+ X"0000000000";
						end if;
					end if;

					if is_negative = '0' then tp1 <='1';
					else tp1 <='0';
					end if;

					p <=p+1;
					pp :=pp+1;
					if p+2 >rj_countR then
						if jR<15 then
							rj_countR<=rj_countR+conv_integer(rjR_array(jR+1));
						end if;
						jR<=jR+1;
					end if;

				end if;--if pp <512 then


				if pp = 512 then
					next_compute_state <= s3;
					jL<=0;
					jR<=0;
					jj:=0;
				end if;--pp<512
				
			when s3 =>
				if jj<16 then
					sL :=sL +ujL(jj);
					sL :=sL(39) & sL(39 downto 1);
					sR :=sR +ujR(jj);
					sR :=sR(39) & sR(39 downto 1);
					jj :=jj+1;
				end if;
				if jj> 15 then
					if reset_n='1' then
						next_compute_state <= s5;
					else 
						next_compute_state<=s0;
					end if;
				end if;
			when s5 =>
				voice_outL <=sl;
				sumL<=sl;
				voice_outR <=sR;
				sumR<=sR;
				if frame = '0' then  --waiting for tb to receive
					next_compute_state <= s5;
				else 
					next_compute_state <= s0;
					if(frame_count<3) then
						enable_send<='0';
					else
						enable_send<='1';
					end if;
					jj:=0;
					p <=0;
				end if;
			when others	   		=> 
			end case;
		end if;
	end process;
	
	send_process:process(sclk)
	variable jj,kk,pp		: integer := 0;
	variable tp_coef :std_logic_vector (15 DOWNTO 0);
	variable sL,sR	:std_logic_vector (39 DOWNTO 0):=X"0000000000";
	variable is_negative : std_logic:='0';
	variable buffer_pointer:integer;
	begin
	if rising_edge(sclk) then
		case current_send_state is
			when s0 =>
				if enable_send='1'then
					current_send_state<=s1;
					jj:=0;
					pp :=0;
				else
					current_send_state<=s0;
				end if;
			when s1 =>
				if reset_n='0' or start='1' then
					dataout_ready<='0';
				elsif pp<40 then
					dataout_ready <='1';
					outputL<=voice_outL(pp);
					outputR<=voice_outR(pp);
					pp:=pp+1;
					if pp = 40 then
						current_send_state <=s2;
					else 
						current_send_state <=s1;
					end if;
				end if;
			when s2 =>
				dataout_ready <='0';
				outputL<='0';
				outputR<='0';
				output_count<=output_count+1;
				current_send_state <=s0; 
			when others	   		=> 
		end case;
		if start='1' then 
			output_count<=0;
		end if;
	end if;
	end process;

	compute_state_change :process(sclk,next_compute_state)
	begin
	if falling_edge(sclk) then
			current_compute_state <= next_compute_state;
		end if;
	end process;

	end Behavioral;
	
				
