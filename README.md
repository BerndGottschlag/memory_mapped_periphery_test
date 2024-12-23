# Memory Mapped Periphery Test

This project implements a simple periphery element that can be connected to a host MCU via Serial Peripheral interface (SPI). I created it as a learning project to start learning VHDL and develop components to re-use in later projects.

The idea was to develop this example peripheral element based on internal components connected a Wishbone bus. There are three main components:

1. The SPI interface component that receives read and write commands from the host MCU and converts them to wishbone transactions.
2. A LED output component containing eight memory-mapped registers which control the state of one each of the user LEDs on the evaluation board.
3. A button input component containing four memory-mapped registers containing the state of one each of the user push buttons.

The project uses the [LatticeXP2 Brevia2 Development Kit ](https://www.latticesemi.com/products/developmentboardsandkits/latticexp2brevia2developmentkit) which is equipped with the LatticeXP2-5E 6TN144C FPGA. The design was developed using the [Lattice Diamond](https://www.latticesemi.com/en/Products/DesignSoftwareAndIP/FPGAandLDS/LatticeDiamond) tool version 3.14.

## Connection to the Host MCU

- SPI:
    - CS: J3-3 (Pin Number 103)
    - SCK: J3-4 (Pin Number 69)
    - MISO: J3-5 (Pin Number 102)
    - MOSI: J3-6 (Pin Number 66)
- Soft reset input (active low): J3-7 (Pin Number 101)

## License

This design is licensed under [CERN-OHL-W](https://ohwr.org/project/cernohl/-/wikis/Documents/CERN-OHL-version-2).

