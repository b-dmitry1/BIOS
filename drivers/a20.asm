; A20 line control routines
;

; a20_enable
; Enables A20..A31 access
; In:
;   none
; Out:
;   none
a20_enable:
%if ((CPU == CPU_CX486) || (CPU == CPU_TI486))
	; Cyrix 486 or Texas Instruments TI486
	push ax
	mov al, 0xC0
	out 0x22, al
	in al, 0x23
	mov ah, al
	and ah, 0xFB	; reset A20M
	mov al, 0xC0
	out 0x22, al
	mov al, ah
	out 0x23, al
	pop ax
%else
	push ax
	mov al, 0x02
	out 0x92, al
	pop ax
%endif
	ret

; a20_disable
; Disables A20..A31 access
; In:
;   none
; Out:
;   none
a20_disable:
%if ((CPU == CPU_CX486) || (CPU == CPU_TI486))
	; Cyrix 486 or Texas Instruments TI486
	push ax
	mov al, 0xC0
	out 0x22, al
	in al, 0x23
	mov ah, al
	or ah, 0x04	; set A20M
	mov al, 0xC0
	out 0x22, al
	mov al, ah
	out 0x23, al
	pop ax
%else
	push ax
	mov al, 0x00
	out 0x92, al
	pop ax
%endif
	ret

; a20_get
; Returns A20 state
; In:
;   none
; Out:
;   AL = 0 - A20 disabled, 1 - A20 enabled
a20_get:
%if ((CPU == CPU_CX486) || (CPU == CPU_TI486))
	; Cyrix 486 or Texas Instruments TI486
	mov al, 0xC0
	out 0x22, al
	in al, 0x23
	and al, 0x04
	xor al, 0x04
	shr al, 1
	shr al, 1
%else
	in al, 0x92
	and al, 0x02
	shr al, 1
%endif
	ret
