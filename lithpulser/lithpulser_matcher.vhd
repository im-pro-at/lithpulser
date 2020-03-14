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
use ieee.numeric_std.ALL;
Library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;


entity lithpulser_matcher is port
(
    clk : in std_logic;
    clear_all : in STD_LOGIC;

    --Memory interface
    mcs : in integer range 0 to C_SEQUENCES-1; --Sequenz Select 
    set : in STD_LOGIC;
    datain : in r_event;
    
    --Realtime evebts
    rcs : in integer range 0 to C_SEQUENCES-1; --Sequenz Select 
    run : in STD_LOGIC;
    t_in : in unsigned(C_SEQTIMEWIDTH-1 downto 0);
    o : out r_outputsequence    
);
end lithpulser_matcher;

architecture Behavioral of lithpulser_matcher is

    type a_pointer is array (0 to C_SEQUENCES-1) of integer range 0 to C_EVENTS;
    
    --RAM interface
    signal ram_di: std_logic_vector(16*3-1 downto 0);
    signal ram_do: std_logic_vector(16*3-1 downto 0);
    signal ram_we : std_logic_vector(1 downto 0);
    signal ram_add : std_logic_vector(10 downto 0);
    signal we : std_logic;
    signal setram_add : integer range 0 to C_EVENTS*C_SEQUENCES-1; 
    signal le : r_event;
    signal se : r_event;
    
    --Sequenc managment
    signal pm: a_pointer;        
    signal p : integer range 0 to C_EVENTS;
    signal t_l : unsigned(C_SEQTIMEWIDTH-1 downto 0);

begin

    --Xilinx BRAM
    --BRAM 3*32*1024/(32+14) =~ 16*128
    rams: for i in 0 to 2 generate
        ram : BRAM_SINGLE_MACRO
            generic map (
                BRAM_SIZE => "36Kb", -- Target BRAM, "18Kb" or "36Kb"
                DEVICE => "7SERIES", -- Target device: "VIRTEX5", "VIRTEX6", "7SERIES", "SPARTAN6"
                WRITE_WIDTH => 16, -- Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
                READ_WIDTH => 16, -- Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
                DO_REG => 0, -- Optional output register (0 or 1)
                WRITE_MODE => "WRITE_FIRST" -- Specify "READ_FIRST" for same clock or synchronous clocks
            )
            port map (
                CLK => clk, -- Input write enable, width defined by write port depth
                DO => ram_do(16*(i+1)-1 downto 16*i), -- Output read data port, width defined by READ_WIDTH parameter
                DI => ram_di(16*(i+1)-1 downto 16*i), -- Input write data port, width defined by WRITE_WIDTH parameter
                ADDR => ram_add, -- Input read address, width defined by read port depth
                WE => ram_we, -- 1-bit input read clock
                EN => '1', -- 1-bit input read port enable
                RST => '0', -- 1-bit input reset
                REGCE => '1'
            );
    end generate;

    -- Neutral BRAM
--    ramblock: process(clk)
--    begin
--        if(rising_edge(clk)) then
--           if(we='1') then
--              ram(to_integer(unsigned(ram_add))) <= ram_di(C_SEQTIMEWIDTH+C_OUTPUTS-1 downto 0) ;
--           end if;
--           ram_do(C_SEQTIMEWIDTH+C_OUTPUTS-1 downto 0) <= ram(to_integer(unsigned(ram_add)));
--        end if;    
--    end process;


    ram_we <= (others => we);
    ram_di(C_SEQTIMEWIDTH+C_OUTPUTS-1 downto 0)<= event2slv(se);
    le<=slv2event(ram_do(C_SEQTIMEWIDTH+C_OUTPUTS-1 downto 0));
   
    
    --RAM adress calc must be one clock earlier: 
    caddres: process(we, rcs , le, t_l, p, setram_add)
    begin         
        if(we='0') then --Not writing RAM => prepair for read:
            if(le.t=t_l) then
                ram_add <= std_logic_vector(TO_UNSIGNED(rcs*C_EVENTS+p+1,11));            
            else
                ram_add <= std_logic_vector(TO_UNSIGNED(rcs*C_EVENTS+p,11));                        
            end if;
        else 
            ram_add <= std_logic_vector(TO_UNSIGNED(setram_add,11));
        end if;
    end process;
    
    --Matcher
    matcher: process(clk)
    begin         
        if(rising_edge(clk)) then
            we <= '0';
            o.valid <= '0';
            o.o <= (others => '-'); 
            t_l <= (others => '1');
            if (clear_all='1') then
                pm <= (others => 0);                    
            elsif(run = '0') then 
                p<=0;
                if(pm(mcs)<C_EVENTS) then
                    if(set = '1') then
                        setram_add <= mcs*C_EVENTS+pm(mcs);               
                        we <= '1';
                        se <= datain; 
                        pm(mcs)<=pm(mcs)+1;
                    end if;
                end if;                
            else
                t_l<=t_in;                   
                if(p<pm(rcs)) then
                    if(le.t=t_l) then
                        o.valid <= '1';
                        o.o <=le.o;
                        p<=p+1;                     
                    end if;
                end if;                
            end if;
        end if;
    end process;
    


end Behavioral;
