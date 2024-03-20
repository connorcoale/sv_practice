set oled_root $env(OLED_ROOT)

read_verilog -sv $oled_root/src/oled_top.sv $oled_root/src/oled.sv $oled_root/../spi/src/spi_master.sv $oled_root/../utils/src/counter.sv $oled_root/../utils/src/debouncer.sv $oled_root/../utils/src/monopulser.sv

set_property generic "oled.TEST_IMAGE_ADDR=$oled_root/test_images/shrek.hex" [current_fileset]

read_xdc $oled_root/xdc/Arty-A7-35.xdc

synth_design -top oled_top -part xc7a35ticsg324-1L

opt_design
place_design
route_design

write_bitstream -force oled.bit
