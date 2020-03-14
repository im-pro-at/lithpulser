------------------------------------------------------------------------------------
-- Company: im-pro.at
-- Engineer: Patrick Knöbel
--
--   GNU GENERAL PUBLIC LICENSE Version 3
--
------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.ALL;
use work.lithpulser_package.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity lithpulser is Port 
( 
    clk : in STD_LOGIC;
    rstn : in STD_LOGIC;

    led_o : out STD_LOGIC_VECTOR (7 downto 0);
    outputs : out STD_LOGIC_VECTOR (C_OUTPUTS-1 downto 0);
    inputs  : in STD_LOGIC_VECTOR (1 downto 0);
    
    sys_addr : in STD_LOGIC_VECTOR (16 downto 0);
    sys_wdata : in STD_LOGIC_VECTOR (31 downto 0);
    sys_wea : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    sys_rea : in STD_LOGIC;
    sys_rdata : out STD_LOGIC_VECTOR (31 downto 0);
    
    --TO FIFO
    log_reset  : out STD_LOGIC;
    log_din : out STD_LOGIC_VECTOR(56 DOWNTO 0);
    log_wr: OUT STD_LOGIC;
    log_rd: OUT STD_LOGIC;
    log_dout: IN STD_LOGIC_VECTOR(56 DOWNTO 0);
    log_full: IN STD_LOGIC;
    log_empty: IN STD_LOGIC
    
); 
end lithpulser;

architecture Behavioral of lithpulser is
    ATTRIBUTE X_INTERFACE_INFO : STRING;
    
    ATTRIBUTE X_INTERFACE_INFO OF sys_rea: SIGNAL IS "xilinx.com:interface:bram:1.0 BRAM_PORTA EN";
    ATTRIBUTE X_INTERFACE_INFO OF sys_wea: SIGNAL IS "xilinx.com:interface:bram:1.0 BRAM_PORTA WE";
    ATTRIBUTE X_INTERFACE_INFO OF sys_addr: SIGNAL IS "xilinx.com:interface:bram:1.0 BRAM_PORTA ADDR";
    ATTRIBUTE X_INTERFACE_INFO OF sys_wdata: SIGNAL IS "xilinx.com:interface:bram:1.0 BRAM_PORTA DIN";
    ATTRIBUTE X_INTERFACE_INFO OF sys_rdata: SIGNAL IS "xilinx.com:interface:bram:1.0 BRAM_PORTA DOUT";
    
    ATTRIBUTE X_INTERFACE_INFO OF log_din: SIGNAL IS "xilinx.com:interface:fifo_write:1.0 LOG_FIFO_WRITE WR_DATA";
    ATTRIBUTE X_INTERFACE_INFO OF log_wr: SIGNAL IS "xilinx.com:interface:fifo_write:1.0 LOG_FIFO_WRITE WR_EN";
    ATTRIBUTE X_INTERFACE_INFO OF log_full: SIGNAL IS "xilinx.com:interface:fifo_write:1.0 LOG_FIFO_WRITE FULL";
    ATTRIBUTE X_INTERFACE_INFO OF log_rd: SIGNAL IS "xilinx.com:interface:fifo_read:1.0 LOG_FIFO_READ RD_EN";
    ATTRIBUTE X_INTERFACE_INFO OF log_dout: SIGNAL IS "xilinx.com:interface:fifo_read:1.0 LOG_FIFO_READ RD_DATA";
    ATTRIBUTE X_INTERFACE_INFO OF log_empty: SIGNAL IS "xilinx.com:interface:fifo_read:1.0 LOG_FIFO_READ EMPTY";



    --Mapping Signals
    signal os : a_outputs;
    signal muxin :a_outputsequence;
    signal m_clear :STD_LOGIC;
    signal m_mcs : integer range 0 to C_SEQUENCES-1;
    signal m_set : STD_LOGIC_VECTOR(7 downto 0);
    signal m_datain : r_event;
    signal m_run :STD_LOGIC;
    signal m_t : tt;
    signal sys_wen: STD_LOGIC;
    signal log_overrun : STD_LOGIC;

    signal stopout : STD_LOGIC_VECTOR(C_OUTPUTS-1 downto 0);
    signal seqs : a_sequence;    
    
    signal cs : integer range 0 to C_SEQUENCES-1;
    signal next_cs: integer range 0 to C_SEQUENCES-1;
    signal has_next_cs: std_logic;
    signal loglevel : STD_LOGIC_VECTOR(1 downto 0);
    signal run : std_logic;
    signal runt : unsigned(C_GLOBTIMEWIDTH-1 downto 0);
    signal seqs_count : a_seqcount;
    signal seqsrun_done: std_logic;
    signal seqs_to_counter : a_seqtimout;
    signal seqs_to : STD_LOGIC_VECTOR(C_SEQUENCES-1 downto 0);
    signal seqs_done : STD_LOGIC_VECTOR(C_SEQUENCES-1 downto 0);
    signal t: unsigned(C_SEQTIMEWIDTH-1 downto 0);

    --State 
    signal state : t_state;

    --ld
    signal ld_in: a_ldin;
    signal lastldin : std_logic_vector(1 downto 0);
    signal ldcount : a_ldcount;
    signal ldcounterreset : std_logic;
    
