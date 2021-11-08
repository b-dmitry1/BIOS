; Simple USB driver for 2-port FPGA USB controller
;
; USB controller algorythm:
; If port state == "no device"
;   1. Wait until device connection detected on the bus (D+ or D- go high)
;   2. Wait 500 ms (debounce)
;   3. Send RESET command to the device (both lines low for 20 ms)
;   4. Set port state to "connected"
; If port state == "connected"
;   1. If the device is removed set port state to "no device"
;   2. For low-speed device: each 1000 us send EOP to the device
;   3. For full-speed device: each 125 us send SOF to the device
; If port state == "transmit"
;   1. If there are no data queued then send EOP and set state to "receive" and start receive timer
;   2. If there are some data in queue then send it
; If port state == "receive"
;   1. If receive timer expired then set state to "connected"
;   2. Check the line for a new data and put it into the receive queue
; When any data written to USB1/USB2 port:
;   1. If port state == "transmit" or "connected" or "receive" then put the data into queue and set port state to "transmit"
;   2. Otherwise ignore the data
; When CPU trying to read a value from USB1/USB2 port:
;   1. If port state == "receive" then wait for a new data in the receive queue and return it
;   2. Otherwise return some incorrect value like 0xFFFF

; usb1_send
; Sends a packet to USB1
; In:
;   CS:SI = message address, first byte = count
; Out:
;   none
usb1_send:
	mov cl, [cs:si]
	inc si
	xor ch, ch
usb1_send1:
	mov ax, [cs:si]
	add si, 2
	out USB1, ax
	loop usb1_send1
	mov cx, 20
	loop $
	ret

; usb1_recv
; Receives a 16-bit value from USB1
; In:
;   none
; Out:
;   AX = received value
usb1_recv:
	in ax, USB1
	ret

; usb2_send
; Sends a packet to USB2
; In:
;   CS:SI = message address, first byte = count
; Out:
;   none
usb2_send:
	mov cl, [cs:si]
	inc si
	xor ch, ch
usb2_send1:
	mov ax, [cs:si]
	add si, 2
	out USB2, ax
	loop usb2_send1
	mov cx, 20
	loop $
	ret

; usb2_recv
; Receives a 16-bit value from USB2
; In:
;   none
; Out:
;   AX = received value
usb2_recv:
	in ax, USB2
	ret

; usb_wait
; Used to add a small delay between USB packets
; In:
;   none
; Out:
;   none
usb_wait:
	push cx
	mov cx, 655
	loop $
	pop cx
	ret
