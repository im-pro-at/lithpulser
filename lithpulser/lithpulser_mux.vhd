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

entity lithpulser_mux is Port 
( 
    clk : in STD_LOGIC;
    resetn : in STD_LOGIC; 
    resetout : in STD_LOGIC_VECTOR(C_OUTPUTS-1 downto 0);
    input : in a_outputsequence;
    output : out a_outputs
);
end lithpulser_mux;

architecture Behavioral of lithpulser_mux is
    signal reg : aa_mux;
    signal lastout : STD_LOGIC_VECTOR(C_OUTPUTS-1 downto 0);
begin

    -- in 10 Stages date will be shifted adding delay of 10*8ns => 80ns!
    -- optimised for worst case timing therefore a little bit resouce hungry
    main: process(clk)
    begin
        if(rising_edge(clk)) then
            if(resetn = '0') then
                reg <= (others =>(others => mux_reset));
                lastout <= resetout;
                output <= (others => resetout);
            else 
                --Stage 1 Loade Data:
                for j in 0 to 7 loop
                    reg(0)(j).o <= input(j).o;
                    reg(0)(j).valid <= input(j).valid;
                    reg(0)(j).uselast <= '0';
                end loop;
                
                --Copy date to the next stage
                for i in 1 to 9 loop
                    for j in 0 to 7 loop
                        reg(i)(j).o <=reg(i-1)(j).o;
                        reg(i)(j).valid <=reg(i-1)(j).valid;
                        reg(i)(j).uselast <=reg(i-1)(j).uselast;
                    end loop;
                end loop;
                
                --Stage 2 to 9 Shift informations (worst case 8 shifts needed! => allwase use 8 shifts)
                for i in 1 to 9 loop
                    --First element is special!
                    if (reg(i-1)(0).valid = '0') then 
                        reg(i)(0).uselast <='1';
                    else
                        reg(i)(0).uselast <='0';                    
                    end if;
                    for j in 1 to 7 loop
                        
                        if (reg(i-1)(j).valid = '0') then
                            if(reg(i-1)(j-1).uselast = '1') then
                                reg(i)(j).uselast <= '1';
                            else
                                reg(i)(j).o <= reg(i-1)(j-1).o;
                            end if;
                        end if;                            
                    end loop;
                end loop;
                
                --Stage 10 execute uselast
                 for j in 0 to 7 loop
                    if(reg(9)(j).uselast = '1') then
                        output(j)<=lastout;
                    else
                        output(j)<=reg(9)(j).o;
                    end if;
                 end loop;
                 if(reg(9)(7).uselast = '1') then
                    lastout<=lastout;  
                 else
                    lastout<=reg(9)(7).o;
                 end if;
                 
            end if;
        end if;
    end process; 
    
end Behavioral;
