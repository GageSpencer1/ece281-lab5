----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
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

entity controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is

    type sm_states is (s_clear, s_operand1, s_operand2, s_operation);
    
    signal f_Q, f_Q_next: sm_states;
begin
    -- CONCURRENT STATEMENTS ----------------------------
    
	-- Next state logic

    f_Q_next <= s_operand1 when (f_Q = s_clear and i_adv = '1' and i_reset = '0') else
	            s_operand2 when (f_Q = s_operand1 and i_adv = '1' and i_reset = '0') else
	            s_operation when (f_Q = s_operand2 and i_adv = '1' and i_reset = '0')  else
	            s_clear when (f_Q = s_operation and i_adv = '1' and i_reset = '0') or (i_reset = '1') else
	            f_Q; 
	          
    with f_Q select
        o_cycle <= "0001" when s_operand1,
                   "0010" when s_operand2,
                   "0100" when s_operation,
                   "1000" when s_clear,
                   "1000" when others;
	
    state_register : process(i_adv, i_reset)
	begin
        if rising_edge (i_adv) then
           if i_reset = '1' then
               f_Q <= s_clear;
           else
                f_Q <= f_Q_next;
            end if;
        end if;
	end process state_register;
end FSM;
