
; CPU types
%define CPU_X86			0
%define CPU_386EX		1
%define CPU_CX486		2
%define CPU_TI486               3

; Set CPU type here
%define CPU			CPU_X86



; Extended RAM size in KB
%define EXT_RAM_SIZE		7168

; Set to 1 if you have OEM video BIOS or ROM BIOS extension chips
%define USE_ADDON_ROMS		0

; Set to 1 to enable RAM test
%define RAM_TEST		0

; Set to 1 to enable continuous RAM test to check system stability
%define CONTINUOUS_RAM_TEST	0

; Set to 1 if you have ROM Basic on 0xF6000 and wish to use it instead of OS
%define RUN_ROM_BASIC		0



; HDD cylinder count
; HDD size: HDD_CYLINDERS * 16 * 63 * 512 bytes
%define HDD_CYLINDERS		203

; Boot drive:
; 0x00 - drive A: (floppy 0)
; 0x80 - drive C: (HDD 0)
%define BOOT_DRIVE		0x80

; Set to enable disk BIOS hyper call
; Emulator use only! All int 13h code will be removed
%define HYPER_13H		1

; Set to enable IDE HDD controller
%define USE_IDE_HDD		0

; Set to 1 if SPI SD-card is used
%define USE_SPI_SDCARD		0

; Set to 1 to make disks read-only
%define DISKS_READONLY		0



; Set to 1 if zeroing of high memory area (0x100000-0x10FFF0) is needed
%define CLEAR_HMA		0

; Set to 1 if you need A20 enabled
; Some of old DOS packed EXEs will not work with A20 enabled
%define LEAVE_A20_ENABLED	1

; Set to 1 if you don't need cga glyphs
; This will save 1 KB of ROM
%define NO_CGA_GLYPHS		0



; Set to 1 if a very simple FPGA USB controller is used
%define USE_COMPACT_FPGA_USB	0



; Set to 1 if you don't need mouse report from FPGA USB controller
%define FPGA_USB_NO_MOUSE	0



; Set to 1 if your CPU contains PLL (clock multiplier)
; Please activate only if your system working good at normal speed
%define ACTIVATE_PLL		0


; Set to 1 if your CPU contains cache memory and you need to enable it
%define ENABLE_CACHE		0

