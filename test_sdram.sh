

iverilog -o output_sdram.vpp sdram_controller.v sdram_controller_tb.v
vvp output_sdram.vpp
