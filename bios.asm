cpu 8086

%include "config.inc"

%include "ioports.inc"


	org 0

[BITS 16]
image_start:

; BIOS parameter block
; Do not move!
%include "data\biosdata.asm"

	align 8
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Entry point
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
start:
	; For real 286+ CS register is normalized here
	; So address will be 0x000F0000 instead of 0xFFFF0000

	cli
	cld

	; If we have 386EX CPU we may need to program Chip Select Unit
	; as soon as possible
%include "drivers\chipselect.asm"

	; Setup segments
	mov ax, 0x40
	mov ds, ax

	; Check if this restart is just an exit from protected mode
	; and we need to resume execution of user program
	mov ax, [pmode_exit_cs]
	or ax, [pmode_exit_ip]
	jz normal_restart

	; TODO: Need to check NVRAM also for a protected mode exit flag

	; Zero values or the system will not restart properly
	mov word [pmode_exit_cs], 0
	mov word [pmode_exit_ip], 0

	; Resume execution in real mode	
	push word [pmode_exit_cs]
	push word [pmode_exit_ip]
	retf

normal_restart:

	; Send '1' to debug port to notify that BIOS and debug console both working
	mov al, '1'
	out DEBUG_UART, al

	; Setup stack
	xor ax, ax
	mov ss, ax
	mov sp, 0x400

	; Set FPGA / emulator video controller to text mode
	mov al, 3
	out PORT_VMODE, al

	; Set interrupt controller (PICs 8259) registers
%include "drivers\pic.asm"
	
	; Send '2' to debug port to notify that PIC initialized
	mov al, '2'
	out DEBUG_UART, al

	; Create an empty interrupt table
	xor ax, ax
	mov ds, ax
	mov es, ax
	xor di, di
	mov cx, 192
erase_ints2:
	mov ax, empty_int
	stosw
	mov ax, cs
	stosw
	loop erase_ints2

	; Fill used vectors
	mov [0x00 * 4], word int00
	mov [0x01 * 4], word int01
	mov [0x02 * 4], word int02
	mov [0x03 * 4], word int03
	mov [0x04 * 4], word int04
	mov [0x05 * 4], word int05
	mov [0x06 * 4], word int06
	mov [0x07 * 4], word int07
	mov [0x08 * 4], word int08
	mov [0x09 * 4], word int09
	mov [0x0A * 4], word empty_hw_int
	mov [0x0B * 4], word empty_hw_int
	mov [0x0C * 4], word int0c
	mov [0x0D * 4], word empty_hw_int
	mov [0x0E * 4], word empty_hw_int
	mov [0x0F * 4], word empty_hw_int
	mov [0x10 * 4], word int10
	mov [0x11 * 4], word int11
	mov [0x12 * 4], word int12
	mov [0x13 * 4], word int13
	mov [0x14 * 4], word int14
	mov [0x15 * 4], word int15
	mov [0x16 * 4], word int16
	mov [0x17 * 4], word int17
	mov [0x19 * 4], word int19
	mov [0x1A * 4], word int1a
	mov [0x1D * 4], word video_init_table
	mov [0x1E * 4], word int1e
	mov [0x41 * 4], word int41

	; Set CGA glyph table address
	mov [0x43 * 4 + 2], word 0xF000
	mov [0x43 * 4], word 0xFA6E

	; Copy BIOS data
	mov ax, 0x0000
	mov es, ax
	mov di, 0x400
	mov ax, cs
	mov ds, ax
	mov si, bios_data
	mov cx, 0x100 + bios_data_end - bios_data + 1
	rep movsb

	; Display 'R' on the left top corner of the screen
	mov ax, 0xB800
	mov ds, ax
	mov word [0], 0x0F00 + 'R'

	; Send '3' to debug port to notify that all going ok
	mov al, '3'
	out DEBUG_UART, al


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Before this point there were only writes to RAM                  ;
	; Now we should try to read                                        ;
	                                                                   ;
	; If your RAM controller is not working properly                   ;
	; or add-on ROM chips generate an error                            ;
	; you will see "123" in the debug console and 'R' in the left top  ;
	; corner of the screen and the system will hang or restart         ;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	; Check if we have additional BIOS chips
%if (USE_ADDON_ROMS == 1)
	mov ax, 0x40
	mov ds, ax
	mov word [bios_temp + 2], 0xC000
	mov word [bios_temp], 2
