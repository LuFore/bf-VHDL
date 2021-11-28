library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

package defs is

--edit these to change parts of CPU
	constant word_size : positive := 8; --8 bits
	constant instruction_max: positive := 300;
	--maximum number of instructions allowed
	constant mem_size: positive := 30000; 
		--30k is standard brainfuck
	constant reset_polarity: std_ulogic := '1';
	--'1' is reset on high, '0' is reset on low
	constant loop_depth : positive := 10;
	--possible depth of [ and ]s 
	--(Depth = 1 is [], depth = 2 is [[]] and so on..)

--Do not edit below here, mostly types derived from
--above constants
	constant mem_ptr_size : positive :=
		positive(ceil(log2(real(mem_size))));
 	subtype byte is 
		std_ulogic_vector(7 downto 0);
	subtype mem_ptr is 
		std_ulogic_Vector(mem_ptr_size -1 downto 0);
	subtype word is
		std_ulogic_vector(word_size - 1 downto 0);
	subtype PC_type is 
		std_ulogic_Vector(positive(ceil(log2(real(instruction_max))))-1
			downto 0);
	type loopstack is array(0 to loop_depth-1)of PC_type;
	subtype loopstackptr is std_ulogic_vector(positive(ceil(
		log2(real(loop_depth))))-1 downto 0);
	
	type word_array is array(natural range <>) of word;
	type inst_array is array(natural range <>) of word;



	type instruction is (NA, ptr_inc, ptr_dec, dat_inc, dat_dec,
		inp, oup, head, tail);
	--><+-.,[]
end package;
