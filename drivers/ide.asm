; Compact IDE HDD driver (poll-mode)
;

%define IDE_HDD_READ		0x20
%define IDE_HDD_WRITE		0x30

%define IDE_STATUS_DRQ		0x08

%define IDE_PORT_DATA		0x1F0
%define IDE_PORT_COUNT		0x1F2
%define IDE_PORT_SECTOR		0x1F3
%define IDE_PORT_CYL_LOW	0x1F4
%define IDE_PORT_CYL_HIGH	0x1F5
%define IDE_PORT_HEAD_DRV_LBA	0x1F6
%define IDE_PORT_CMD		0x1F7
%define IDE_PORT_STATUS		0x1F7
%define IDE_PORT_ALT_STATUS	0x3F6

; ide_send_chs
; Sends number of sectors, drive number and CHS to IDE HDD
; In:
;   AL - number of sectors
;   CH - cylinder
;   CL - sector
;   DH - head
;   DL - drive number
ide_send_chs:
	push ax
	push cx
	push dx

	push dx

	; 0x1F2 - number of sectors
	mov dx, IDE_PORT_COUNT
	out dx, al

	; 0x1F3 - sector
	mov al, cl
	and al, 0x3F
	mov dx, IDE_PORT_SECTOR
	out dx, al

	; 0x1F4 - cylinder low
	mov al, ch
	mov dx, IDE_PORT_CYL_LOW
	out dx, al

	; 0x1F5 - cylinder high
	mov al, cl
	mov cl, 6
	shr al, cl
	mov dx, IDE_PORT_CYL_HIGH
	out dx, al

	pop dx
	
	; 0x1F6 - drive (0x10) / lba (0x40) / head (0x0F)
	shl dl, 1
	shl dl, 1
	shl dl, 1
	shl dl, 1
	or dl, dh
	and dl, 0x1F
	mov al, dl
	mov dx, IDE_PORT_HEAD_DRV_LBA
	out dx, al

	pop dx
	pop cx
	pop ax	
	ret


; ide_wait
; Waits until the device has PIO data to transfer, or is ready to accept PIO data
; In:
;   none
; Out:
;   CF = 0 - ok
ide_wait:
	push ax
	push cx
	push dx
	mov cx, 65535
	mov dx, IDE_PORT_STATUS
ide_wait_loop:
	in al, dx
	test al, IDE_STATUS_DRQ
	jnz ide_wait_ok
	loop ide_wait_loop
	stc
	jmp ide_wait_done
ide_wait_ok:
	clc
ide_wait_done:
	pop dx
	pop cx
	pop ax
	ret


; ide_read
; IDE HDD read
; In:
;   AL - number of sectors to read
;   CH - cylinder
;   CL - sector
;   DH - head
;   DL - drive number
;   ES:BX - buffer
ide_read:
	push ax

	call ide_send_chs

	; send read command
	mov al, IDE_HDD_READ
	mov dx, IDE_PORT_CMD
	out dx, al

	pop ax

ide_read_loop:
	or al, al
	jz ide_read_done
	call ide_wait
	jc ide_read_timeout
	mov cx, 256
	mov dx, IDE_PORT_DATA
	push ax
ide_read_data:
	in ax, dx
	mov [es:bx], ax
	add bx, 2
	loop ide_read_data
	pop ax
	sub al, 1
	jmp ide_read_loop
ide_read_done:
	clc
	ret
ide_read_timeout:
	ret

; ide_write
; IDE HDD write
; In:
;   AL - number of sectors to write
;   CH - cylinder
;   CL - sector
;   DH - head
;   DL - drive number
;   ES:BX - buffer
ide_write:
	push ax

	call ide_send_chs

	; send write command
	mov al, IDE_HDD_WRITE
	mov dx, IDE_PORT_CMD
	out dx, al

	pop ax

ide_write_loop:
	or al, al
	jz ide_write_done
	call ide_wait
	jc ide_write_timeout
	mov cx, 256
	mov dx, IDE_PORT_DATA
	push ax
ide_write_data:
	mov ax, [es:bx]
	out dx, ax
	add bx, 2
	loop ide_write_data
	pop ax
	sub al, 1
	jmp ide_write_loop
ide_write_done:
	clc
	ret
ide_write_timeout:
	ret
