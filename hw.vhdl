library work;
library ieee;

use work.defs.all,
    work.funcs.all,
		ieee.std_logic_1164.all,
		ieee.numeric_std.all;

entity bf_cpu is 
	port(
		signal clk, rst, stall:in std_ulogic;
		--clk, rst are standard programming is set to rst 
		--polarity when a new program is being clocked into 
		--CPU. Stall holds the state of the CPU
		signal chan_in : in word; --Data from , goes here
		signal chan_out:out word; --Data from . goes here
		signal active_output : out std_ulogic; --high when valid output
		--currently used to store all instructions, may change this later
		signal inst_memory :in word_array(instruction_max-1 downto 0);
		signal PC_expose : out PC_type --For TB only
		-- Used to know when to stop the simulation
	);
end entity;

--Improvements
--Make all [] control use spare inst_memory space
--exception handling (error register+output+rst?)

architecture bf_cpu_arch of bf_cpu is 
--registers

--Main memory
signal data_memory : word_array(mem_size -1 downto 0);
--Instruction memory,moved outside block
--signal inst_memory : word_array(instruction_max-1 downto 0);
--Program counter
signal PC          : PC_type;
--Pointer for the data
signal data_ptr    : mem_ptr;
--Stores state if looking for an unkown ]
signal search      : std_ulogic ;
--Store location of latest [ and ] for quick jumping on complete
signal headstack   : loopstack;
signal hsptr       : loopstackptr;
signal tail_ptr    : PC_type; --location of end of current loop

--Counter for searching for [], to check they match
--Clean this up to use spair address space
signal hcounter 	 : std_ulogic_vector(31 downto 0);
signal tcounter    : std_ulogic_vector(31 downto 0);

 begin
	process(clk)
		variable inst : instruction;
		constant cdata: word := data_memory(to_integer(unsigned(data_ptr)));
	begin
	if rst = reset_polarity then
		rstlogic(hsptr);
		--rst first value of stack as this may be compared
		rstlogic(headstack(0));
		rstlogic(tail_ptr);
		rstlogic(hcounter);
		rstlogic(PC);
		rstlogic(data_ptr);
		rstlogic(tcounter);
		chan_out <= (others => '0');
		search <= '0';
		for i in data_memory'range loop
			data_memory(i) <= (others => '0');
		end loop;
	elsif rising_edge(clk) and stall = '0' then
		--decode instruction
		inst := decode(inst_memory(to_integer(unsigned(PC))));
--		report "PC = "&integer'image(to_integer(unsigned(PC)));
--		report "Encoded Instruction: " &
--		integer'image(to_integer(unsigned(inst_memory(to_integer(unsigned(PC))))))
--		& " Decoded Instruction: " & 
--		instruction'image(inst);
		PC <= add(PC,1); -- increment PC
		active_output <= '0'; --no output by defeault 
		if search = '0' then 
			case inst is 
			--malformed instruction
			when NA =>	null; --throw error (do this in future)
			when ptr_inc =>	data_ptr <= add(data_ptr, 1);   -- > overflow error 
			when ptr_dec => data_ptr <= add(data_ptr,-1);   -- < on all of these
			when dat_inc => data_memory(to_integer(unsigned(data_ptr)))
				<= add(data_memory(to_integer(unsigned(data_ptr))),1);  -- + ones
			when dat_dec =>  data_memory(to_integer(unsigned(data_ptr)))
				<= add(data_memory(to_integer(unsigned(data_ptr))),-1); -- - to here
			when inp     =>	data_memory(to_integer(unsigned(data_ptr)))
				<= chan_in;       -- , input 
			when oup     => chan_out -- . output
				<= data_memory(to_integer(unsigned(data_ptr)));
				active_output <= '1';
			when head    =>  -- [ this has lots of control and special cases
			--find if jump needed 
			if unsigned(data_memory(to_integer(unsigned(data_ptr)))) = 0 then 	
				--jump needed
				--find if matching ] is already on stack, by finding if current ]
				--happens after current [ (this will always work, unless malformed)
				if unsigned(headstack(to_integer(unsigned(hsptr)))) < 
					 unsigned(tail_ptr) then 
					 --make this hstack mess into alias
					 --jump to 1 after next ]
					PC <= add(tail_ptr,1);
					--decrement stacks, popping values off top
					hsptr <= add(hsptr,-1);
					tail_ptr <= (others => '0'); --reset tailpointer
				else
					--start search mode to look for next ] without executing instrucitons
					search <= '1';
				end if;
			else --jump not needed
				--find if not already on stack
				-- current matching [ ] will always be on top of stack
				if headstack(to_integer(unsigned(hsptr))) /= PC then 
					hsptr <= add(hsptr,1);
					headstack(to_integer(unsigned(add(hsptr,1)))) <= PC;
				end if;
			end if;
			when tail => -- ] 
				--check if location of ] is currently held in register
				if tail_ptr /= PC then 
					--not held in register so it will be added
					tail_ptr <= PC;
				end if;
				--Jump back to current matching [ (head)
				PC <= headstack(to_integer(unsigned(hsptr)));
			end case;
		elsif inst = head then 
			hcounter <= add(hcounter,1);
		elsif inst = tail then
			if tcounter = hcounter then 
				--find ] matches [
				--because [ counter is 1 offset and addition is only performed after
				--process (it's a signal) this will always match,
				--unless using malformed code
				search <= '0'; -- the search is over, the matching bracket is found
				--reset counters back to 0
				rstlogic(hcounter);
				rstlogic(tcounter);
			else	
				tcounter <= add(tcounter,1); -- improve with error catching
			end if;
		end if;
	end if;
	end process;
 PC_expose <= PC; 
 --for TB purposes, so that TB knows when to end
end architecture;
