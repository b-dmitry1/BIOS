; SPI mode SD card BIOS

sd_read:
	; Read SD card
	push es
	mov cx, 0x40
	mov es, cx
	mov cl, [es:sd_block]
	pop es

	cmp cl, 1
	je sd_readsector_block
	and dx, 0x7FFF
	shl ax, 1
	rcl dx, 1	; DX:AX = LBA * 2
	push bx
	mov dh, dl
	mov dl, ah
	mov bh, al
	xor bl, bl
	jmp sd_readsector_start_read
sd_readsector_block:
	push bx
	mov bx, ax
sd_readsector_start_read:
	cmp bp, 0x300
	je sd_write
	mov al, 18	; Read multiple blocks
	call sd_sendcmd
	pop bx
	cmp al, 0
	je sd_readsector_ok
sd_readsector_fail:
	pop ax		; Remove AX from stack
	xor ax, ax
	pop bp
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	jmp int13_not_ready
sd_readsector_ok:
	pop ax		; AX = number of sectors to read
	xor ah, ah
	mov bp, ax
	mov dx, ax
	mov di, bx
	cld
sd_readsector_wait0:
	mov al, 0xFF
sd_readsector_wait:
	call spi
	cmp al, 0xFF
	je sd_readsector_wait
	cmp al, 0xFE
	jne sd_readsector_fail
	mov cx, 512
sd_readsector_read:
	mov al, 0xFF
	call spi
	stosb
	
	loop sd_readsector_read
	mov al, 0xFF
	call spi
	mov al, 0xFF
	call spi
	sub dx, 1
	jnz sd_readsector_wait0
	xor bx, bx
	xor dx, dx
	mov al, 12	; Stop transmission
	call sd_sendcmd
	call sd_deselect

	; TODO: add read checksum comparison and repeat in case of error

done_read_check:

	mov ax, bp
	xor ah, ah

	pop bp
	pop di
	pop si
	pop dx
	pop cx
	pop bx

	jmp int13_success

sd_write:
	mov al, 25	; Write multiple blocks
	call sd_sendcmd
	pop bx
	cmp al, 0
	je sd_writesector_ok
sd_writesector_fail:
	pop ax		; Remove AX from stack
sd_write_next_sector_failed:
	xor ax, ax
	pop bp
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	jmp int13_not_ready

sd_writesector_ok:
	pop ax		; AX = number of sectors to write

	xor ah, ah
	mov bp, ax
	mov dx, ax
	mov di, bx
	cld

sd_write_next_sector:
	; Wait for card
	mov al, 0xFF
	call spi
	cmp al, 0xFF
	jne sd_write_next_sector

	; Start of the block
	mov al, 0xFC
	call spi

	; Send data
	mov cx, 512
sd_write_next_sector_loop:
	mov al, [es:di]
	call spi
	inc di
	loop sd_write_next_sector_loop

	; Skip checksum
	; TODO: calculate and send checksum
	mov al, 0xFF
	call spi
	mov al, 0xFF
	call spi
	mov al, 0xFF
	call spi

	and al, 0x1F
	cmp al, 0x05
	jne sd_write_next_sector_failed

	sub dx, 1
	jnz sd_write_next_sector


sd_write_next_sector_last:
	; Wait for card
	mov al, 0xFF
	call spi
	cmp al, 0xFF
	jne sd_write_next_sector_last
	
	; Transaction end
	mov al, 0xFD
	call spi

	call sd_deselect

	; TODO: add written data verification here

done_write_check:

	mov ax, bp
	xor ah, ah

	pop bp
	pop di
	pop si
	pop dx
	pop cx
	pop bx

	jmp int13_success

sd_wait:
	mov al, 0xFF
	call spi
	cmp al, 0xFF
	jne sd_wait
	ret

sd_select:
	push ax
	call spi_begin
	mov al, 0xFF
	call spi
	call sd_wait
	pop ax
	ret

sd_deselect:
	push ax
	call spi_end
	mov al, 0xFF
	call spi
	pop ax
	ret

; Send command to SD-card
; In:
; al = cmd
; bl = arg[7:0]
; bh = arg[15:8]
; dl = arg[23:16]
; dh = arg[31:24]
; Out:
; al = resp
; ah = ?
sd_sendcmd:
	test al, 0x80
	jz sd_sendcmd_done55
	push ax
	push bx
	push dx
	mov al, 55 ; APP_CMD
	xor bx, bx
	xor dx, dx
	call sd_sendcmd
	test al, 0xFE
	jnz sd_sendcmd_error55
	pop dx
	pop bx
	pop ax
	jmp sd_sendcmd_done55
