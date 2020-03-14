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
library UNISIM;
use UNISIM.VComponents.all;

entity lithpulser_outddr is port 
(
    input : in a_outputs;
    output : out std_logic_vector(C_OUTPUTS-1 downto 0);
    
    clk_in: in STD_LOGIC;
    rstn: in STD_LOGIC
    
);
end lithpulser_outddr;
    

architecture Behavioral of lithpulser_outddr is
    signal rst: STD_LOGIC;
    signal rst_sync: STD_LOGIC;
    signal clkfb : STD_LOGIC;
    signal clk_out : STD_LOGIC;
    signal clk4_out : STD_LOGIC; 
    signal pll_locked : STD_LOGIC;
        
    signal out_prebuf : std_logic_vector(C_OUTPUTS-1 downto 0);

    attribute dont_touch : string;
    attribute dont_touch of clkfb : signal is "true";
    attribute dont_touch of clk_out : signal is "true";
    attribute dont_touch of clk4_out : signal is "true";

begin
    rst <= not rstn;
    
    pll: PLLE2_ADV generic map
    (
        BANDWIDTH          =>   "HIGH",
        COMPENSATION       =>   "ZHOLD",
        DIVCLK_DIVIDE      =>   1,
        CLKFBOUT_MULT      =>   8,
        CLKFBOUT_PHASE     =>   0.000,
        CLKOUT0_DIVIDE     =>   8,
        CLKOUT0_PHASE      =>   0.000,
        CLKOUT0_DUTY_CYCLE =>   0.500,
        CLKOUT1_DIVIDE     =>   2,
        CLKOUT1_PHASE      =>   0.000,
        CLKOUT1_DUTY_CYCLE =>   0.500,
        CLKIN1_PERIOD      =>   8.0
    )
    port map(
        CLKFBOUT      =>      clkfb, 
        CLKOUT0       =>      clk_out,   --125Mhz
        CLKOUT1       =>      clk4_out,  --500Mhz
        CLKOUT2       =>      open,
        CLKOUT3       =>      open,
        CLKOUT4       =>      open,
        CLKOUT5       =>      open,
        --Input clock control
        CLKFBIN       =>      clkfb,
        CLKIN1        =>      clk_in,
        CLKIN2        =>      '0',
        --Tied to always select the primary input clock
        CLKINSEL      =>      '1',
        --Ports for dynamic reconfiguration
        DADDR         =>      (others => '0'),
        DCLK          =>      '0',
        DEN           =>      '0',
        DI            =>      (others => '0'),
        DO            =>      open,
        DRDY          =>      open,
        DWE           =>      '0',
        --Other control and status signals
        LOCKED        =>      pll_locked,
        PWRDWN        =>      '0',
        RST           =>      rst
    );
   
    reset_sync: process(clk_in)
    begin
        if(rising_edge(clk_in)) then
            rst_sync <= (not pll_locked) or rst;
        end if;
    end process;    
        
    
    genos: for i in 0 to C_OUTPUTS-1 generate
        os : OSERDESE2 generic map
        (  
            DATA_RATE_OQ   => "DDR",
            DATA_RATE_TQ   => "SDR",
            DATA_WIDTH     => 8,
            TRISTATE_WIDTH => 1,
            SERDES_MODE    => "MASTER"        
        )
        port map(
            D1           =>  input(0)(i),
            D2           =>  input(1)(i),
            D3           =>  input(2)(i),
            D4           =>  input(3)(i),
            D5           =>  input(4)(i),
            D6           =>  input(5)(i),
            D7           =>  input(6)(i),
            D8           =>  input(7)(i),
            T1           =>  '0',
            T2           =>  '0',
            T3           =>  '0',
            T4           =>  '0',
            SHIFTIN1     =>  '0',
            SHIFTIN2     =>  '0',
            SHIFTOUT1    =>  open,
            SHIFTOUT2    =>  open,
            OCE          =>  '1',
            CLK          =>  clk4_out,
            CLKDIV       =>  clk_out,
            OQ           =>  out_prebuf(i),
            TQ           =>  open,
            OFB          =>  open, 
            TFB          =>  open,
            TBYTEIN      =>  '0',
            TBYTEOUT     =>  open,
            TCE          =>  '0',
            RST          =>  rst_sync
    
        );
        o: OBUF port map
        (
            I    =>     out_prebuf(i),
            O   =>      output(i)
        );
                
    end generate;

end Behavioral;
