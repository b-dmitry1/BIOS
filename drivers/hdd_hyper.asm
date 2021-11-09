; Hypercall for HDD emulation
; Insert your code here

	; Undefined command 0xFF / 7 (hypercall)
	db 0xFF, 0xFF
	; Send interrupt 13h code to emulator
	db 0x13
