### x86 embedded BIOS R3
Very compact (less than 8KB of ROM space) x86 BIOS for embedded systems, FPGA, and emulators.

Tested with a hardware:
* Original Intel 8086 CPU
* Harris 80286 CPU
* Intel 80386SX25 CPU
* Intel KU80386EX25 CPU
* Cyrix Cx486SLC-V25 CPU
* Texas Instruments TI486SXLC2-G50 CPU

Some board images could be found in the [pictures directory](pictures).

Tested with an emulators:
* Bochs 2.6.11 (require USE_ADDON_ROMS and USE_IDE_HDD in "config.inc" to use Bochs's Video BIOS and HDD)

![FPGA board with TI486](https://github.com/b-dmitry1/BIOS/blob/main/BoardTI486.jpg)

Tested with a software:
* MS-DOS 3.3, 4.0, 6.22
* Windows 1.0, 2.0, 3.1, 95
* Linux 0.01, 1.3.89
* Minix 1.x, 2.x
* Most of DOS/Windows software and games working good

### Compiling on Windows machine

* Use Netwide Assembler (https://www.nasm.us/) to compile the source code.
* Edit "config.inc" file to select features you need.
* Launch "\_make.bat" file to create binaries.

If your NASM location on disk is not "C:\nasm\nasm.exe" - please change the path to nasm.exe in "\_make.bat" file.

### Implemented functions and features
* Minimal initialization
* Minimal functionality ISRs 10h-1Ah
* Lower memory test with continuous mode to help debugging FPGA SDRAM controller
* Very compact Video BIOS
* Minimal SVGA functionality enough to run hi-res games like "Heroes Of Might and Magic" and "Transport Tycoon"
* Supports add-on ROM chips (see config.inc)
* BIOS disk hypercall for emulators
* SPI mode SD-card support on FPGA boards
* Very simplified USB HID device support for FPGA boards
* Good for a systems without video adapter
* Customizable SPI/USB drivers
* A20 line and PLL control (frequency multiplier for 486)

### Known issues
* No hardware detection / BIOS setup (to save ROM space)
* No extended memory test
* Int 13h (BIOS disk) supports only reset/read/write functions
* Internal video BIOS doesn't support printing text in graphic mode
* Video adapter initialization incomplete so will not work properly with a real VGA chips without OEM BIOS