scan_roms:
	mov ax, [bios_temp + 2]
	mov es, ax
	cmp [es:0], word 0xAA55
	jnz no_rom
	call far [bios_temp]
no_rom:
	mov ax, 0x40
	mov ds, ax
	mov ax, 0x1000
	add [bios_temp + 2], ax
	cmp word [bios_temp + 2], 0xF000
	jnz scan_roms
%endif

	; Send '4' to debug port to notify that we are going to use
	; stack, interrupts and read from RAM
	mov al, '4'
	out DEBUG_UART, al

	; Set the text mode normal way	
	mov ax, 3
	int 0x10
	
	; Send '5' to debug port to notify that RAM is working properly
	mov al, '5'
	out DEBUG_UART, al

	mov al, 13
	out DEBUG_UART, al
	mov al, 10
	out DEBUG_UART, al

	; Display welcome message
	mov si, msg_reset
	call putsv

	; Enable A31..A20 lines
	call a20_enable

	; Check BIOS parameter block alignment
%if ((check_size - bios_data) != 0xA8)
%error BIOS parameter block data offset detected!
%endif

	; Initialize COM-port
	; mov ax, 0
	; int 0x14
                             
	mov al, 13
	call putchv
	mov al, 10
	call putchv



	; This is a good place to activate CPU's PLL to run at full speed
	; The memory test performed at the next step will help to check
	; system stability in a full speed mode
%if (ACTIVATE_PLL == 1)
%include "drivers\pll.asm"
	call pll_enable
%endif


%if (RAM_TEST == 1)
	; Perform 0 - 640 KB RAM test
	; Can be runned several times
	mov bp, 17171
begin_memory_test:
	push bp
	call memory_test
	pop bp
	add bp, 52371

%if (CONTINUOUS_RAM_TEST == 1)
	jmp begin_memory_test
%endif

	mov al, 13
	call putchv
	mov al, 10
	call putchv
%endif


	; Memory test OK, so now we can enable CPU's cache
%if (ENABLE_CACHE == 1)

%include "drivers\cache.asm"
	call cache_enable
%endif



	; Timer 1: 15 us / 0x12
	; We don't need old-style timer DRAM regeneration so will use default value
	mov al, 0x54
	out 0x43, al
	mov al, 0x12
	out 0x41, al
	mov al, 0x00
	out 0x41, al
	mov al, 0x40
	out 0x43, al

	; Timer 2: 1 ms / 0x4A9
	; Can be programmed to 2 or 4 KHz to produce loud beeps
	mov al, 0xB6
	out 0x43, al
	mov al, 0xA9
	out 0x42, al
	mov al, 0x04
	out 0x42, al
	mov al, 0x40
	out 0x43, al

	; Timer 0: 55 ms / 0xFFFF
	; System timer connected to IRQ0
	mov al, 0x36
	out 0x43, al
	mov al, 0
	out 0x40, al
	out 0x40, al


	; Ok, lets try to initialize FPGA's USB1 and USB2 for keyboard and mouse
%if (USE_COMPACT_FPGA_USB == 1)
	mov si, msg_usb1_init
	call putsv
	call usb1_init
	mov si, msg_ok
	call putsv
	mov si, msg_usb2_init
	call putsv
	call usb1_init
	mov si, msg_ok
	call putsv
%endif

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	mov ax, 0x0000
	mov es, ax

%if (RUN_ROM_BASIC == 1)
	jmp (0xF600):0
%endif


%if (CLEAR_HMA)
	; Need to clear HMA
	mov ax, 0xFFFF
	mov es, ax
	mov di, 0x10
	mov cx, 32768 - 8
	xor ax, ax
	rep stosw
%endif



%if (USE_SPI_SDCARD == 1)
	; Try to find and initialize SD-card
	call sd_init
%endif

	; If we reached this point -> we have disk and can boot now
	mov si, msg_bootsector
	call putsv

	; Load a very first sector from default boot drive
	xor ax, ax
	mov es, ax
	mov bx, 0x7C00
	mov ax, 0x201
	mov dx, BOOT_DRIVE
	mov cx, 1
	int 0x13

	xor ax, ax
	mov es, ax
	mov ds, ax

	; Display on screen first bytes and boot signature of the received data
	; If all ok you will see something like FA33C08E...55AA on screen
	; and in the debug console
	mov si, 0x7C00
	lodsb

	call print_hexv
	lodsb
	call print_hexv
	lodsb
	call print_hexv
	lodsb
	call print_hexv
	mov al, '.'
	call putchv
	mov al, '.'
	call putchv
	mov al, '.'
	call putchv
	mov si, 0x7DFE
	lodsb
	call print_hexv
	lodsb
	call print_hexv

	mov si, msg_crlf
	call putsv

	; Enable interrupts
	mov al, 0x20
	out 0x20, al
	sti