begin
    
    ---------------------------------STATE MASCHINE---------------------------------------
    sm: process(clk)
        variable c_init_wait: integer range 0 to 11;
    begin
        if(rising_edge(clk)) then
            -- Signals
            log_wr <= '0';
            log_reset <= '0';
            next_cs <= 0;
            has_next_cs <= '0';
            m_run <= '0';
            ldcounterreset <= '0';
            seqsrun_done <= '0';
            
            if(rstn = '0') then
                state <= S_STOP; 
                log_reset <= '1';
                log_overrun <= '0';
                seqs_count <= (others => (others => '0'));
                seqs_to_counter <= (others => (others => '0'));
                seqs_done <= (others => '0');
                t <= (others => '0'); 
                m_t <= (others => (others => '0'));   
            else

                if(log_full='1') then
                    log_overrun <= '1';
                end if;
                
                --Global Runtime
                runt <= runt+8; --8ns pro 125MHz
                -- Timeouts for seqences
                for i in 0 to C_SEQUENCES-1 loop
                    if(seqs(i).used = '0' or seqs_done(i)='1') then 
                      --If not used or done there is never a timeout
                      seqs_to(i) <= '0';                    
                    elsif(seqs_to_counter(i)>=8) then
                      seqs_to_counter(i) <= seqs_to_counter(i) -8;                          
                      seqs_to(i) <= '0';
                    else
                      seqs_to_counter(i) <= (others => '0');                          
                      seqs_to(i) <= '1';
                    end if;
                end loop;
                
                
                case state is 
                    when S_STOP => 
                        runt <= (others => '0');
                        if(run = '1') then
                            seqs_count <= (others => (others => '0'));
                            seqs_to_counter <= (others => (others => '0'));
                            seqs_done <= (others => '0');
                            state <= S_INIT;
                            c_init_wait := 0;  
                        end if;
                    when S_INIT => 
                        --Wait for Log to initialise
                        log_overrun <= '0';
                        log_reset <= '1';
                        if(c_init_wait>=7) then 
                            log_reset <= '0';
                        end if;
                        if(c_init_wait>=10) then
                            state <= S_PRERUN1;  
                        end if;
                        c_init_wait := c_init_wait+1;
                    when S_PRERUN1 =>
                        for i in 0 to C_SEQUENCES-1 loop
                            if(seqs_to(i)='1') then
                                has_next_cs <= '1';
                                next_cs <= i;
                                exit;
                            end if;
                        end loop;
                        state <= S_PRERUN2;              
                    when S_PRERUN2 =>
                        if(run <= '0') then
                            state <= S_STOP;
                        elsif(has_next_cs = '1') then 
                            cs <= next_cs; 
                            t <= (others => '0'); 
                            m_t <= (others => (others => '0'));   
                            --Reset counters:
                            ldcounterreset <= '1';
                            --Log start time
                            if(loglevel(1)='1') then
                                log_wr <= '1';
                                log_din(0) <= '0';
                                log_din(4-1+1 downto 1) <= std_logic_vector(TO_UNSIGNED(next_cs,4));
                                log_din(C_GLOBTIMEWIDTH-1+5 downto 5) <= std_logic_vector(runt);
                            end if;
                            seqs_count(next_cs) <= seqs_count(next_cs)+1;  
                            state <= S_RUN;              
                        else
                            state <= S_PRERUN1;                             
                        end if;    
                    when S_RUN =>
                        if(run <= '0') then
                            state <= S_STOP;
                        else
                            m_run <= '1';

                            for i in 0 to 7 loop
                                m_t(i) <= t+i;
                            end loop;

                            t <= t+8; --8ns pro 125MHz

                            if(t+8>=seqs(cs).length) then 
                               state <= S_POSTRUN1;
                            end if;
                        end if;
                    when S_POSTRUN1 =>
                        --Test logical condition for rerun:
                        case TO_INTEGER(seqs(cs).ldmode) is
                            when 0 => seqsrun_done<='1'; --NO RERUN
                            when 1 => 
                                if(ldcount(0)>=seqs(cs).lds(0).minc and  ldcount(0)<=seqs(cs).lds(0).maxc) then 
                                    seqsrun_done<='1'; --NO RERUN
                                end if;
                            when 2 => 
                                if(ldcount(1)>=seqs(cs).lds(1).minc and  ldcount(1)<=seqs(cs).lds(1).maxc) then 
                                    seqsrun_done<='1'; --NO RERUN
                                end if;
                            when 3 => 
                                if((ldcount(0)>=seqs(cs).lds(0).minc and  ldcount(0)<=seqs(cs).lds(0).maxc) and (ldcount(1)>=seqs(cs).lds(1).minc and  ldcount(1)<=seqs(cs).lds(1).maxc)) then 
                                    seqsrun_done<='1'; --NO RERUN
                                end if;
                            when 4 => 
                                if((ldcount(0)>=seqs(cs).lds(0).minc and  ldcount(0)<=seqs(cs).lds(0).maxc) or (ldcount(1)>=seqs(cs).lds(1).minc and  ldcount(1)<=seqs(cs).lds(1).maxc)) then 
                                    seqsrun_done<='1'; --NO RERUN
                                end if;
                            when others => seqsrun_done<='1';  --Default NO RERUN
                        end case;
                        state <= S_POSTRUN2;                    
                    when S_POSTRUN2 =>
                        if(seqsrun_done = '1') then 
                            if(seqs(cs).rerun = maxunsigend(seqs(cs).rerun'LENGTH)) then
                                --Sequence done for ever
                                seqs_done(cs) <= '1';                                
                                seqs_to(cs) <= '0';
                            else 
                                seqs_to_counter(cs) <= seqs(cs).rerun;
                                if(seqs(cs).rerun= 0) then
                                    --Sequence cen be rerun imidetly
                                    seqs_to(cs) <= '1';                            
                                else
                                    --RERUN after timout
                                    seqs_to(cs) <= '0';
                                end if;
                            end if;
                        else
                            --RERUN as soon as possible no new Timeout
                        end if;
                        
                        --Log counters
                        if(TO_INTEGER(seqs(cs).ldmode)/=0 and loglevel(0)='1') then
                            log_wr <= '1';
                            log_din(0) <= '1';
                            log_din(4 downto 1) <= std_logic_vector(TO_UNSIGNED(cs,4));
                            log_din(C_PULSECERWIDTH-1+5 downto 5) <= std_logic_vector(ldcount(0));
                            log_din(C_PULSECERWIDTH-1+31 downto 31) <= std_logic_vector(ldcount(1));
                        end if;  
                        
                        state <= S_PRERUN1;                    
                end case;             
            end if;
        end if;
    end process;    


    ---------------------------------LOGICAL DECISION-------------------------------------

    ld: process(clk)
    begin
        if(rising_edge(clk)) then
            for i in 0 to 1 loop
                ld_in(i)(0) <= inputs(i);
                if(rstn = '0') then
                    lastldin(i) <= '0'; 
                    for j in 1 to 5 loop
                        ld_in(i)(j) <= '0';
                    end loop;
                elsif(ldcounterreset = '1') then 
                    ldcount(i) <= (others => '0');            
                else
                    --Coming form different clock domain => sync! 6 Stages => TTF ~10^9
                    for j in 0 to 4 loop
                        ld_in(i)(j+1) <= ld_in(i)(j);
                    end loop;
                    --debouncing
                    if(ld_in(i)(4) = ld_in(i)(5)) then 
                        --edge detection
                        if(ld_in(i)(5) /= lastldin(i)) then 
                            lastldin(i) <= ld_in(i)(5);
                            --Positive edge
                            if(lastldin(i) = '0') then 
                                if(t>seqs(cs).lds(i).st and t<seqs(cs).lds(i).et) then 
                                    --count only in window
                                    ldcount(i) <= ldcount(i) +1;
                                end if;
                            end if;
                        end if;    
                    end if;
                                        
                end if;
            end loop;
        end if;
    end process;    
    
    ---------------------------------MODULE MAPPING---------------------------------------
    
    --Latency 8sn (1clk)
    matchers: for i in 0 to 7 generate
        matcher: lithpulser_matcher port map
        (
            clk => clk,
            clear_all => m_clear,
            
            --Memory interface
            mcs => m_mcs,
            set => m_set(i),
            datain => m_datain,
            
            --Realtime events
            rcs => cs,
            run => m_run,
            t_in => m_t(i),
            o => muxin(i)  
        );
    end generate;

    --Latency 80ns (10clk)
    mux: lithpulser_mux port map 
    (
        clk=> clk,
        resetn=> run,
        resetout=> stopout,
        input=> muxin,
        output=> os
    );
    
    --Latency 32ns (4clk)
    o: lithpulser_outddr port map
    (
        input => os,
        output => outputs,
        clk_in => clk,
        rstn => rstn  
    );
    
    led: process(clk)
    begin
        if(rising_edge(clk)) then
            led_o <= (others => '0');
            led_o(0)<=run;    
            led_o(1)<=log_overrun; 
            if(m_run='1') then   
                for i in 0 to 5 loop
                    if(cs = i) then 
                        led_o(i+2)<='1';
                    end if;
                end loop;
            end if;
        end if;
    end process;    
    
    ------------------------------------------SYSTEM BUS RGISTERMAP---------------------------------------------
    
    sys_wen <= (sys_wea(0) or sys_wea(1) or sys_wea(2) or sys_wea(3)) and sys_rea;
    
    sys_write: process(clk)
        variable tcs: integer range 0 to C_SEQUENCES-1;
    begin
        if(rising_edge(clk)) then
            --matcher mem interface reset
            m_set <= (others => '0');
            m_clear <= '0';
            if(rstn = '0') then
                seqs <= (others => sequence_reset);
                m_clear <= '1';
                stopout <= (others => '0');
                run <= '0';
                loglevel <= (others => '0');
            elsif(sys_wen = '1') then 
                if(sys_addr(16 downto 12)="00000") then 
                    --Controll
                    case sys_addr(11 downto 0) is
                        when x"004" => run <= sys_wdata(0);
                        when x"008" => 
                            if (sys_wdata(0)='1') then 
                                seqs <= (others => sequence_reset);
                                m_clear <= '1';
                            end if;
                        when x"010" => stopout <= sys_wdata(C_OUTPUTS-1 downto 0);
                        when x"020" => loglevel <= sys_wdata(1 downto 0);
                        when others => null;
                    end case;                                     
                elsif(sys_addr(16)='1') then
                    --Sequentce X
                    tcs := TO_INTEGER(UNSIGNED(sys_addr(15 downto 12)));
                    case sys_addr(11 downto 0) is
                        when x"000" => seqs(tcs).used <= sys_wdata(0);
                        when x"020" => seqs(tcs).rerun <= unsigned(sys_wdata(C_SEQTIMEWIDTH-1 downto 0));
                        when x"024" => seqs(tcs).length <= unsigned(sys_wdata(C_SEQTIMEWIDTH-1 downto 0));
                        when x"030" => seqs(tcs).last_din.o <= sys_wdata(C_OUTPUTS-1 downto 0);
                        when x"034" => seqs(tcs).last_din.t <= unsigned(sys_wdata(C_SEQTIMEWIDTH-1 downto 0));
                        when x"038" =>
                            if(sys_wdata(0)='1') then 
                                m_datain <=  seqs(tcs).last_din;
                                seqs(tcs).last_din <= event_reset;
                                m_mcs <= tcs;
                                m_set(TO_INTEGER(seqs(tcs).last_din.t) mod 8) <= '1';  --Set for the right macher  
                            end if;
                        when x"100" => seqs(tcs).ldmode <= unsigned(sys_wdata(7 downto 0));
                        when x"110" => seqs(tcs).lds(0).st <= unsigned(sys_wdata(C_SEQTIMEWIDTH-1 downto 0));
                        when x"114" => seqs(tcs).lds(0).et <= unsigned(sys_wdata(C_SEQTIMEWIDTH-1 downto 0));
                        when x"118" => seqs(tcs).lds(0).minc <= unsigned(sys_wdata(C_PULSECERWIDTH-1 downto 0));
                        when x"11C" => seqs(tcs).lds(0).maxc <= unsigned(sys_wdata(C_PULSECERWIDTH-1 downto 0));
                        when x"120" => seqs(tcs).lds(1).st <= unsigned(sys_wdata(C_SEQTIMEWIDTH-1 downto 0));
                        when x"124" => seqs(tcs).lds(1).et <= unsigned(sys_wdata(C_SEQTIMEWIDTH-1 downto 0));
                        when x"128" => seqs(tcs).lds(1).minc <= unsigned(sys_wdata(C_PULSECERWIDTH-1 downto 0));
                        when x"12C" => seqs(tcs).lds(1).maxc <= unsigned(sys_wdata(C_PULSECERWIDTH-1 downto 0));
                        when others => null;
                    end case; 
                end if;
            end if;
        end if;
    end process; 

    
    sys_read: process(clk)
        variable tcs: integer range 0 to C_SEQUENCES-1;
    begin
        if(rising_edge(clk)) then
            log_rd <= '0';
            sys_rdata <= (others => '0');
            if (sys_rea='1') then 
                if(sys_addr(16 downto 12)="00000") then 
                    --Controll
                    case sys_addr(11 downto 0) is
                        when x"000" => sys_rdata(31 downto 0) <= x"0BADA550";
                        when x"004" => sys_rdata(0) <= run;
                        when x"010" => sys_rdata(C_OUTPUTS-1 downto 0) <= stopout;
                        when x"020" => sys_rdata(1 downto 0) <= loglevel;
                        when x"030" => sys_rdata(31 downto 0) <= log_dout(31 downto 0);
                        when x"034" => sys_rdata(24 downto 0) <= log_dout(56 downto 32);
                        when x"038" => 
                            if(log_empty='1') then
                                --No new element
                                sys_rdata(0) <= '0';
                            else
                                --Read next element
                                sys_rdata(0) <= '1';
                                log_rd <= '1';
                            end if;
                        when x"03C" => sys_rdata(0) <= log_overrun;
                        when others => null;
                    end case;                                     
                elsif(sys_addr(16)='1') then
                    --Sequentce X
                    tcs := TO_INTEGER(UNSIGNED(sys_addr(15 downto 12)));
                    case sys_addr(11 downto 0) is
                        when x"000" => sys_rdata(0) <= seqs(tcs).used;
                        when x"010" => sys_rdata(31 downto 0) <= std_logic_vector(seqs_count(tcs)); 
                        when x"020" => sys_rdata(C_SEQTIMEWIDTH-1 downto 0) <= std_logic_vector(seqs(tcs).rerun);
                        when x"024" => sys_rdata(C_SEQTIMEWIDTH-1 downto 0) <= std_logic_vector(seqs(tcs).length);
                        when x"030" => sys_rdata(C_OUTPUTS-1 downto 0) <= std_logic_vector(seqs(tcs).last_din.o);
                        when x"034" => sys_rdata(C_SEQTIMEWIDTH-1 downto 0) <= std_logic_vector(seqs(tcs).last_din.t);
                        when x"100" => sys_rdata(7 downto 0) <= std_logic_vector(seqs(tcs).ldmode);
                        when x"110" => sys_rdata(C_SEQTIMEWIDTH-1 downto 0) <= std_logic_vector(seqs(tcs).lds(0).st);
                        when x"114" => sys_rdata(C_SEQTIMEWIDTH-1 downto 0) <= std_logic_vector(seqs(tcs).lds(0).et);
                        when x"118" => sys_rdata(C_PULSECERWIDTH-1 downto 0) <= std_logic_vector(seqs(tcs).lds(0).minc);
                        when x"11C" => sys_rdata(C_PULSECERWIDTH-1 downto 0) <= std_logic_vector(seqs(tcs).lds(0).maxc);
                        when x"120" => sys_rdata(C_SEQTIMEWIDTH-1 downto 0) <= std_logic_vector(seqs(tcs).lds(1).st);
                        when x"124" => sys_rdata(C_SEQTIMEWIDTH-1 downto 0) <= std_logic_vector(seqs(tcs).lds(1).et);
                        when x"128" => sys_rdata(C_PULSECERWIDTH-1 downto 0) <= std_logic_vector(seqs(tcs).lds(1).minc);
                        when x"12C" => sys_rdata(C_PULSECERWIDTH-1 downto 0) <= std_logic_vector(seqs(tcs).lds(1).maxc);
                        when others => null;
                    end case; 
                end if;
            end if;
        end if;
    end process; 
end Behavioral;
