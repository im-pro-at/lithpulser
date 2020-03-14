------------------------------------------------------------------------------------
-- Company: im-pro.at
-- Engineer: Patrick Knöbel
--
--   GNU GENERAL PUBLIC LICENSE Version 3
--
------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VComponents.all;


entity redpitaya_hk is
    Port ( clk_i_p : in STD_LOGIC;
           clk_i_n : in STD_LOGIC;
           rstn_i : in STD_LOGIC;
           clk_o : out STD_LOGIC;
           rstn_o : out STD_LOGIC;
           adc_clk_o : out STD_LOGIC_VECTOR ( 1 downto 0 );
           adc_cdcs_o : out STD_LOGIC);
end redpitaya_hk;

architecture Behavioral of redpitaya_hk is
    ATTRIBUTE X_INTERFACE_INFO : STRING;
    ATTRIBUTE X_INTERFACE_INFO OF clk_o: SIGNAL IS "xilinx.com:signal:clock:1.0 clock CLK";

    signal clk_i: STD_LOGIC;
    signal clk_ub: STD_LOGIC;
    signal clkfb : STD_LOGIC;
    signal rst_pll: STD_LOGIC;
    signal pll_locked : STD_LOGIC;    
begin
    rst_pll <= not rstn_i;
    
    clk_i_divbuffer: IBUFDS port map 
    (
        I=> clk_i_p,
        IB=> clk_i_n,
        O=> clk_i
    );
    
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
        CLKIN1_PERIOD      =>   8.0
    )
    port map(
        CLKFBOUT      =>      clkfb, 
        CLKOUT0       =>      clk_ub,
        CLKOUT1       =>      open,
        CLKOUT2       =>      open,
        CLKOUT3       =>      open,
        CLKOUT4       =>      open,
        CLKOUT5       =>      open,
        --Input clock control
        CLKFBIN       =>      clkfb,
        CLKIN1        =>      clk_i,
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
        RST           =>      rst_pll
    );

    clk_o_buf: BUFG port map 
    (
        I=> clk_ub,
        O=> clk_o
    );

    
    rstn_o <= rstn_i and pll_locked;
    adc_clk_o <= "10";
    adc_cdcs_o <= '1';
    


end Behavioral;
