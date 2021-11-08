@echo off
c:\nasm\nasm bios.asm -o bin\bios.bin
tools\bin2mif\bin2mif silent 8 bin\bios.bin
c:\nasm\ndisasm bin\bios.bin > bios.dasm

copy /b bin\bios.bin+bin\empty8k.bin+bin\empty8k.bin+bin\empty8k.bin+bin\empty8k.bin+bin\empty8k.bin+bin\empty8k.bin+bin\bios.bin bin\bios64k.bin >nul

pause
