library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_textio.all;    -- for hread(), hwrite()
use IEEE.std_logic_unsigned.all;  -- for conv_integer()
use std.textio.all;               -- for file operations

entity testbench is
end testbench;

----------------- Architecture Declarations -------------------
architecture examine of testbench is

-- data clock frequency of 768KHz (1302ns) for 1 bit, 48KHz for 16 bits
constant DclkFreq_KHz : integer := 768;
constant SclkFreq_KHz : integer := 26888;

constant RjNum    : integer := 16;   
constant CoefNum  : integer := 512;        

constant DclkPeriod : time := 1 ms/DclkFreq_KHz;
constant SclkPeriod : time := 1 ms/SclkFreq_KHz;


constant Time16bit   : time := DclkPeriod*16;   -- 20832 ns
constant WaitInReady : time := DclkPeriod*3;    -- 3906 ns

constant TransBegin :time:=DclkPeriod+WaitInReady;                              -- 5208 ns
constant StartBegin :time:=100 ns;                                              -- 100 ns
constant StartEnd   :time:=StartBegin+DclkPeriod;                               -- 1402 ns
constant StartBegin1 :time:=2500 ns;                                            -- during wait_rj
--constant StartBegin1 :time:=7000 ns;                                            -- during receive_rj
--constant StartBegin1 :time:=338530 ns;                                            -- during wait_coef
--constant StartBegin1 :time:=11000000 ns;                                            -- during receive_coef
--constant StartBegin1 :time:=11004550 ns;                                            -- during wait_data
--constant StartBegin1 :time:=12000000 ns;                                            -- during working
--constant StartBegin1 :time:=86500000 ns;                                            -- during sleeping
--constant StartBegin1 :time:=TransBegin+Time16bit*(RjNum+CoefNum+4200)+10125 ns; -- during reset
constant StartEnd1   :time:=StartBegin1+DclkPeriod;       
constant ResetBegin1:time:=TransBegin+Time16bit*(RjNum+CoefNum+4200)+10125 ns;  -- 98.279877 ms
constant ResetEnd1  :time:=ResetBegin1+DclkPeriod;                              -- 98.281179 ms
constant ResetBegin2:time:=ResetEnd1+WaitInReady+Time16bit*1799+6060 ns;        -- 135.767913 ms
constant ResetEnd2  :time:=ResetBegin2+DclkPeriod;                              -- 135.769215 ms

file inputfile     : text open read_mode  is "data1.in";
file outputfile    : text open write_mode is "data1.out";
file inputfile_ex  : text open read_mode  is "data_expected1.out";

-- Declare the entity under test.

component MSDAP_RTL
    port(
        Sclk     : in  std_logic;
        Dclk     : in  std_logic;
        Start    : in  std_logic;
        Reset_n  : in  std_logic;
        Frame    : in  std_logic;
        InputL   : in  std_logic;
        InputR   : in  std_logic;
        InReady  : out std_logic;
        OutReady : out std_logic;
        OutputL  : out std_logic;
        OutputR  : out std_logic
    );
end component MSDAP_RTL;

component MSDAP_BEH 
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
end component MSDAP_BEH;

signal Sclk     : std_logic := '1';
signal Dclk_tb     : std_logic := '1';
signal Dclk    : std_logic;
signal Start    : std_logic;
signal Reset_n  : std_logic;
signal Frame    : std_logic := '0';
signal InputL   : std_logic := '0';
signal InputR   : std_logic := '0';
signal InReady_RTL  : std_logic := '0';
signal InReady_BEH  : std_logic := '0';
signal OutReady_RTL : std_logic := '0';
signal OutputL_RTL  : std_logic := '0';
signal OutputR_RTL  : std_logic := '0';
signal OutReady_BEH : std_logic := '0';
signal OutputL_BEH  : std_logic := '0';
signal OutputR_BEH  : std_logic := '0';
signal receive_RTL,receive_BEH:std_logic:='0';

signal countRj     : integer range 0 to 16; 
signal countcoeff  : integer range 0 to 512;
signal countInput  : integer range 0 to 7000;
signal countOutput : integer range 0 to 6400;
signal countWrong  : integer range 0 to 6400;
signal correct_out : std_logic := '0';
signal OutputL_test    : std_logic_vector(39 downto 0):=X"0000000000";
signal OutI_test    : integer;

