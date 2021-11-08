

; Extended RAM size in KB
%define EXT_RAM_SIZE		7168

; Set to 1 if you have OEM video BIOS
%define USE_OEM_VIDEO		0

; HDD cylinder count
; HDD size: HDD_CYLINDERS * 16 * 63 * 512 bytes
%define HDD_CYLINDERS		203

; Boot drive:
; 0x00 - drive A: (floppy 0)
; 0x80 - drive C: (HDD 0)
%define BOOT_DRIVE		0x80

; Set to enable disk BIOS hyper call
; Emulator use only!
%define HYPER_13H		0

; Set to 1 to enable RAM test
%define RAM_TEST		1

; Set to 1 to enable continuous RAM test to check system stability
%define CONTINUOUS_RAM_TEST	0

; Set to 1 if SPI SD-card is used
%define USE_SPI_SDCARD		0

; Set to 1 to make disks read-only
%define DISKS_READONLY		0

; Set to 1 if zeroing of high memory area (0x100000-0x10FFF0) is needed
%define CLEAR_HMA		0

; Set to 1 if you need A20 enabled
%define LEAVE_A20_ENABLED	1

; Set to 1 if a very simple FPGA USB controller is used
%define USE_COMPACT_FPGA_USB	0

; Set to 1 if you don't need mouse report from FPGA USB controller
%define FPGA_USB_NO_MOUSE	0

; Set to 1 if you don't need cga glyphs
; This will save 1 KB of ROM
%define NO_CGA_GLYPHS		0
