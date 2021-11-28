#!/bin/bash

ghdl -a defs.vhdl funcs.vhdl hw.vhdl tb.vhdl &&
ghdl -e bf_cpu  &&
ghdl -e bf_cpu_tb &&
ghdl -r bf_cpu_tb --wave="hello_world.ghw" &&
gtkwave hello_world.ghw
