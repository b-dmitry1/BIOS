; Cache memory routines
;

cache_enable:
	
	; To disable cache memory on 486+ CPUs we need to set bit 30 of CR0
	; mov eax, cr0
	; or eax, 0x40000000
	; mov cr0, eax

	; CPU's cache memory is enabled by default so there's nothing to do here

%if ((ENABLE_CACHE == 1) && ((CPU == CPU_CX486) || (CPU == CPU_TI486)))
	; Cyrix 486 and Texas Instruments TI486

	; !!! Note that you should add your code here to set non-cached regions
	; if you have memory-mapped devices like VGA-card that cannon work
	; correctly with CPU's internal cache enabled
	; More information can be found in the "TI486SXL Microprocessors Reference Guide"
	; For example, we should set 0xA0000 - 0xBFFFF as non-cacheable for VGA adapter:
	;; Select ARR1 [7:0]
	;mov al, 0xC6
	;out 0x22, al
	;; Set 128KB region
	;mov al, 0x06
	;out 0x23, al
	;; Select ARR1 [15:8]
	;mov al, 0xC5
	;out 0x22, al
	;; Set 0xA0000 region start
	;mov al, 0x0A
	;out 0x23, al


	; Disable cache for 0xA0000 - 0xFFFFF area by setting CCR0.NC1
	; and enable it for 
	mov al, 0xC0
	out 0x22, al
	in al, 0x23
	mov ah, al
	or ah, 0x02	; set NC1
	and ah, 0xF7	; reset KEN to disable KEN# control
	mov al, 0xC0
	out 0x22, al
	mov al, ah
	out 0x23, al
		
%endif

	ret
