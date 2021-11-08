; SPI port driver for FPGA
;
; SPI controller algorythm:
; When CPU write a value to PORT_SPI_DATA port:
;   1. Shift the data out
;   2. Receive result and put it in the PORT_SPI_DATA (read) port
; When CPU write a value to PORT_SPI_CS port:
;   1. If bit 0 = 1 then activate CS
;   2. If bit 0 = 0 then deactivate CS
; When CPU write a value to PORT_SPI_DIV port:
;   1. Set an SPI frequency divisor value

; CS enable port
%define PORT_SPI_CS		0xB0
; Serial speed divisor port
%define PORT_SPI_DIV		0xB1
; Blocking data port
%define PORT_SPI_DATA		0xB2

; spi
; Shift-out user value and shift-in the result
; In:
;   AL = value
; Out:
;   AL = result
spi:
	out PORT_SPI_DATA, al
	in al, PORT_SPI_DATA
	ret

; spi_readbyte
; Shift-out empty value and shift-in the result
; In:
;   none
; Out:
;   AL = result
spi_readbyte:
	mov al, 0xFF
	out PORT_SPI_DATA, al
	in al, PORT_SPI_DATA
	ret

; spi_begin
; Selects the device on SPI bus
; In:
;   none
; Out:
;   none
spi_begin:
	push ax
	mov al, 0x01
	out PORT_SPI_CS, al
	pop ax
	ret

; spi_end
; Deselects the device on SPI bus
; In:
;   none
; Out:
;   none
spi_end:
	push ax
	mov al, 0x00
	out PORT_SPI_CS, al
	pop ax
	ret

; spi_slow
; Set slow SPI data rate
; In:
;   none
; Out:
;   none
spi_slow:
	mov al, 250
	out PORT_SPI_DIV, al
	ret

; spi_fast
; Set fast SPI data rate
; In:
;   none
; Out:
;   none
spi_fast:
	mov al, 5
	out PORT_SPI_DIV, al
	ret