sd_sendcmd_error55:
	pop dx
	pop bx
	pop bx
	ret
sd_sendcmd_done55:
	and al, 0x7F
	cmp al, 12 ; STOP_TRANSMISSION
	je sd_sendcmd_done_select
	call sd_deselect
	call sd_select
sd_sendcmd_done_select:
	mov ah, al
	or al, 0x40	; start + cmd
	call spi
	mov al, dh
	call spi
	mov al, dl
	call spi
	mov al, bh
	call spi
	mov al, bl
	call spi
	mov al, 0x01	; stop + crc for other
	cmp ah, 0
	jne sd_sendcmd_skip1
	mov al, 0x95	; crc for cmd 0
sd_sendcmd_skip1:
	cmp ah, 8
	jne sd_sendcmd_skip2
	mov al, 0x87	; crc for cmd 8
sd_sendcmd_skip2:
	call spi
	cmp ah, 12
	jne sd_sendcmd_skip3
	call spi_readbyte
sd_sendcmd_skip3:
	mov ah, 10
sd_sendcmd_loop:
	call spi_readbyte
	test al, 0x80
	jz sd_sendcmd_loop_end
	sub ah, 1
	jnz sd_sendcmd_loop
sd_sendcmd_loop_end:
	ret

; Get SD result
; Out:
; bl = arg[7:0]
; bh = arg[15:8]
; dl = arg[23:16]
; dh = arg[31:24]
sd_get_result:
	call spi_readbyte
	mov dh, al
	call spi_readbyte
	mov dl, al
	call spi_readbyte
	mov bh, al
	call spi_readbyte
	mov bl, al
	ret

sd_init:
	; Set SPI speed to 200 KHz to initialize SD card in SPI mode
	call spi_slow

	mov cx, 10000
	loop $

        call sd_deselect
	mov si, msg_sd_init
	call putsv

	call spi_readbyte
	call spi_readbyte
	call spi_readbyte
	call spi_readbyte
	call spi_readbyte
	call spi_readbyte
	call spi_readbyte
	call spi_readbyte
	call spi_readbyte
	call spi_readbyte

	mov al, 0
	xor bx, bx
	xor dx, dx
	call sd_sendcmd
	cmp al, 1
	je sd_init1
	call sd_deselect
sd_init_error:
	mov si, msg_sd_init_error
	call putsv
        call sd_deselect
	jmp $
sd_init1:
	mov al, 8
	mov bx, 0x1AA
	xor dx, dx
	call sd_sendcmd
	cmp al, 1
	je sd_init_sdv2

	mov al, 0x80
	add al, 41
	xor bx, bx
	xor dx, dx
	call sd_sendcmd
	test al, 0xFE
	jz sd_init_sdv1

sd_init_mmc_wait:
	mov al, 1
	xor bx, bx
	xor dx, dx
	call sd_sendcmd
	or al, al
	jnz sd_init_mmc_wait

	mov si, msg_sd_init_mmc
	call putsv

	jmp sd_init_setblocksize

sd_init_sdv1:
	mov al, 0x80
	add al, 41
	xor bx, bx
	xor dx, dx
	call sd_sendcmd
	or al, al
	jnz sd_init_sdv1

	mov si, msg_sd_init_sdv1
	call putsv

sd_init_setblocksize:
	mov al, 16
	mov bx, 512
	xor dx, dx
	call sd_sendcmd
	jmp sd_init_done	

sd_init_sdv2:
	call sd_get_result
	cmp bh, 1
	jne sd_init_error
	cmp bl, 0xAA
	jne sd_init_error

	mov si, msg_sd_init_sdv2
	call putsv

sd_init_sdv2_wait:
	mov al, 0x80
	add al, 41
	xor bx, bx
	mov dx, 0x4000
	call sd_sendcmd
	or al, al
	jnz sd_init_sdv2_wait

	mov al, 58
	xor bx, bx
	xor dx, dx
	call sd_sendcmd
	or al, al
	jnz sd_init_error

	call sd_get_result	
	
	test dh, 0x40
	jz sd_init_setblocksize

	mov si, msg_sd_init_sdv2_block
	call putsv

	mov ax, 0x40
	mov es, ax
	mov [es:sd_block - bios_data], byte 1

sd_init_done:
	call sd_deselect
	; The card is successfully initialized so can configure SPI to full speed
	call spi_fast
	ret	
