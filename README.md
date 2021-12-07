# bf-VHDL
A VHDL implementation of brainfuck

# Running a program
In order to simulate run run.sh. ghdl is quired for simulation and gtkwave is needed to view the waveform files generated by ghdl.
In order to run your own brainfuck programs save them to the assembly directory then edit line 55 of tb.vhdl in order to read the name of the assembly file to be run.

# Editing parameters 
Parameters for this can be edited in defs.vhdl such as word size, the maximum instructions that can be saved and the length of the data array.
This uses a stack to store \[ locations in memory, this stack size is changed by loop_depth in defs.vhdl so can only handle limited number of active \['s at a time. by default this is 10 so although legal brainfuck this is not allowed.