signal compare : std_logic := '0';
signal regL_RTL,regR_RTL    : std_logic_vector(39 downto 0):=X"0000000000";
signal regL_BEH,regR_BEH    : std_logic_vector(39 downto 0):=X"0000000000";

begin    
   -- Apply to entity under test.
   UUT_RTL: MSDAP_RTL
        port map(
                  Sclk     => Sclk,
                  Dclk     => Dclk,
                  Start    => Start,
                  Reset_n  => Reset_n,
                  Frame    => Frame,
                  InputL   => InputL,
                  InputR   => InputR,
                  InReady  => InReady_RTL,
                  OutReady => OutReady_RTL,
                  OutputL  => OutputL_RTL,
                  OutputR  => OutputR_RTL
                 );
	   UUT_BEH: MSDAP_BEH
			port map(
					  Sclk     => Sclk,
					  Dclk     => Dclk,
					  Start    => Start,
					  Reset_n  => Reset_n,
					  Frame    => Frame,
					  InputL   => InputL,
					  InputR   => InputR,
					  InReady  => InReady_BEH,
					  OutReady => OutReady_BEH,
					  OutputL  => OutputL_BEH,
					  OutputR  => OutputR_BEH
					 );
      
    Sclk <= not Sclk after SclkPeriod/2;
    Dclk_tb <= not Dclk_tb after DclkPeriod/2;
                
    -- If InReady='0', no Dclk, Frame and any input sample until InReady='1'.
    Dclk <= Dclk_tb when InReady_RTL = '1' else '0';


    Start   <= '0', '1' after StartBegin,  '0' after StartEnd;   
    --Start   <= '0', '1' after StartBegin,  '0' after StartEnd,   
								--'1' after StartBegin1,  '0' after StartEnd1;  
    Reset_n <= '1', '0' after ResetBegin1, '1' after ResetEnd1,
                       '0' after ResetBegin2, '1' after ResetEnd2;

    -- 1. Read each serial output word transmitting from the MSDAP_RTL chip bit by bit
    --    and store in a parallel vector. Then write this vector to an output file.
    -- 2. Wait a little delay of data clock to catch output data.
    read_RTL : process (Start,Sclk)
        -- line is an access type predefined in the textio package.
        variable BufLineOut    : line;
        variable BufLineOut_ex : line;      
        
        variable OutputL_rtl_var    : std_logic_vector(39 downto 0);
        variable OutputR_rtl_var    : std_logic_vector(39 downto 0);  	

        variable countBit    : integer range 0 to 40;
        
        --variable countWrong  : integer range 0 to 2692;    
    begin    
        if rising_edge(Sclk) then
            if OutReady_RTL = '0' then
                countBit := 40;
                OutputL_rtl_var    := (others=>'0');
                OutputR_rtl_var    := (others=>'0');               
            elsif OutReady_RTL ='1' then
               --  1. OutReady='1' begins with the first bit of output.
               --  2. Frame aligns with the first bit of both each input and each output word.
               --     So Frame signal should be high at this moment, otherwise Error.
                if ((countBit = 39) and (Frame = '0')) then
                    report "Frame and OutReady signals are not aligned!"
                    severity ERROR;
                end if;
							if countBit<40 then
								OutputL_rtl_var(39-countBit) := OutputL_RTL;
								OutputR_rtl_var(39-countBit) := OutputR_RTL;
							end if;
                end if;
							
							if countBit=5 then
								receive_RTL<='0';
							end if;
							
							if countBit=0 then
							  countBit := 40;
								receive_RTL<='1';
								regL_RTL<=OutputL_rtl_var;
								regR_RTL<=OutputR_rtl_var;
							else
                    countBit := countBit - 1;
                end if;
							
        end if;     
    end process;
	
	read_BEH : process (Start,Sclk)
        -- line is an access type predefined in the textio package.
        variable BufLineOut    : line;  
        
        variable OutputL_beh_var    : std_logic_vector(39 downto 0);
        variable OutputR_beh_var    : std_logic_vector(39 downto 0);  	

        variable countBit    : integer range 0 to 40;
        
        --variable countWrong  : integer range 0 to 2692;
    begin
				if rising_edge(Sclk) then
            if OutReady_BEH = '0' then
                countBit := 40;
                OutputL_beh_var    := (others=>'0');
                OutputR_beh_var    := (others=>'0');               
            elsif OutReady_BEH ='1' then
               --  1. OutReady='1' begins with the first bit of output.
               --  2. Frame aligns with the first bit of both each input and each output word.
               --     So Frame signal should be high at this moment, otherwise Error.
                if ((countBit = 39) and (Frame = '0')) then
                    report "Frame and OutReady signals are not aligned!"
                    severity ERROR;
                end if;

							if countBit<40 then
								OutputL_beh_var(39-countBit) := OutputL_BEH;
								OutputR_beh_var(39-countBit) := OutputR_BEH;
							end if;
 							OutputL_test<=OutputL_beh_var;
							OutI_test<=39-countBit;
                end if; 
							if countBit=5 then
								receive_BEH<='0';
							end if;
							if countBit=0 then
							  countBit := 40;
								receive_BEH<='1';
								regL_BEH<=OutputL_beh_var;
								regR_BEH<=OutputR_beh_var;
							else
                    countBit := countBit - 1;
                end if;
        end if;     
    end process;

