### x86 embedded BIOS
Very compact (less than 8KB of ROM space) x86 BIOS for embedded systems, FPGA and emulators.

Tested with hardware:
* Original Intel 8086 CPU
* Harris 80286 CPU
* Intel 80386SX25 CPU
* Intel KU80386EX25 CPU
* Cyrix Cx486SLC-V25 CPU
* Texas Instruments TI486SXLC2-G50 CPU

![FPGA board with TI486](https://github.com/b-dmitry1/BIOS/blob/main/BoardTI486.jpg)

Tested with software:
* MS-DOS 3.3, 4.0, 6.6
* Windows 1.0, 2.0, 3.1, 95
* Linux 0.01, 1.3.89
* Minix 1.x, 2.x
* Most of DOS software and games working good

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
* Support add-on ROM chips (see config.inc)
* BIOS disk hypercall for emulators
* SPI mode SD-card support on FPGA boards
* Very simplified USB HID device support on FPGA boards

### Known problems
* No 32-bit functions
* No extended memory test
* Due to very incomplete realization of int 15h some PC diagnostic programs will show memory size error
* Int 13h (BIOS disk) supports only reset/read/write functions
* No NVRAM/RTC support
* Internal video BIOS doesn't support printing chars in graphic mode
* Video adapter initialization incomplete so will not work properly with real VGA chips without OEM BIOS
* No SMM mode so 32-bit software cannot use FPGA SD-card and USB controller
