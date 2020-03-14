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

entity lithpulser_tb is
--  empty => TB
end lithpulser_tb;



architecture Behavioral of lithpulser_tb is
    constant clk_period : time := 8 ns; --125MHz
    constant I0_period : time := 32 ns; 
    constant I1_period : time := 40 ns; 
    signal clk : STD_LOGIC :='0';

    signal rstn : STD_LOGIC;
    signal led_o : STD_LOGIC_VECTOR (7 downto 0);
    signal outputs : STD_LOGIC_VECTOR (13 downto 0);
    signal inputs  : STD_LOGIC_VECTOR (1 downto 0);
    signal sys_addr : STD_LOGIC_VECTOR (31 downto 0);
    signal sys_wdata : STD_LOGIC_VECTOR (31 downto 0);
    signal sys_wea : STD_LOGIC_VECTOR (3 downto 0);
    signal sys_rea : STD_LOGIC;
    signal sys_rdata : STD_LOGIC_VECTOR (31 downto 0);

    signal log_reset  :  STD_LOGIC;
    signal log_din :  STD_LOGIC_VECTOR(56 DOWNTO 0);
    signal log_wr:  STD_LOGIC;
    signal log_rd:  STD_LOGIC;
    signal log_dout:  STD_LOGIC_VECTOR(56 DOWNTO 0);
    signal log_full:  STD_LOGIC;
    signal log_empty:  STD_LOGIC;

begin

    uut: lithpulser port map
    (
        clk => clk,
        rstn=> rstn,
        led_o=> led_o,
        outputs=> outputs,
        inputs=> inputs,
        sys_addr=> sys_addr(16 downto 0),
        sys_wdata=> sys_wdata,
        sys_wea=> sys_wea,
        sys_rea=> sys_rea,
        sys_rdata=> sys_rdata,

        log_reset => log_reset,
        log_din  => log_din,
        log_wr => log_wr,
        log_rd => log_rd,
        log_dout => log_dout,
        log_full => log_full,
        log_empty => log_empty
    );
    
    

    -- Clock process definitions( clock with 50% duty cycle is generated here.
    clk_process :process
    begin
        clk <= '0';
        wait for clk_period/2;  --for 0.5 ns signal is '0'.
        clk <= '1';
        wait for clk_period/2;  --for next 0.5 ns signal is '1'.
    end process;    

    I0 :process
    begin
        inputs(0) <= '0';
        wait for I0_period/2;  
        inputs(0) <= '1';
        wait for I0_period/2;  
    end process;    
    
    I1 :process
    begin
        inputs(1) <= '0';
        wait for I1_period/2;  
        inputs(1) <= '1';
        wait for I1_period/2; 
    end process;    

    
    -- Stimulus process
    stim_proc: process
        procedure write_reg (addr : STD_LOGIC_VECTOR (31 downto 0); data : STD_LOGIC_VECTOR (31 downto 0)) is
        begin
            sys_addr <= addr;
            sys_wdata <= data;
            sys_wea <= (others => '1');
            sys_rea <= '1';
            wait for clk_period; 
            sys_wea <= (others => '0');
            sys_rea <= '0';
            wait for clk_period;         
        end write_reg;

        procedure read_log is
        begin
            sys_addr <= x"40000038";
            sys_rea <= '1';
            wait for clk_period; 
            sys_rea <= '0';
            wait for clk_period;         
            sys_addr <= x"40000030";
            sys_rea <= '1';
            wait for clk_period; 
            sys_rea <= '0';
            wait for clk_period;         
            sys_addr <= x"40000034";
            sys_rea <= '1';
            wait for clk_period; 
            sys_rea <= '0';
            wait for clk_period;         
        end read_log;

    begin           
        sys_addr  <= (others => '0');
        sys_wdata <= (others => '0');
        sys_wea   <= (others => '0');
        sys_rea   <= '0';
        rstn      <= '0';
        log_dout  <= (others => '0');
        log_full  <= '0';
        log_empty <= '0';
        wait for 10*clk_period;
        rstn      <= '1';
        wait for 8*clk_period;
        
        --Configur
        write_reg(x"40000008",x"00000001"); --RESET Settings
        write_reg(x"40000010",x"0000AAAA"); --RESET PATTERN
        write_reg(x"40000020",x"00000003"); --LOGLEVEL FULL

        --Configur sequence 1
        write_reg(x"40010000",x"00000001"); --Enable
        write_reg(x"40010020",x"00000100"); --Rerun after 265ns
        write_reg(x"40010024",x"00000400"); --Length 1024 ns
        
        for i in 0 to 31 loop
            write_reg(x"40010030", std_logic_vector(TO_UNSIGNED(i+1,32)) ); --Outputpattern
            write_reg(x"40010034", std_logic_vector(TO_UNSIGNED(i*32,32)) ); --Output time
            write_reg(x"40010038", x"00000001"); --transfer 
        end loop;        
        
        write_reg(x"40010100",x"00000004"); --ld mode

        write_reg(x"40010110",x"00000000"); --ld I0 st
        write_reg(x"40010114",x"00000400"); --ld I0 et
        write_reg(x"40010118",x"00000020"); --ld I0 minc
        write_reg(x"4001011C",x"00000100"); --ld I0 maxc

        write_reg(x"40010120",x"00000040"); --ld I1 st
        write_reg(x"40010124",x"00000400"); --ld I1 et
        write_reg(x"40010128",x"00000000"); --ld I1 minc
        write_reg(x"4001012C",x"00000100"); --ld I1 maxc


        --Configur sequence 2
        write_reg(x"40011000",x"00000001"); --Enable
        write_reg(x"40011020",x"FFFFFFFF"); --NO rerun
        write_reg(x"40011024",x"00000020"); --Length 32 ns
        
        for i in 0 to 32 loop
            write_reg(x"40011030", std_logic_vector(TO_UNSIGNED(256+i+1,32)) ); --Outputpattern
            write_reg(x"40011034", std_logic_vector(TO_UNSIGNED(i,32)) ); --Output time
            write_reg(x"40011038", x"00000001"); --transfer 
        end loop;        
        
        write_reg(x"40011100",x"00000000"); --ld mode
        

        --Configur sequence 3
        write_reg(x"40012000",x"00000001"); --Enable
        write_reg(x"40012020",x"00000000"); --Rerun after imitetally
        write_reg(x"40012024",x"00000020"); --Length 32 ns
        
        for i in 0 to 31 loop
            write_reg(x"40012030", std_logic_vector(TO_UNSIGNED(1024+i+1,32)) ); --Outputpattern
            write_reg(x"40012034", std_logic_vector(TO_UNSIGNED(i,32)) ); --Output time
            write_reg(x"40012038", x"00000001"); --transfer 
        end loop;        
        
        write_reg(x"40011200",x"00000000"); --ld mode
        

        
        --START
        write_reg(x"40000004",x"00000001");

        wait for 1000*clk_period;

        --STOP
        write_reg(x"40000004",x"00000000");

        wait for 10*clk_period;


        for i in 0 to 10 loop
            read_log;    
        end loop;        
    end process;    
   
end Behavioral;
