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

### Compiling on a Windows machine

* Use Netwide Assembler (https://www.nasm.us/) to compile the source code.
* Edit "config.inc" file to select features you need.
* Launch "\_make.bat" file to create binaries.

If your NASM location on disk is not "C:\nasm\nasm.exe" - please change the path to nasm.exe in "\_make.bat" file.

### Compiling on a Linux machine

* Edit "config.inc" file to select features you need. Enable USE_DEBUG_UART if you want to test it in QEMU.
* In "config.inc" file set START_SEGMENT to 0xF000 and ROM_SIZE to 65536. QEMU requires 64 KB BIOS, and this will add 56 KB of empty space to your binary.
* Install nasm and qemu:
```
sudo apt update
sudo apt install nasm qemu-system-x86
```
* Compile BIOS with nasm:
```
nasm bios.asm
```
* Download and unzip freedos.img disk image from "e86r" project or use your own image.
* Run in QEMU:
```
qemu-system-i386 -bios bios -machine isapc -vga std -drive file=freedos.img,format=raw,bus=0,unit=0,media=disk
```
The font will look different than on a modern computers: this is because we are loading only first 128 CGA glyphs 8x8 to a 8x16 VGA glyph table.
The only way to load such a font is to stretch it vertically to double its size.
Complete 8x16 font requires 4 KB of ROM space and this is too expensive for this tiny BIOS.

If you want to test a serial port (COM1) output: in QEMU's "View" menu switch display to "serial0". There are should be a BIOS banner.

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
* QEMU's VGA adapter will only work in 0x03 (text, 16 color, 80x25 chars) and 0x13 (graphics, 256 color, 320x200) video modes due to palette and programming sequence issues in other modes.
