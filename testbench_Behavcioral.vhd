LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use IEEE.std_logic_textio.all;    -- for hread(), hwrite()
use IEEE.std_logic_unsigned.all;  -- for conv_integer()
use std.textio.all; 			  -- for file operations
 
ENTITY FSM_TB IS
END FSM_TB;
 
ARCHITECTURE behavior OF FSM_TB IS 

	file inputfile : text open read_mode  is "data1.in";
	file outputfile : text open write_mode  is "data1.out";
 
	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT FSM_MSDAP
		PORT(
			sclk				:in std_logic; 
			dclk 				:in std_logic;
			start				:in std_logic;
			frame				:in std_logic;
			inputL				:in std_logic;
			inputR				:in std_logic;
			reset_n				:in std_logic;
			outputL				:out std_logic;
			outputR				:out std_logic;
			inready				:out std_logic;
			outready 			:out std_logic
			);
	END COMPONENT;
    
	signal sclk : std_logic := '0';
	signal dclk : std_logic := '0';
	signal start : std_logic := '0';
	signal reset_n : std_logic := '1';
	signal frame : std_logic := '0';
	signal frame_receive : std_logic := '0';
	signal frame_send : std_logic := '0';
	signal inready : std_logic;
	signal inputL : std_logic := '0';
	signal inputR : std_logic := '0';
	signal outReady : std_logic ;
	signal outputL : std_logic;
	signal outputR : std_logic;

	signal count_rj : integer := 0;
	signal count_coeffs : integer := 512;
	signal bit_count : integer := 15;
	signal voice_outL : std_logic_vector(39 downto 0):=X"0000000000";
	signal voice_outR : std_logic_vector(39 downto 0):=X"0000000000";
	signal temp_result : std_logic_vector(39 downto 0):=X"0000000000";
	
	signal outbc : integer := 39;
	signal resetCount : integer := 0;
	signal test_point1 : integer := 0;
	signal test_point2 : integer := 0;
	signal test_point3 : integer := 0;
	signal testVector: std_logic_vector(15 downto 0);
	signal i 				: integer := 0;
	signal j 				: integer := 0;
	signal k 				: integer := 0;
	signal output_count_tb : integer := 0;
	type receive_state_type is (s0,s1,s2,s3,s4,s5,s6,s7,s8);
	signal current_receive_state,next_receive_state: receive_state_type:=s0;
	signal in_reset			: std_logic := '0';
	signal send_over			: std_logic := '0';
	signal receive_over			: std_logic := '0';
	signal tpppp			: std_logic := '0';
	signal dclk_count :integer:=0;
	type state_type is 
	(initilize,wait_rj,receive_rj,wait_coeff,receive_coeff,wait_data,working,clearing,sleeping);
	signal currentTB_state,next_state : state_type;

	-- Clock period definitions
	-- constant HALFsclk : time := 17 ns; -- Half period of system clock at 31.250 MHZ
	constant HALFsclk : time := ((1 ms/31250)/2);
	-- constant HALFdclk : time := 651.041667 ns; -- Half period of data clock at 768 kHz
	constant HALFdclk : time := ((1 ms/768)/2);
 
	BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
	uut: FSM_MSDAP PORT MAP (
		sclk => sclk,
		dclk => dclk,
		start => start,
		frame => frame,
		inputL => inputL,
		inputR => inputR,
		reset_n => reset_n,
		inready => inready,
		outReady => outReady,
		outputL => outputL,
		outputR => outputR
		);

	-- Clock process definitions
	dclk_generate : process
	begin
		dclk <= '1';
		dclk_count<=dclk_count+1;
		wait for HALFdclk;
		dclk <= '0';
		wait for HALFdclk;
		resetCount<= resetCount+1;
	end process;

	sclk_generate :process
	begin
		sclk <= '0';
		wait for HALFsclk;
		sclk <= '1';
		wait for HALFsclk;
	end process;
	
	start_generate: process
	begin
		start <= '1';
		wait for HALFsclk*2;
		start <= '0';
		wait for HALFsclk*2;
		wait;
	end process;
		
	reset_detect:process
	begin
		for i in 0 to 1000 loop
		wait until reset_n='0';
		if voice_outL=X"0000000000" and voice_outR=X"0000000000" then
			wait for HALFDCLK*2*16;
			in_reset<='1';
			wait for HALFDCLK*2*16;
			in_reset<='0';
			wait for HALFDCLK*2;
		else 
			wait for HALFDCLK*2*16;
			in_reset<='1';
			wait for HALFDCLK*2*30;
			in_reset<='0';
			wait for HALFDCLK*2;
		end if;
		end loop ; 
	end process;

	send_data:process
	variable tempL : std_logic_vector(15 downto 0);
	variable tempR : std_logic_vector(15 downto 0);
	variable outline,outline_next : line;
	variable inline: line;
	begin
		wait until (rising_edge(inready));--fisrt inready,going to state2
		currentTB_state <=receive_rj;
		frame_send <= '0';
		----------------sending rj data-----------------
		frame_send <= '1';
		while (i < 15) loop
			readline(inputfile,outline);
			if outline(1) = '/' then
				next;              
			end if;
			hread(outline,tempL);
			hread(outline,tempR);
			testVector	<=tempL;
			for j in 0 to 15 loop
				InputL <= tempL(j);
				InputR <= tempR(j);
				wait for HALFDCLK*2;
			end loop;
			test_point2 <= test_point2+1;
			i <=i+1;
			frame_send <= '0';
		end loop;
		frame_send <= '0';
		wait for HALFDCLK*2;

	---------------- wait for finish -----------------
		wait for HALFDCLK*2;
		currentTB_state <=receive_coeff;
		frame_send <= '1';
	----------------sending coef data-----------------
		i<=0;
		test_point2 <= 0;
		while (i < 511) loop
			readline(inputfile,outline);
			if outline(1) = '/' then
				next;             
			end if;
			hread(outline,tempL);
			hread(outline,tempR);
			testVector	<=tempL;
			for j in 0 to 15 loop
				InputL <= tempL(j);
				InputR <= tempR(j);
				wait for HALFDCLK*2;
			end loop;
			i <= i+1;
			test_point2 <= test_point2+1;
			frame_send <= '0';
		end loop;
	---------------- wait data mode -----------------
		frame_send <= '0';
		currentTB_state <=wait_data;
		wait for HALFdclk*10;--go to working mode
		frame_send <= '1';
		i<=0;
		test_point2 <= 0;

		currentTB_state <=working;


	---------------- working mode -----------------
		readline(inputfile,outline_next);
		
		while not endfile(inputfile) loop
			outline:=outline_next;
			if outline(1) = '/' then 
				readline(inputfile,outline_next);
				if outline_next(4 to 6)="end" then
					tpppp<='1';
					send_over<='1';   
					wait;         
				end if;
				next;              
			end if;

			frame_send<= '1';
			if (outline'length) > 37 then
				if outline(34 to 38)="reset" then
					reset_n<='0';
					frame_send<= '0';
				end if;
			else 
				reset_n<='1';
			end if;

			hread(outline,tempL);
			hread(outline,tempR);	
			testVector	<=tempL;	
			for j in 0 to 15 loop
				
				InputL <= tempL(j);
				InputR <= tempR(j);
				wait for HALFDCLK*2;
				frame_send<= '0';
			end loop;
			i <= i+1;
			test_point2 <= test_point2+1;

			readline(inputfile,outline_next);
			if outline_next(4 to 6)="end" then
				send_over<='1'; 
				tpppp<='1';
				wait;            
			end if;
			frame_send<= '0';

		end loop;
		send_over<='1';
		wait;
	end process;


	send_over_process:process
	begin
		wait until send_over='1';
		wait for HALFDCLK*2*32;
		receive_over<='1';
	end process;
	receive_data:process(sclk,outready)
	variable jj :integer;
	variable out_line : line;
	variable temp_outL : std_logic_vector(39 downto 0):=X"0000000000";
	variable temp_outR : std_logic_vector(39 downto 0):=X"0000000000";
	begin
		if falling_edge(sclk) then
			case current_receive_state is
			when s0 =>
				if send_over ='1' then
					next_receive_state<=current_receive_state;
				elsif(in_reset ='1') then
					next_receive_state<=current_receive_state;
				elsif(outready='1') then
					next_receive_state<=s1;
				else 
					next_receive_state<=current_receive_state;
				end if;
			when s1 =>
				frame_receive <='1';
				jj:=0;
				temp_outL:= X"0000000000";
				temp_outR:= X"0000000000";
				next_receive_state<=s2;
			when s2 =>
				temp_outL:=outputL & temp_outL(39 downto 1);
				temp_outR:=outputR & temp_outR(39 downto 1);
				jj := jj+1;
				if jj =40 then
					temp_result<=temp_outL XOR temp_outL;
					if(temp_result/=X"0000000000") then
						write(out_line, string'("result incorrect!"));
					end if;
					frame_receive <='0';
					next_receive_state <=s0;
					write(out_line, string'("   "));
					hwrite(out_line, temp_outL);
					write(out_line,string'("      "));
					hwrite(out_line, temp_outR);
					if output_count_tb <6393 then
						writeline(outputfile, out_line);
					end if;
					voice_outL<=temp_outL;
					voice_outR<=temp_outR;
					output_count_tb<=output_count_tb+1;
				end if;
			when others =>

			end case;
		end if;
	end process;

	receive_change_state : process(sclk)
		begin 
		if falling_edge(sclk) then
			current_receive_state <= next_receive_state;
		end if;
		end process;

	frame_process: process(sclk,frame_send,frame_receive)
	begin
		if frame_send ='1' or frame_receive ='1' then
			frame<='1';
		else 
			frame <='0';
		end if;
	end process;
END;