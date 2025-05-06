----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is

component  ripple_adder is
    Port ( A : in std_logic_vector (3 downto 0);
           B : in std_logic_vector (3 downto 0);
           Cin : in STD_LOGIC;
           S : out STD_LOGIC_VECTOR (3 downto 0);
           Cout : out STD_LOGIC);
end component  ripple_adder;

signal notB : std_logic_vector (7 downto 0);
signal BInAdder: std_logic_vector (7 downto 0);
signal carry : std_logic;
signal OrOp : std_logic_vector (7 downto 0);
signal finalCout : std_logic;
signal res: std_logic_vector (7 downto 0);
signal AndOp : std_logic_vector (7 downto 0);
signal Answer: std_logic_vector (7 downto 0); 

begin

    adderOne : ripple_adder
        port map( 
            A => i_A(3 downto 0),
            B => BInAdder (3 downto 0),
            Cin => i_op(0),
            Cout => carry,
            S => Answer(3 downto 0)
           );
    adderTwo : ripple_adder
        port map (
        A => i_A(7 downto 4),
        B => BInAdder (7 downto 4),
        Cin => carry,
        Cout => finalCout,
        S => Answer (7 downto 4)
        );
 
--concurent statements
--mux for b signal into adders
notB <= not i_B;
BInAdder <= i_B when i_op(0) = '0' else
            notB;


OrOp <= i_A or i_B;
AndOp <= i_A and i_B;
--reult
res <= OrOp when i_op(1 downto 0) = "11" else
            AndOp when i_op (1 downto 0) = "10" else
            Answer when i_op (1 downto 0) = "01" else
            Answer when i_op (1 downto 0) = "00" else
            Answer;
o_result <= res;

--flags
    --Negative
    o_flags(3) <= res(7);
    o_flags(2) <= '1' when Answer = "00000000" else
                   '0'; 
    o_flags(1) <= finalCout and (not i_op(1));
    o_flags(0) <= (not(i_op(0) xor (i_A(7) xor i_B(7)))) and (i_A(7) xor Answer(7)) and (not i_op(1));
end Behavioral;
