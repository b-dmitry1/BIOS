

; Video mode port for FPGA / emulator
%define PORT_VMODE		0xBE

; Blocking debug port
%define DEBUG_UART		0xBC

; Chip-select unit 80386EX
%define UCSADH			0xF43A
%define UCSADL			0xF438
%define UCSMSKH			0xF43E
%define UCSMSKL			0xF43C

; IO 80386EX
%define P1CFG			0xF820
%define P2CFG			0xF822
%define P3CFG			0xF824
%define P1LTC			0xF862

; Low speed USB (FPGA)
%define USB1			0xB4
%define USB2			0xB6
; Full speed USB (FPGA)
%define USB3			0xB8
%define USB4			0xBA
