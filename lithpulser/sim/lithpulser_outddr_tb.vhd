------------------------------------------------------------------------------------
-- Company: im-pro.at
-- Engineer: Patrick Knöbel
--
--   GNU GENERAL PUBLIC LICENSE Version 3
--
------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.lithpulser_package.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lithpulser_outddr_tb is
--  empty => TB
end lithpulser_outddr_tb;

architecture Behavioral of lithpulser_outddr_tb is
    signal clk : STD_LOGIC :='0';
    signal rstn : STD_LOGIC :='1';

    signal input : a_outputs := (others => (others =>'0'));
    signal output : std_logic_vector(C_OUTPUTS-1 downto 0) := (others =>'0');

    constant clk_period : time := 8 ns; --125MHz
begin

    uut: lithpulser_outddr port map
    (
       clk_in=> clk,
       rstn=> rstn,
       input=> input,
       output=> output
    );

    -- Clock process definitions( clock with 50% duty cycle is generated here.
    clk_process :process
    begin
        clk <= '0';
        wait for clk_period/2;  --for 0.5 ns signal is '0'.
        clk <= '1';
        wait for clk_period/2;  --for next 0.5 ns signal is '1'.
    end process;    
    
    -- Stimulus process
    stim_proc: process
        variable c : integer :=0;
    begin         
        for i in 0 to 7 loop
            input(i) <= (others => '0');
        end loop;
        c:=0;
    
        rstn <='0';
        wait for 5*clk_period;
        rstn <='1';
        
        for x in 0 to 100 loop
            for i in 0 to 7 loop
                input(i) <= STD_LOGIC_VECTOR(to_unsigned(c,C_OUTPUTS));
                c:=c+1;
            end loop;
            wait for clk_period;
        end loop;

    end process;    
   
end Behavioral;
