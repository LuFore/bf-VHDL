library ieee, work, std;
use ieee.std_logic_1164.all, ieee.numeric_std.all,
 work.defs.all, std.textio.all;

package funcs is 
function decode(inst:byte) return instruction;

--procedure PC_logic(inst:in instruction;
--                   hcounter, tcounter: inout integer;
--                   hstack, tstack: in std_ulogic_vector;
--                   dat :in data;      
--                   tpush,tpop,hpush,hpop:out std_ulogic;
--                   search:inout std_logic;
--                   PC:inout PC_type);

function add(vect:std_ulogic_vector;int:integer)
	return std_ulogic_vector;
procedure rstlogic(signal vect:inout std_ulogic_vector);

procedure read_bf_file(file_in: in string;
                       signal ret:out word_array;
											 signal inst_no: out integer);
	--an error from here probably means you don't have enough instructions
	--or you are putting malformed stuff in
	--ret is the contents of the file 
	--inst_no is the number of instructions found

end package;


package body funcs is

function decode(inst:byte) return instruction is
begin
	case to_integer(unsigned(inst))is
	--ASCII values for each control character
		when 62 => return ptr_inc;
		when 60 => return ptr_dec;
		when 43 => return dat_inc;
		when 45 => return dat_dec;
		when 44 => return inp;
		when 46 => return oup;
		when 91 => return head;
		when 93 => return tail;
		when others => return NA;
	end case;
end decode;

----Control the Program counter
--procedure PC_logic(inst:in instruction;
--                   hcounter, tcounter: inout integer;
--                   hstack, tstack: in std_ulogic_vector;
--                   dat :in data;      
--                   tpush,tpop,hpush,hpop:out std_ulogic;
--                   search:inout std_logic;
--                   PC:inout PC_type)is
----h & t counter are for counting number of heads & tails in a
---- 'search' block (unkown jump to ])
----h & t stack are stacks for storing locations of [ and ]
---- for quick jumping too and from (maybe make funciton to 
---- deal when they are full? slow search backwards)
---- dat is for data currently being read
---- t & h pop and push are for popping and pushing into 
---- the above stacks
--begin
--	case inst is 
--	when head=>
--		--searching for matching ], skip past [
--		if search = '1' then
--			PC:=add(PC,1);
--			hcounter := hcounter + 1;
--		
--		elsif signed(dat) = 0 then --jump needed
--			if unsigned(hstack) < unsigned(tstack) then
--			--find if matching ] is on stack
--			--Given the way ] is searched for only the next
--			-- ] may be on the stack at any given time
--				PC := add(tstack,1);
--			end if;
--		else --no jump needed
--			PC := add(PC,1);
--			if to_integer(unsigned(PC))
--				 /= to_integer(unsigned(hstack)) then
--				hpush := '1';
--			end if;
--		end if;
--	when tail=>
--		if search = '1' then
--			PC := add(PC,1);
--			--search complete when brackets match
--			if hcounter = tcounter then
--				search:= '0';
--				hcounter:= 0;
--				tcounter:= 0;
--			else --brackets don't match
--				tcounter := tcounter + 1;
--			end if;
--		else --Will always jump back to last [ 
--			PC := hstack;
--			--if first jump from here, store jump location
--			if tstack /= PC then
--				tstack := PC;
--			end if;
--		end if;
--	when others =>
--		PC := add(PC,1);
--		tpush := '0';
--		tpop  := '0';
--		hpush := '0';
--		hpop  := '0';
--	end case;
--end PC_logic;             



--This *was* all unsigned, now changed
function add(vect:std_ulogic_vector;int:integer)
	return std_ulogic_vector is
--Add a logic vecotr(unsigned) and an integer allowing for overflow
--convert back to std_ulogic from integer
	constant temp:std_ulogic_Vector :=
	std_ulogic_vector(to_signed( --convert back to ulog from int
	to_integer(signed(vect))+int, --convert to integer and add int
	vect'length+1)); --add an additional bit to allow for overflow
begin
--for i in vect'range loop
--report std_ulogic'image(vect(i));
--end loop;
	
--	report 
--		integer'image(to_integer(unsigned(vect))) & " + " & integer'image(int)&
--		" = " & integer'image(to_integer(unsigned(temp)));
	--move this stuff up to constant
	return temp(vect'range); --return a logic vector of the same size
end add;

procedure rstlogic(signal vect:inout std_ulogic_vector) is
begin
	vect <= (others => '0');
end rstlogic;

procedure read_bf_file(file_in: in string;
                       signal ret:out word_array;
											 signal inst_no: out integer)is
	variable r : word_array(instruction_max-1 downto 0);
	file     f : text open read_mode is file_in;
	variable l : line;
	variable c : integer := 0;
	variable s : string(1 to instruction_max);
	variable m : natural;
	--Not very clever, but should be able to fit the theoretical
	--most compact bf file, will error if total chars on line < inst_max
	function word_t(int:integer) return word is 
	begin
		return std_ulogic_vector(to_unsigned(int, word'length));
	end word_t;

begin
	loop
		exit when endfile(f);
		readline(f,l);
		m := l'length; --store for when l is cleared when read 
		read(l,s(l'range));
		report "Code being converted: " & s;
		for i in 1 to m loop
			case s(i) is
			--character'pos would also work,
			--but would have to manually check anyway so this is better
			when '>' => r(c) := word_t(62); 	
			when '<' => r(c) := word_t(60);
			when '+' => r(c) := word_t(43);
			when '-' => r(c) := word_t(45);
			when '.' => r(c) := word_t(46);
			when ',' => r(c) := word_t(44);
			when '[' => r(c) := word_t(91);
			when ']' => r(c) := word_t(93);
			when others => c := c - 1; --cancel out future instrucion increase then
			--skip past char
			end case;
			c := c + 1; --assume a correct instruction
		end loop;
	end loop;
	
	--clean up unused instruction space for simulation
	for i in c to instruction_max-1 loop 
		r(i) := (others => '0');
	end loop;
	ret <= r;
	inst_no <= c;
end read_bf_file;
end package body;