combine:process(receive_RTL,receive_BEH)	
	begin
		if rising_edge(receive_RTL) or rising_edge(receive_BEH) then
			if receive_BEH='1' and receive_RTL='1' then
				compare<='1';
			else
				compare<='0';
			end if;
		end if;
	end process;
	
WriteOutput : process (Start,compare)
        -- line is an access type predefined in the textio package.
        variable BufLineOut    : line;
			 variable BufLineOut_ex : line;
        variable countBit    : integer range 0 to 39;
		   variable OutL_ex : std_logic_vector(39 downto 0);
        variable OutR_ex : std_logic_vector(39 downto 0);        
        
        --variable countWrong  : integer range 0 to 2692;
    begin
        if rising_edge(Start) then        
            countOutput <= 1;
            countWrong  <= 0;
            correct_out <= '0';
            
					write(BufLineOut, string'("                                       MSDAP Automatic Verification"));
					writeline(outputfile, BufLineOut);
					write(BufLineOut, string'("         |                  OutputL                 |                 OutputR                  |"));
					writeline(outputfile, BufLineOut); 
					write(BufLineOut, string'(" Number  |    Expected    Behavioural      RTL      |    Expected    Behavioural    RTL        | Result"));
					writeline(outputfile, BufLineOut);   
					file_close(inputfile_ex);
					file_open(inputfile_ex,"data_expected1.out",READ_MODE);			
              
        elsif rising_edge(compare) then
            if receive_BEH ='1' and receive_RTL ='1'then
						countOutput <= countOutput + 1;
						
						readline(inputfile_ex, BufLineOut_ex);  -- read line from file                 

						hread(BufLineOut_ex, OutL_ex);
						hread(BufLineOut_ex, OutR_ex);
						
						--print number
						write(BufLineOut, string'("   "));
						write(BufLineOut, countOutput);
						write(BufLineOut, HT);
						if countOutput<100 then write(BufLineOut, HT);end if;
						write(BufLineOut, string'("|   "));
						
						--print left channel
						hwrite(BufLineOut, OutL_ex);
						write(BufLineOut, string'("   "));
						hwrite(BufLineOut, regL_BEH);
						write(BufLineOut, string'("   "));
						hwrite(BufLineOut, regL_RTL);
						
						--print right channel
						write(BufLineOut, string'("   |   "));
						hwrite(BufLineOut, OutR_ex);
						write(BufLineOut, string'("   "));
						hwrite(BufLineOut, regR_BEH);	
						write(BufLineOut, string'("   "));					
						hwrite(BufLineOut, regR_RTL);
		  
						write(BufLineOut, string'("   |   "));             
						

						
						 if ((regL_RTL /= OutL_ex) or (regL_BEH /= OutL_ex) 
									or (regR_RTL /= OutR_ex) or (regR_BEH /= OutR_ex))then
							 write(BufLineOut, string'("miss"));
							 countWrong <= countWrong + 1;
							 correct_out <= '0';
						 else
							 correct_out <= '1';
							 write(BufLineOut, string'("hit"));
						 end if;
						 
						writeline(outputfile, BufLineOut);                    
            end if;      
        end if;     
    end process;
--print the final result after simulation.
WriteComment:process(countOutput)

variable BufLineOut    : line;

begin        
        if (countOutput>6393) then
            if(countWrong=0) then
              write(BufLineOut, string'("--------------------------------------------------------------------------------"));
              writeline(outputfile, BufLineOut); 
              write(BufLineOut, string'("Congratulations! Your output is 100% correct!"));
              writeline(outputfile, BufLineOut);  
            else
              write(BufLineOut, string'("--------------------------------------------------------------------------------"));
              writeline(outputfile, BufLineOut); 
              write(BufLineOut, string'("Your output: "));
              write(BufLineOut, countWrong);
              write(BufLineOut, string'(" mismatch!"));
              writeline(outputfile, BufLineOut);  
            end if;
        end if;
end process;
 

    -- Read each input word from an input file and feed to
    -- the input pin of the MSDAP_RTL chip in serial manner.
    send : 
        process
        -- line is an access type predefined in the textio package.
        variable BufLineIn : line;

        -- hread() needs them to be variable instead of signal.
        variable InputL_var       : std_logic_vector(15 downto 0);
        variable InputR_var       : std_logic_vector(15 downto 0);
        
        
        variable temp       : std_logic_vector(15 downto 0);
        variable sumRj      : integer range 0 to 65536;
        variable i          : integer range 0 to 16;

             
    begin
		for startX in 0 to 10 loop
			file_close(inputfile);
			file_open(inputfile,"data1.in",READ_MODE);
        InputL_var       := (others=>'0');
        InputR_var       := (others=>'0');
        temp             := (others=>'0');
      
        wait for TransBegin;
        -- After Start and enough time (close to the time of WaitInReady), InReady
        -- should be high on the rising_edge(Dclk), otherwise Error.
        if InReady_RTL = '0' then
            report "InReady signal is missing!"
            severity ERROR;
            wait;  -- "wait" stops running code but ModelSim keeps going.
        end if;
         
        while not endfile(inputfile) loop
					exit when Start='1';
            readline(inputfile, BufLineIn);  -- read line from file                 
            if BufLineIn(1) = '/' then
                next;  -- skip this comment line in file            
            end if;
            
         
            Frame <= '1';
            hread(BufLineIn, InputL_var);
            hread(BufLineIn, InputR_var);

                       
                                        
         -- Finish loading all coefficients. Then begin to count input.
          if  (countRj = 16) then
                sumRj       :=  conv_integer(temp);
             if  (countcoeff < sumRj) then
                   countcoeff  <=  countcoeff + 1;
             else
                   countInput  <=  countInput + 1;
             end if;
          else                
                  temp        :=  temp + InputL_var;
                  countRj     <=  countRj + 1;
          end if;
             
             
        i := 16;
          
 
 -- Reading 16 bit data  
         while (i > 0 ) loop
						exit when Start='1';
               i := i - 1;          
                -- It's better to catch NOW during a period of time instead of a moment only.
                if (((NOW >= ResetBegin1) and (NOW <= ResetEnd1)) or
                    ((NOW >= ResetBegin2) and (NOW <= ResetEnd2))) then

                    i := 0;
                    Frame <= '0';

                    wait for (DclkPeriod + WaitInReady); 
                    -- After reset and enough time, InReady should be high at this moment,
                    -- otherwise Error.
                    if InReady_RTL = '0' then
                       report "InReady signal is missing!"
                       severity ERROR;
                       wait;  -- "wait" stops running code but ModelSim keeps going.
                    end if;                                       
                 else
                    InputL <= InputL_var(15-i);
                    InputR <= InputR_var(15-i);
                    wait for DclkPeriod;
                    Frame <= '0';
                end if;
          end loop;
              
        end loop;                

        report "Simulation is done!"
        severity NOTE;
      
        wait for DclkPeriod*5;  -- Flush out pipe line in hardware model.
		end loop;
    wait;  -- Stop simulation.
    end process;
    
    
 end examine;