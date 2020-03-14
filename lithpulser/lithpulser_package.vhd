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

package lithpulser_package is
    constant C_OUTPUTS : integer := 14;  --MAX 16
    constant C_SEQUENCES: integer := 16; --MAX 16
    constant C_EVENTS : integer := 128;   --MAX 2^11 / C_SEQUENCES
    constant C_SEQTIMEWIDTH : integer := 32; --MAX 32 => max Sequence Time interval 2^32 *1ns = 4.3 s
    constant C_GLOBTIMEWIDTH : integer := 52; --MAX 52 => max Global Time interval 2^52 *1ns = 7.4 weeks
    constant C_PULSECERWIDTH : integer := 26; --MAX 26 => max pulses to register 2^26 = 67 million
    
    type r_outputsequence is record
        o : std_logic_vector(C_OUTPUTS-1 downto 0);
        valid : std_logic;
    end record;

    constant outputsequence_reset : r_outputsequence := 
    (
        o => (others => '0'),
        valid => '0'
    );
    
    type a_outputsequence is array(0 to 7) of r_outputsequence;    
    type a_outputs is array (0 to 7) of std_logic_vector(C_OUTPUTS-1 downto 0);

    type r_mux is record
        o : std_logic_vector(C_OUTPUTS-1 downto 0);
        valid : std_logic;
        uselast : std_logic;
    end record;
    
    constant mux_reset : r_mux :=
    (
        o => (others => '0'),
        valid => '0',
        uselast => '1'
    );

    type a_mux is array (0 to 7) of r_mux;
    type aa_mux is array(0 to 9) of a_mux;
    
    type r_event is record 
        t : unsigned(C_SEQTIMEWIDTH-1 downto 0);
        o : std_logic_vector(C_OUTPUTS-1 downto 0);
    end record;
    
    constant event_reset : r_event :=
    (
        t => (others => '0'),
        o => (others => '0')
    );
    
    function event2slv (e : r_event) return std_logic_vector;
    function slv2event (slv : std_logic_vector) return r_event;
    function maxunsigend (N : integer) return unsigned;

    type tt is array (0 to 7) of unsigned(C_SEQTIMEWIDTH-1 downto 0);
    type a_seqcount is array (0 to 15) of unsigned(31 downto 0);   
    type a_seqtimout is array (0 to 15) of unsigned(C_SEQTIMEWIDTH-1 downto 0);   
     
    type r_ld is record
        st: unsigned(C_SEQTIMEWIDTH-1 downto 0);
        et: unsigned(C_SEQTIMEWIDTH-1 downto 0);
        minc: unsigned(C_PULSECERWIDTH-1 downto 0);
        maxc: unsigned(C_PULSECERWIDTH-1 downto 0);
    end record;
    
    constant ld_reset : r_ld := 
    (
        st => (others => '0'),
        et => (others => '0'),
        minc => (others => '0'),
        maxc => (others => '0')
    );    
    
    type a_ld is array (0 to 1) of r_ld;     

    type r_sequence is record 
        used: STD_LOGIC;
        rerun:  unsigned(C_SEQTIMEWIDTH-1 downto 0);
        length: unsigned(C_SEQTIMEWIDTH-1 downto 0);
        last_din: r_event;
        ldmode: unsigned(7 downto 0);
        lds: a_ld;
    end record;    

    type a_sequence is array (0 to 15) of r_sequence;
  
    constant sequence_reset : r_sequence := 
    (
        used => '0',
        rerun => (others => '0'),
        length => (others => '0'),
        last_din => event_reset,
        ldmode => (others => '0'),
        lds => (others => ld_reset)
    );  
      
      
    type t_state is (S_STOP,S_INIT,S_PRERUN1,S_PRERUN2,S_RUN,S_POSTRUN1,S_POSTRUN2 );
    
    type a_ldin is array (0 to 1) of std_logic_vector(5 downto 0);
    type a_ldcount is array (0 to 1) of unsigned(C_PULSECERWIDTH-1 downto 0);

    
    component lithpulser_matcher is port
    (
        clk : in std_logic;
        clear_all : in STD_LOGIC;
    
        --Memory interface
        mcs : in integer range 0 to C_SEQUENCES-1; --Sequenz Select 
        set : in STD_LOGIC;
        datain : in r_event;
        
        --Realtime events
        rcs : in integer range 0 to C_SEQUENCES-1; --Sequenz Select 
        run : in STD_LOGIC;
        t_in : in unsigned(C_SEQTIMEWIDTH-1 downto 0);
        o : out r_outputsequence    
    );
    end component;

   component lithpulser_mux port 
    ( 
        clk : in STD_LOGIC;
        resetn : in STD_LOGIC;
        resetout : in STD_LOGIC_VECTOR(C_OUTPUTS-1 downto 0);
        input : in a_outputsequence;
        output : out a_outputs
    );
    end component;

    --output driver
    component lithpulser_outddr port
    (
        input : in a_outputs;
        output : out std_logic_vector(C_OUTPUTS-1 downto 0);
        
        clk_in: in STD_LOGIC;
        rstn: in STD_LOGIC
    );
    end component;   
      
    component lithpulser is Port 
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
    end component   ;    
    
end package;

package body lithpulser_package is

    function event2slv (e : r_event) return std_logic_vector is
        variable slv : std_logic_vector(C_SEQTIMEWIDTH+C_OUTPUTS - 1 downto 0);
    begin
        slv :=  std_logic_vector(e.t) & e.o;
        return slv;
    end;
    
    function slv2event (slv : std_logic_vector) return r_event is
        variable e : r_event;
    begin
        e.t     := unsigned(slv(C_SEQTIMEWIDTH+C_OUTPUTS - 1 downto C_OUTPUTS));
        e.o     := slv(C_OUTPUTS - 1 downto  0);
        return e;
    end;

    function maxunsigend (N : integer) return unsigned is
        variable r : unsigned(N - 1 downto 0);    
    begin
        r := (others => '1');
        return r;
    end;

end package body;