%if (LEAVE_A20_ENABLED != 1)
	; Disable A20
	call a20_disable
%endif

	; Set general register default values
	xor ax, ax
	xor bx, bx
	xor cx, cx
	mov dx, BOOT_DRIVE	; Boot drive code should be in DL
	xor si, si
	xor di, di
	xor bp, bp

	; Start OS
	jmp (0x0000):0x7C00

%include "console.asm"

%if (USE_COMPACT_FPGA_USB == 1)
%include "drivers\compact_fpga_usb.asm"
%include "drivers\compact_fpga_hid.asm"
%endif

; Memory test
; In:
;   BP - random value

%ifdef RAM_TEST
memory_test:
	mov si, msg_testingmemory
	call putsv

	cli

	xor di, di
	mov ds, di
	mov di, 0x800
	mov bx, bp
memory_test_fill:
	mov [di], bx
	add bx, 531
	add di, 2
	jnz memory_test_fill
	xor di, di
	mov ax, ds
	add ax, 0x1000
	mov ds, ax

	cmp ax, 0xA000
	jnz memory_test_fill

	xor di, di
	mov ds, di
	mov di, 0x800
	mov bx, bp
memory_test_cmp:
	cmp bx, [di]
	jne memory_test_fail
	add bx, 531
	add di, 2
	jnz memory_test_cmp

	mov ax, ds
	add ax, 0x1000
	mov ds, ax

	push bx
	push ds

	mov si, msg_testingmemory
	call putsv

	pop ds
	push ds

	mov ax, ds
	xor dx, dx
	mov bx, 64
	div bx
	call print_u16v

	mov si, msg_kbok
	call putsv

	pop ds
	pop bx

	mov ax, ds
	xor di, di
	cmp ax, 0xA000
	jnz memory_test_cmp

	ret

memory_test_fail:
	mov al, 'F'
	out DEBUG_UART, al
	mov si, msg_memorytestfailed
	call putsv
	cli
	jmp $
%endif

; Interrupt return with Z or C flag set/reset
iret_carry_on:
	stc
iret_carry:
	push bp
	mov bp, sp
	jnc iret_carry_off1
	or word [bp+6], 1
	pop bp
	iret
iret_carry_off1:
	and word [bp+6], 0xFFFE
	pop bp
	iret
iret_carry_off:
	clc
	jmp iret_carry

iret_zero:
	push bp
	mov bp, sp
	jnz iret_zero_off1
	or word [bp+6], 0x40
	pop bp
	iret
iret_zero_off1:
	and word [bp+6], 0xFFBF
	pop bp
	iret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Interrupts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

empty_hw_int:
	push ax
	mov al, 0x20
	out 0x20, al
	pop ax
	iret

empty_int:
	iret

%include "isr\traps.asm"

%include "isr\int08_timer.asm"
%include "isr\int09_keyboard.asm"
%include "isr\int0c_comm.asm"
%include "isr\int10_video.asm"
%include "isr\int11.asm"
%include "isr\int12.asm"
%include "isr\int13_disk.asm"
%include "isr\int14_comm.asm"
%include "isr\int15_at.asm"
%include "isr\int16_keyboard.asm"
%include "isr\int17.asm"
%include "isr\int19.asm"
%include "isr\int1a_rtc.asm"

; SPI controller for SD-card or W25Q128 flash ROM
%include "drivers\spi.asm"

; BIOS messages
msg_reset:
	db "x86 embedded BIOS R2", 13, 10, "github.com/b-dmitry1/BIOS", 13, 10, 0

msg_usb1_init:
	db "USB 1 init", 0

msg_usb2_init:
	db "USB 2 init", 0

msg_ok:
	db "OK", 13, 10, 0

msg_crlf:
	db 13, 10, 0

msg_testingmemory:
	db 13, "Testing RAM: ", 0

msg_memorytestfailed:
	db 13, 10, "RAM test FAILED", 13, 10, "System halted", 0

msg_kbok:
	db " KB OK   ", 0

msg_bootsector:
	db 13, 10, "Boot sector: ", 0

msg_failed:
	db 'failed', 0

msg_sd_init:
	db 13, 10, 13, 10, "HDD0: ", 0
