--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        btnL    :   in std_logic; 
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals


component sevenseg_decoder is
   port ( i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
           o_seg_n : out STD_LOGIC_VECTOR (6 downto 0));
end component sevenseg_decoder;

 
component ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end component ALU;

component TDM4 is
	generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
    Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	);
end component TDM4;

component clock_divider is
	generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
											   -- Effectively, you divide the clk double this 
											   -- number (e.g., k_DIV := 2 --> clock divider of 4)
	port ( 	i_clk    : in std_logic;
			i_reset  : in std_logic;		   -- asynchronous
			o_clk    : out std_logic		   -- divided (slow) clock
	);
end component clock_divider;

component  controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end component controller_fsm;

component twos_comp is
    port (
        i_bin: in std_logic_vector(7 downto 0);
        o_sign: out std_logic;
        o_hund: out std_logic_vector(3 downto 0);
        o_tens: out std_logic_vector(3 downto 0);
        o_ones: out std_logic_vector(3 downto 0)
    );
end component twos_comp;
        
      signal ALUResult: std_logic_vector  (7 downto 0);
      signal A: std_logic_vector (7 downto 0);
      signal B: std_logic_vector (7 downto 0);
      signal cycle: std_logic_vector (3 downto 0);
      signal flags: std_logic_vector  (3 downto 0);
      signal muxDisp: std_logic_vector (7 downto 0);
      signal Op: std_logic_vector (2 downto 0);
      signal reg1: std_logic_vector (7 downto 0);
      signal reg2: std_logic_vector (7 downto 0);
      signal sign: std_logic_vector (6 downto 0);
      signal SegDecoder: std_logic_vector (6 downto 0);
      signal TDMClk: std_logic;
      signal TDMData: std_logic_vector (3 downto 0);
      signal TDMSelect: std_logic_vector (3 downto 0);
      signal twosSign: std_logic;
      signal twosHund: std_logic_vector (3 downto 0);
      signal twosTens: std_logic_vector (3 downto 0);
      signal twosOnes: std_logic_vector (3 downto 0);
     
      
begin
	-- PORT MAPS ----------------------------------------
	twosComp : twos_comp
        port map (
        o_hund => twosHund,
        o_tens => twosTens,
        o_sign => twosSign,
        i_bin => muxDisp,
        o_ones => twosOnes
        );
    controllerFSM : controller_fsm
        port map (
        i_adv => btnC,
        i_reset => btnU,
        o_cycle => cycle
        );      
    TDM : TDM4
        port map (
        i_clk => TDMClk,
        i_reset => btnU,
        o_data => TDMData,
        o_sel => TDMSelect,
        i_D3 => "0000",
        i_D2 => twosHund,
        i_D1 => twosTens,
        i_D0 => twosOnes
        );
        TDMClock : clock_divider
        port map (
        i_clk => clk,
        i_reset => btnL,
        o_clk => TDMClk
        );
    finalSeg: sevenseg_decoder
        port map ( 
        i_hex => TDMData,
        o_seg_n => SegDecoder
        );
    register1 : process(cycle(0))
	begin
		if rising_edge (cycle(0))then
			reg1 <= A;
		else 
		    reg1 <= reg1;
		end if;
	end process register1;
	
	register2 : process(cycle(1))
	begin
		if rising_edge (cycle(1)) then
			reg2 <= B;
		else 
		    reg2 <= reg2;
		end if;
	end process register2;
	
	operator: ALU
	    port map (
	    i_A => reg1,
        i_B => reg2,
        i_op => Op,
        o_result => ALUResult,
        o_flags => flags
	    );
	--input wires
	A <= sw(7 downto 0);
	B <= sw( 7 downto 0);
	Op <= sw( 2 downto 0);
	
	
	-- change anodes when clear stat e    
	an <= "1111" when cycle = "1000" else
	      TDMSelect;
	--neg sign
	sign(6) <= not twosSign;
	sign(5 downto 0) <= "111111";
    --display mux
	muxDisp <= reg1 when cycle = "0001" else
	              reg2 when cycle = "0010" else
	              ALUResult when cycle = "0100" else
	              ALUResult;
	seg <= sign when TDMSelect = "0111" else --seg mux
	       SegDecoder;

    led (15 downto 12) <= flags; --flags
	led(11 downto 4) <= "00000000"; --ground
    led(3 downto 0) <= cycle; --cycle
end top_basys3_arch;
