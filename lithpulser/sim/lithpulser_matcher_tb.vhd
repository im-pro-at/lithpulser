------------------------------------------------------------------------------------
-- Company: im-pro.at
-- Engineer: Patrick Knöbel
--
--   GNU GENERAL PUBLIC LICENSE Version 3
--
------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.lithpulser_package.ALL;

entity lithpulser_matcher_tb is
--  empty => TB
end lithpulser_matcher_tb;


architecture Behavioral of lithpulser_matcher_tb is
    signal clk : STD_LOGIC :='0';
    signal clear_all : STD_LOGIC :='1';
    signal mcs : integer range 0 to C_SEQUENCES-1 :=0;
    signal rcs : integer range 0 to C_SEQUENCES-1 :=0;
    
    signal set : STD_LOGIC :='0';
    signal datain : r_event;
    
    signal run : STD_LOGIC :='0';
    signal t_in : unsigned(C_SEQTIMEWIDTH-1 downto 0);
    signal o : r_outputsequence;

    
    constant clk_period : time := 8 ns; --125MHz
begin
    uut: lithpulser_matcher port map
    (
       clk => clk,
       clear_all => clear_all,
       mcs => mcs,
       set => set,
       datain => datain,
       rcs => rcs,
       run => run,
       t_in => t_in,
       o => o
    );
    
    -- Clock process definitions( clock with 50% duty cycle is generated here.
    clk_process :process
    begin
        clk <= '0';
        wait for clk_period/2;  
        clk <= '1';
        wait for clk_period/2;  
    end process;    
    
    -- Stimulus process
    stim_proc: process
        variable c : unsigned(C_OUTPUTS-1 downto 0);
    begin       
        set <= '0';  
        mcs <= 0;
        rcs <= 0;
        clear_all <='1';
        run <='0';
        wait for clk_period;
        clear_all <='0';        
        wait for clk_period;

        --Load Data
        for i in 0 to 3 loop
            mcs <= i;
            c := TO_UNSIGNED(0,C_OUTPUTS);            
            for t in 0 to 130 loop
                if((t mod (i+1)) = 0) then
                    set <= '1';    
                    datain.t <= TO_UNSIGNED(t,C_SEQTIMEWIDTH);
                    datain.o <= std_logic_vector(c);
                    datain.o(C_OUTPUTS-1 downto 8) <= std_logic_vector(TO_UNSIGNED(i,C_OUTPUTS-8));
                    c :=c+1;
                else
                    set <= '0';
                end if;
                wait for clk_period;
            end loop;            
        end loop;                
        set <= '0';
        
        mcs <= 4;
        c := TO_UNSIGNED(1,14);            
        for t in 0 to 20 loop
            set <= '1';    
            datain.t <= TO_UNSIGNED(TO_INTEGER(c),C_SEQTIMEWIDTH);
            datain.o <= std_logic_vector(c);
            c :=c+c;
            wait for clk_period;
        end loop;            
        set <= '0';
        
        
        wait for 8*clk_period;

        --run
        for i in 0 to 4 loop
            t_in <= TO_UNSIGNED(0,C_SEQTIMEWIDTH);  
            run <= '0';
            wait for clk_period;
            rcs <= i;
            t_in <= (others => 'X');
            run <= '1';
            for t in 0 to 140 loop
                t_in <= TO_UNSIGNED(t,C_SEQTIMEWIDTH);
                wait for clk_period;
            end loop;            
        end loop;                


    end process;    
   
end Behavioral;