msg_sd_init_error:
	db "not found", 13, 10, 0
msg_sd_init_mmc:
	db "MMC", 13, 10, 0
msg_sd_init_sdv1:
	db "SDv1", 13, 10, 0
msg_sd_init_sdv2:
	db "SDv2", 13, 10, 0

msg_sd_init_sdv2_block:
	db "SD mode: Block", 13, 10, 0

; Tables
int1e:
	db 0xDF ; Step rate 2ms, head unload time 240ms
	db 0x02 ; Head load time 4 ms, non-DMA mode 0
	db 0x25 ; Byte delay until motor turned off
	db 0x02 ; 512 bytes per sector
floppy_sectors_per_track:
	db 18	; 18 sectors per track (1.44MB)
	db 0x1B ; Gap between sectors for 3.5" floppy
	db 0xFF ; Data length (ignored)
	db 0x54 ; Gap length when formatting
	db 0xF6 ; Format filler byte
	db 0x0F ; Head settle time (1 ms)
	db 0x08 ; Motor start time in 1/8 seconds


video_static_table:
	; https://dos4gw.org/VGA_Static_Functionality_Table
	db 0x7f ; bits 0 .. 7 = modes 00h .. 07h supported
	db 0xff ; bits 0 .. 7 = modes 08h .. 0fh supported
	db 0x0f ; bits 0 .. 3 = modes 10h .. 13h supported
	dd 0 	; IBM reserved
	db 0x07 ; scan lines suppported: bit 0 = 200, 1 = 350, 2 = 400
	db 0x08 ; font blocks available in text mode (4 = EGA, 8 = VGA)
	db 0x02 ; maximum active font blocks in text mode (2 = EGA или VGA)
	db 0xfd ; misc support flags
	db 0x08	; misc capabilities (DCC support)
	dw 0x00 ; reserved
	db 0x3C	; save pointer function flags
	db 0x00 ; reserved 

video_init_table:
	; https://dos4gw.org/Video_Initialization_Table
abRegs40x25:
	db 0x39, 0x28, 0x2d, 0x10, 0x1f, 0x06, 0x19, 0x1c, 0x02, 0x07, 0x66, 0x07, 0x00, 0x00, 0x00, 0x00
abRegs80x25:
	db 0x72, 0x50, 0x5a, 0x10, 0x1f, 0x06, 0x19, 0x1c, 0x02, 0x07, 0x66, 0x07, 0x00, 0x00, 0x00, 0x00
abRegsGfx:
	db 0x39, 0x28, 0x2d, 0x10, 0x7f, 0x06, 0x64, 0x70, 0x02, 0x07, 0x06, 0x07, 0x00, 0x00, 0x00, 0x00
abRegsMono:
	db 0x72, 0x50, 0x5a, 0x10, 0x1f, 0x06, 0x19, 0x1c, 0x02, 0x07, 0x06, 0x07, 0x00, 0x00, 0x00, 0x00
	; wSize40x25
	dw 0x3E8
	; wSize80x25
	dw 0x7d0
	; wSizeLoRes
	dw 0x3e80
	; wSizeHiRes
	dw 0x3e80
	; abClmCnts (Text columns in each mode)
	db 0x28, 0x28, 0x50, 0x50, 0x28, 0x28, 0x50, 0x00
	; abModeCodes (port 3d8 values for each mode)
	db 0x0c, 0x08, 0x02, 0x09, 0x0a, 0x0e, 0x1a, 0x00 


%if (NO_CGA_GLYPHS != 1)
; CGA 8x8 font
; Do not move! Need to be placed in 0x1A6E
	times 0x1A6E - $ + image_start db 0x90

%include "data\cgafont.asm"

%endif

int41:
	; Hard disk parameter table
	; Hard-coded to save space
	; 203 * 16 * 63 * 512 = 104767488 bytes = 99.9 MB
hdd_cyls:
	dw HDD_CYLINDERS - 1	; Number of cyls minus 1
hdd_heads:
	db 15	; Number of heads minus 1
	dw 0
	dw 0
	db 0
	db 0xC0
	db 0
	db 0
	db 0
	dw 0
hdd_sectors:
	db 63	; Sectors per track
	db 0


	; Fill unused area with NOPs
	times 8192 - 16 - $ + image_start db 0x90

bootentry:
	jmp (0F000h):start
	db	"08/29/87"
	db	0x00
	db	0xFC		; Machine type (XT)
	db	0x55		; Checksum
