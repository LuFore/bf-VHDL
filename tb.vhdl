library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all,
    work.funcs.all;

entity bf_cpu_tb is 
end bf_cpu_tb;

architecture tb of bf_cpu_tb is 
component bf_cpu is
  port(
    signal clk, rst, stall:in std_ulogic;
    --clk, rst are standard programming is set to rst 
    --polarity when a new program is being clocked into 
    --CPU. Stall holds the state of the CPU
    signal chan_in : in word; --Data from , goes here
    signal chan_out:out word; --Data from . goes here
 		signal active_output :out std_ulogic;
		signal inst_memory :in word_array(instruction_max-1 downto 0);
		signal PC_expose : out PC_type);
end component;

	signal clk, rst, stall: std_ulogic;
  signal chan_in : word; --Data from , goes here
  signal chan_out: word; --Data from . goes here
  signal inst_memory : word_array(instruction_max-1 downto 0);
	signal active_output : std_ulogic;
	signal PC_expose: PC_type;
	
	constant tbperoid : time := 1000 ns; --any time, this is just for fun
	signal tbclk      : std_ulogic := '0';
	signal tbsimend   : std_ulogic := '0';
	signal PC_stop    : natural;
begin

	dut : bf_cpu
	port map(
		clk => clk, rst => rst, stall => stall,
		chan_in => chan_in,
		chan_out=> chan_out,
		active_output => active_output,
		inst_memory => inst_memory,
		PC_expose => PC_expose);
--	--clock gen
		tbclk <= not tbclk after tbperoid/2 when tbsimend /= '1' else '0';
		clk <= tbclk;
	stim: process 
	begin
	--init
		stall <= '0';
		rstlogic(chan_in);
		read_bf_file("assembly/testjumps.bf",inst_memory,PC_stop); --copy bf file to memory
		rst <= reset_polarity;
		--clock in reset	
		wait for tbperoid*2;
		rst <= not reset_polarity;

--stop simulation when the program counter is larger than the no of instructions.
		while PC_stop-1 >= to_integer(unsigned(pc_expose)) loop
			if active_output = '1' then 
				report "Output from machine: "& integer'image(to_integer(unsigned(chan_out)));
			end if;
			wait for tbperoid;
		end loop;
		tbsimend <= '1';
		wait;

	end process;
end architecture;
