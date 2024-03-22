# sv_practice
Projects to work on as practice for writing SystemVerilog HDL!
## [SevSeg](SevSeg)
Implementing a module to use the 7 Segment Display from [1BitSQuared](https://1bitsquared.com/products/pmod-7-segment-display) on an Arty A7-35T.
## [spi](spi)
Simple implementation of a spi master with configurable CPOL and CPHA.

TODO:
- add spi receiver (slave)
## [utils](utils)
Various reusable components for FPGA development.
Utils include:
- Debouncer
- Monopulser
- Delay (currently called "counter"... should be changed to reflect this).

TODO:
## [oled](oled)
Simple test implementation of pmodOLEDRGB from Digilent. [Link to product page](https://digilent.com/shop/pmod-oledrgb-96-x-64-rgb-oled-display-with-16-bit-color-resolution/).

TODO:
- Make test image an option for synthesis at compile time.
- Implement a RAM to store rewritable data
- Implement frame buffer
- Implement internal frame clock
- Introduce modes for different color depth (8 bit vs. 16 bit color)
