; PLL enable routines
;

pll_enable:

%if ((ENABLE_CACHE == 1) && (CPU == CPU_TI486))
	; Texas Instruments TI486
	; Select CCR0
	mov al, 0xC0
	out 0x22, al
	in al, 0x23
	mov ah, al
	; Set CKD
	or ah, 0x40
	mov al, 0xC0
	out 0x22, al
	mov al, ah
	out 0x23, al
	; Wait for PLL
	mov cx, 10000
	loop $
%endif

	ret
