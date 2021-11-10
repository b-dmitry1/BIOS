	; Set interrupt controller (PICs 8259) registers
	mov al, 0x11	; ICW1: Edge triggered mode, cascade, ICW4 needed
	out 0x20, al
	mov al, 0x08	; ICW2: Table start at 8
	out 0x21, al
	mov al, 0x04	; ICW3: Slave connected to IR2
	out 0x21, al
	mov al, 0x01	; ICW4: 8086 mode, normal EOI
	out 0x21, al
	mov al, 0x00	; OCW1: enable all IRQs 0-7
	out 0x21, al
	mov al, 0x20	; OCW2: end of interrupt just in case
	out 0x20, al
	mov al, 0x08	; OCW3: reset OCW3
	out 0x20, al

	mov al, 0x11	; ICW1: Edge triggered mode, cascade, ICW4 needed
	out 0xA0, al
	mov al, 0x08	; ICW2: Table start at 8
	out 0xA1, al
	mov al, 0x02	; ICW3: Slave
	out 0xA1, al
	mov al, 0x01	; ICW4: 8086 mode, normal EOI
	out 0xA1, al
	mov al, 0xFF	; OCW1: disable all IRQs 8-15
	out 0xA1, al
	mov al, 0x20	; OCW2: end of interrupt just in case
	out 0xA0, al
	mov al, 0x08	; OCW3: reset OCW3
	out 0xA0, al

; No return from here (inline code!)
