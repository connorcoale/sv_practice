SOURCES = ${OLED_ROOT}/src/oled_top.sv ${OLED_ROOT}/src/oled.sv ${OLED_ROOT}/../spi/src/spi_master.sv

DEPS = ${OLED_ROOT}/../utils/src/counter.sv ${OLED_ROOT}/../utils/src/debouncer.sv ${OLED_ROOT}/../utils/src/monopulser.sv

TB_SOURCES = ${OLED_ROOT}/tb/oled_top_tb.sv

TOOL_OPT = -nojournal -nolog
TOOL = vivado $(SYN_OPT)
SYN_TOOL = $(TOOL)
FLASH_TOOL = $(TOOL)


compile: $(SOURCES) $(DEPS)
	$(SYN_TOOL) -mode batch -source ${OLED_ROOT}/compile.tcl
flash: ${OLED_ROOT}/out/oled.bit
	$(FLASH_TOOL) -mode batch -source ${OLED_ROOT}/flash.tcl
# clean:
# sim:
