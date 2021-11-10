; Chip Select configuration routines
;

; 80386EX CSU registers
%define CS0ADL		(0xF400 + 0)
%define CS0ADH		(0xF400 + 2)
%define CS0MSKL		(0xF400 + 4)
%define CS0MSKH		(0xF400 + 6)

%define CS1ADL		(0xF408 + 0)
%define CS1ADH		(0xF408 + 2)
%define CS1MSKL		(0xF408 + 4)
%define CS1MSKH		(0xF408 + 6)

%define CS2ADL		(0xF410 + 0)
%define CS2ADH		(0xF410 + 2)
%define CS2MSKL		(0xF410 + 4)
%define CS2MSKH		(0xF410 + 6)

%define CS3ADL		(0xF418 + 0)
%define CS3ADH		(0xF418 + 2)
%define CS3MSKL		(0xF418 + 4)
%define CS3MSKH		(0xF418 + 6)

%define CS4ADL		(0xF420 + 0)
%define CS4ADH		(0xF420 + 2)
%define CS4MSKL		(0xF420 + 4)
%define CS4MSKH		(0xF420 + 6)

%define CS5ADL		(0xF428 + 0)
%define CS5ADH		(0xF428 + 2)
%define CS5MSKL		(0xF428 + 4)
%define CS5MSKH		(0xF428 + 6)

%define CS6ADL		(0xF430 + 0)
%define CS6ADH		(0xF430 + 2)
%define CS6MSKL		(0xF430 + 4)
%define CS6MSKH		(0xF430 + 6)

%define UCSADL		(0xF438 + 0)
%define UCSADH		(0xF438 + 2)
%define UCSMSKL		(0xF438 + 4)
%define UCSMSKH		(0xF438 + 6)

%define P2CFG		0xF822

%if (CPU == CPU_386EX)
	; Intel 80386EX

	; Add your code here to configure Chip Select Unit
	; as described in 80386EX User's Manual

	; 1. Program high address (ADH) register
	; 2. Program low address (ADL) register
	; 3. Program high mask (MSKH) register
	; 4. Program low mask (MSKL) register
	; 5. Program P2CFG register to select CS outputs you need

	; Note that UCS block is enabled by default and your CPU will have
	; 15 additional wait states and will ignore RDY input
	; You should at least write a new values to UCS regs

%endif

; No return from here (inline code!)
