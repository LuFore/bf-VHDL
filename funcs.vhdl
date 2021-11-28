library ieee, work, std;
use ieee.std_logic_1164.all, ieee.numeric_std.all,
 work.defs.all, std.textio.all;

package funcs is 
function decode(inst:byte) return instruction;

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
