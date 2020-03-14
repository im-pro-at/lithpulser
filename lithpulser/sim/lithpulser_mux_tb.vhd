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

entity lithpulser_mux_tb is
--  empty => TB
end lithpulser_mux_tb;

architecture Behavioral of lithpulser_mux_tb is
    signal clk : STD_LOGIC :='0';
    signal resetn : STD_LOGIC :='1';
    signal resetout : STD_LOGIC_VECTOR(13 downto 0) := "10000000000001";
    signal input : a_outputsequence := (others => outputsequence_reset);
    signal output : a_outputs:= (others =>(others =>'0'));
    
    constant clk_period : time := 8 ns; --125MHz
begin
    uut: lithpulser_mux port map
    (
       clk=> clk,
       resetn=> resetn,
       resetout=> resetout,
       input=> input,
       output=> output
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
        variable e:STD_LOGIC_VECTOR(7 downto 0);
    begin         
        for i in 0 to 7 loop
            input(i).o<=STD_LOGIC_VECTOR(to_unsigned(i,C_OUTPUTS));
        end loop;
        e:="00000000";
        for i in 0 to 7 loop
            input(i).valid<=e(i);
        end loop;
    
        resetn <='0';
        wait for 5*clk_period;
        resetn <='1';
        wait for 8*clk_period;
        e:="00010000";
        for i in 0 to 7 loop
            input(i).valid<=e(i);
        end loop;
        wait for clk_period;
        e:="10000001";
        for i in 0 to 7 loop
            input(i).valid<=e(i);
        end loop;
        wait for clk_period;
        e:="01010101";
        for i in 0 to 7 loop
            input(i).valid<=e(i);
        end loop;
        wait for clk_period;
        e:="10101010";
        for i in 0 to 7 loop
            input(i).valid<=e(i);
        end loop;
        wait for clk_period;
        e:="01111110";
        for i in 0 to 7 loop
            input(i).valid<=e(i);
        end loop;
        wait for clk_period;
        e:="00000000";
        for i in 0 to 7 loop
            input(i).valid<=e(i);
        end loop;
        wait for 8*clk_period;
        e:="11111111";
        for i in 0 to 7 loop
            input(i).valid<=e(i);
        end loop;
        wait for 11*clk_period;
        resetn <='0';
        wait for clk_period;


    end process;    
   
end Behavioral;
