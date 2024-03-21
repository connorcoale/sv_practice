TOOL_FLAGS = -nojournal -nolog
TOOL = vivado $(TOOL_FLAGS)
SYN_TOOL = $(TOOL)
FLASH_TOOL = $(TOOL)

SOURCES = ${OLED_ROOT}/src/oled_top.sv ${OLED_ROOT}/src/oled.sv
DEPS = ${OLED_ROOT}/../utils/src/counter.sv ${OLED_ROOT}/../utils/src/debouncer.sv ${OLED_ROOT}/../utils/src/monopulser.sv ${OLED_ROOT}/../spi/src/spi_master.sv

SIM_RESDIR = ${OLED_ROOT}/out/verilated
SIM_TOP = oled_top_tb
SIM_TOP_FILE = ${OLED_ROOT}/tb/$(SIM_TOP).sv
SIM_DUT = ${OLED_ROOT}/src/oled.f
SIM_FLAGS = --binary -j 0 -Wno-lint --trace -Mdir $(SIM_RESDIR)
SIM_TOOL = verilator

TB_SOURCES = $(SIM_TOP_FILE)
TB_DEPS =

compile: $(SOURCES) $(DEPS)
	$(SYN_TOOL) -mode batch -source ${OLED_ROOT}/compile.tcl

.PHONY: clean run_sim compile_sim flash

flash:
	$(FLASH_TOOL) -mode batch -source ${OLED_ROOT}/flash.tcl

compile_sim: $(SOURCES) $(DEPS) $(TB_SOURCES) $(TB_DEPS)
	$(SIM_TOOL) $(SIM_FLAGS) $(SIM_TOP_FILE) -f $(SIM_DUT) -pvalue+TB_IMAGE_ADDR='"${OLED_ROOT}/test_images/shrek.hex"'

run_sim:
	$(SIM_RESDIR)/V$(SIM_TOP)
	mv trace.vcd tb/trace/trace.vcd

clean:
	rm -f out/verilated/* clockInfo.txt
