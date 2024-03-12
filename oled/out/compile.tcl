read_verilog -sv ../src/oled_top.sv ../../spi/src/spi_master.sv ../../utils/src/counter.sv ../../utils/src/debouncer.sv ../../utils/src/monopulser.sv

read_xdc ../xdc/Arty-A7-35.xdc

synth_design -top oled_top -part xc7a35ticsg324-1L

opt_design
place_design
route_design

write_bitstream -force oled.bit
