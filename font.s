; =========================================================
; 
; Aracde Kernel Kit
; AArch64 Assembly Language
;
; About:
;
;
;
; Contact Information:
;
;   Jeff Panici
;   Email: jeff@nybbles.io
;   Website: https://nybbles.io
;   Live Stream: https://twitch.tv/nybblesio
;
; Copyright (C) 2018 Jeff Panici
; All rights reserved.
;
; This is free software available under the MIT license.
;
; See the LICENSE file in the root directory 
; for details about this license.
;
; =========================================================

FONT_WIDTH  = 5
FONT_HEIGHT = 5

align 4
nitram_micro_font:
	db 000h, 000h, 000h, 000h, 000h
	db 00ah, 000h, 004h, 011h, 00eh
	db 00ah, 000h, 000h, 00eh, 011h
	db 01bh, 01fh, 01fh, 00eh, 004h
	db 000h, 000h, 000h, 000h, 000h
	db 000h, 004h, 00ah, 004h, 00eh
	db 004h, 00eh, 00eh, 004h, 00eh
	db 000h, 00eh, 00eh, 00eh, 000h
	db 000h, 000h, 000h, 000h, 000h
	db 000h, 004h, 00ah, 004h, 000h
	db 000h, 000h, 000h, 000h, 000h
	db 00fh, 007h, 01fh, 015h, 01ch
	db 014h, 016h, 01fh, 006h, 004h
	db 005h, 00dh, 01fh, 00ch, 004h
	db 01eh, 00ah, 00ah, 00ah, 014h
	db 015h, 00eh, 01bh, 00eh, 015h
	db 004h, 006h, 007h, 006h, 004h
	db 004h, 00ch, 01ch, 00ch, 004h
	db 004h, 00eh, 004h, 00eh, 004h
	db 00ah, 00ah, 00ah, 000h, 00ah
	db 006h, 01ah, 00ah, 00ah, 00ah
	db 000h, 000h, 000h, 000h, 000h
	db 000h, 000h, 000h, 01fh, 01fh
	db 000h, 000h, 000h, 000h, 000h
	db 004h, 00eh, 015h, 004h, 004h
	db 004h, 004h, 015h, 00eh, 004h
	db 004h, 002h, 01fh, 002h, 004h
	db 004h, 008h, 01fh, 008h, 004h
	db 000h, 008h, 008h, 00fh, 000h
	db 000h, 00eh, 00eh, 00eh, 000h
	db 004h, 00eh, 01fh, 000h, 000h
	db 000h, 000h, 01fh, 00eh, 004h
	db 000h, 000h, 000h, 000h, 000h
	db 004h, 004h, 004h, 000h, 004h
	db 00ah, 00ah, 000h, 000h, 000h
	db 00ah, 01fh, 00ah, 01fh, 00ah
	db 01fh, 014h, 01fh, 005h, 01fh
	db 011h, 002h, 004h, 008h, 011h
	db 00ch, 012h, 00dh, 012h, 00dh
	db 002h, 004h, 000h, 000h, 000h
	db 002h, 004h, 004h, 004h, 002h
	db 008h, 004h, 004h, 004h, 008h
	db 015h, 00eh, 01fh, 00eh, 015h
	db 000h, 004h, 00eh, 004h, 000h
	db 000h, 000h, 000h, 004h, 008h
	db 000h, 000h, 00eh, 000h, 000h
	db 000h, 000h, 000h, 000h, 008h
	db 002h, 004h, 004h, 004h, 008h
	db 00eh, 013h, 015h, 019h, 00eh
	db 004h, 00ch, 004h, 004h, 00eh
	db 00eh, 002h, 00eh, 008h, 00eh
	db 00eh, 002h, 006h, 002h, 00eh
	db 008h, 008h, 00ah, 00eh, 002h
	db 00eh, 008h, 00eh, 002h, 00eh
	db 00ch, 008h, 00eh, 00ah, 00eh
	db 00eh, 002h, 006h, 002h, 002h
	db 00eh, 00ah, 00eh, 00ah, 00eh
	db 00eh, 00ah, 00eh, 002h, 00eh
	db 000h, 004h, 000h, 004h, 000h
	db 000h, 004h, 000h, 004h, 008h
	db 002h, 004h, 008h, 004h, 002h
	db 000h, 00eh, 000h, 00eh, 000h
	db 008h, 004h, 002h, 004h, 008h
	db 00eh, 011h, 006h, 000h, 004h
	db 00eh, 012h, 014h, 010h, 00eh
	db 00ch, 012h, 011h, 01fh, 011h
	db 01ch, 012h, 01eh, 011h, 01eh
	db 00eh, 011h, 010h, 011h, 00eh
	db 01eh, 013h, 011h, 011h, 01eh
	db 01fh, 010h, 01eh, 010h, 01fh
	db 01fh, 010h, 01eh, 010h, 010h
	db 00eh, 010h, 013h, 011h, 00eh
	db 012h, 011h, 01fh, 011h, 011h
	db 00eh, 004h, 004h, 004h, 00eh
	db 006h, 002h, 002h, 00ah, 00eh
	db 012h, 014h, 018h, 014h, 012h
	db 010h, 010h, 010h, 010h, 01eh
	db 011h, 01bh, 015h, 011h, 011h
	db 011h, 019h, 015h, 013h, 011h
	db 00eh, 013h, 011h, 011h, 00eh
	db 01ch, 012h, 01ch, 010h, 010h
	db 00eh, 011h, 011h, 013h, 00fh
	db 01ch, 012h, 01ch, 014h, 012h
	db 00fh, 010h, 00eh, 001h, 01eh
	db 01fh, 004h, 004h, 004h, 004h
	db 012h, 011h, 011h, 011h, 00eh
	db 00ah, 00ah, 00ah, 00ah, 004h
	db 012h, 011h, 015h, 015h, 00ah
	db 011h, 00ah, 004h, 00ah, 011h
	db 011h, 00ah, 004h, 004h, 004h
	db 01fh, 002h, 004h, 008h, 01fh
	db 006h, 004h, 004h, 004h, 006h
	db 008h, 004h, 004h, 004h, 002h
	db 00ch, 004h, 004h, 004h, 00ch
	db 004h, 00ah, 000h, 000h, 000h
	db 000h, 000h, 000h, 000h, 00eh
	db 004h, 002h, 000h, 000h, 000h
	db 00ch, 012h, 011h, 01fh, 011h
	db 01ch, 012h, 01eh, 011h, 01eh
	db 00eh, 011h, 010h, 011h, 00eh
	db 01eh, 013h, 011h, 011h, 01eh
	db 01fh, 010h, 01eh, 010h, 01fh
	db 01fh, 010h, 01eh, 010h, 010h
	db 00eh, 010h, 013h, 011h, 00eh
	db 012h, 011h, 01fh, 011h, 011h
	db 00eh, 004h, 004h, 004h, 00eh
	db 006h, 002h, 002h, 00ah, 00eh
	db 009h, 00ah, 00ch, 00ah, 009h
	db 010h, 010h, 010h, 010h, 01eh
	db 011h, 01bh, 015h, 011h, 011h
	db 011h, 019h, 015h, 013h, 011h
	db 00eh, 013h, 011h, 011h, 00eh
	db 01ch, 012h, 01ch, 010h, 010h
	db 00eh, 011h, 011h, 013h, 00fh
	db 01ch, 012h, 01ch, 014h, 012h
	db 00fh, 010h, 00eh, 001h, 01eh
	db 01fh, 004h, 004h, 004h, 004h
	db 012h, 011h, 011h, 011h, 00eh
	db 00ah, 00ah, 00ah, 00ah, 004h
	db 012h, 011h, 015h, 015h, 00ah
	db 011h, 00ah, 004h, 00ah, 011h
	db 011h, 00ah, 004h, 004h, 004h
	db 01fh, 002h, 004h, 008h, 01fh
	db 006h, 004h, 008h, 004h, 006h
	db 004h, 004h, 004h, 004h, 004h
	db 00ch, 004h, 002h, 004h, 00ch
	db 00ah, 014h, 000h, 000h, 000h
	db 000h, 004h, 00ah, 00ah, 00eh
	db 000h, 000h, 000h, 000h, 000h
	db 00ah, 000h, 00ah, 00ah, 00eh
	db 000h, 000h, 000h, 000h, 000h
	db 000h, 000h, 000h, 000h, 000h
	db 00ah, 000h, 00eh, 00ah, 00fh
	db 000h, 000h, 000h, 000h, 000h
	db 000h, 000h, 000h, 000h, 000h
	db 01fh, 011h, 011h, 011h, 01fh
	db 000h, 00eh, 00ah, 00eh, 000h
	db 000h, 000h, 004h, 000h, 000h
	db 000h, 000h, 000h, 000h, 000h
	db 000h, 000h, 004h, 000h, 000h
	db 000h, 00eh, 00ah, 00eh, 000h
	db 000h, 000h, 000h, 000h, 000h
	db 00ah, 000h, 00eh, 00ah, 00fh
	db 000h, 000h, 000h, 000h, 000h
	db 000h, 000h, 000h, 000h, 000h
	db 000h, 000h, 000h, 000h, 000h
	db 000h, 000h, 000h, 000h, 000h
	db 000h, 000h, 000h, 000h, 000h
	db 00ah, 000h, 00eh, 00ah, 00eh
	db 000h, 000h, 000h, 000h, 000h
	db 018h, 013h, 01ah, 012h, 01ah
	db 007h, 01dh, 015h, 015h, 017h
	db 000h, 018h, 010h, 010h, 010h
	db 00ah, 000h, 00eh, 00ah, 00eh
	db 00ah, 000h, 00ah, 00ah, 00eh
	db 000h, 000h, 000h, 000h, 01fh
	db 000h, 000h, 000h, 000h, 000h
	db 000h, 000h, 000h, 000h, 01fh
	db 000h, 000h, 000h, 000h, 000h
	db 000h, 000h, 000h, 000h, 01fh
	db 000h, 000h, 000h, 000h, 000h
	db 000h, 000h, 000h, 000h, 000h
	db 000h, 000h, 000h, 000h, 000h
	db 000h, 000h, 000h, 000h, 000h
	db 000h, 000h, 000h, 000h, 000h
	db 000h, 000h, 000h, 000h, 000h
	db 000h, 000h, 000h, 000h, 000h
	db 000h, 000h, 000h, 000h, 000h
	db 004h, 000h, 00ch, 011h, 00eh
	db 000h, 000h, 007h, 004h, 004h
	db 000h, 000h, 01ch, 004h, 004h
	db 000h, 000h, 000h, 000h, 000h
	db 000h, 000h, 000h, 000h, 000h
	db 004h, 000h, 004h, 004h, 004h
	db 004h, 009h, 012h, 009h, 004h
	db 004h, 012h, 009h, 012h, 004h
	db 000h, 00ah, 000h, 00ah, 000h
	db 00ah, 015h, 00ah, 015h, 00ah
	db 015h, 00ah, 015h, 00ah, 015h
	db 004h, 004h, 004h, 004h, 004h
	db 004h, 004h, 01ch, 004h, 004h
	db 004h, 01ch, 004h, 01ch, 004h
	db 00ah, 00ah, 01ah, 00ah, 00ah
	db 000h, 000h, 01eh, 00ah, 00ah
	db 000h, 01ch, 004h, 01ch, 004h
	db 00ah, 01ah, 002h, 01ah, 00ah
	db 00ah, 00ah, 00ah, 00ah, 00ah
	db 000h, 01eh, 002h, 01ah, 00ah
	db 00ah, 01ah, 002h, 01eh, 000h
	db 00ah, 00ah, 01eh, 000h, 000h
	db 004h, 01ch, 004h, 01ch, 000h
	db 000h, 000h, 01ch, 004h, 004h
	db 004h, 004h, 007h, 000h, 000h
	db 004h, 004h, 01fh, 000h, 000h
	db 000h, 000h, 01fh, 004h, 004h
	db 004h, 004h, 007h, 004h, 004h
	db 000h, 000h, 01fh, 000h, 000h
	db 004h, 004h, 01fh, 004h, 004h
	db 004h, 007h, 004h, 007h, 004h
	db 00ah, 00ah, 00bh, 00ah, 00ah
	db 00ah, 00bh, 008h, 00fh, 000h
	db 000h, 00fh, 008h, 00bh, 00ah
	db 00ah, 01bh, 000h, 01fh, 000h
	db 000h, 01fh, 000h, 01bh, 00ah
	db 00ah, 00bh, 008h, 00bh, 00ah
	db 000h, 01fh, 000h, 01fh, 000h
	db 00ah, 01bh, 000h, 01bh, 00ah
	db 004h, 01fh, 000h, 01fh, 000h
	db 00ah, 00ah, 01fh, 000h, 000h
	db 000h, 01fh, 000h, 01fh, 004h
	db 000h, 000h, 01fh, 00ah, 00ah
	db 00ah, 00ah, 00fh, 000h, 000h
	db 004h, 007h, 004h, 007h, 000h
	db 000h, 007h, 004h, 007h, 004h
	db 000h, 000h, 00fh, 00ah, 00ah
	db 00ah, 00ah, 01fh, 00ah, 00ah
	db 004h, 01fh, 004h, 01fh, 004h
	db 004h, 004h, 01ch, 000h, 000h
	db 000h, 000h, 007h, 004h, 004h
	db 01fh, 01fh, 01fh, 01fh, 01fh
	db 000h, 000h, 01fh, 01fh, 01fh
	db 018h, 018h, 018h, 018h, 018h
	db 003h, 003h, 003h, 003h, 003h
	db 01fh, 01fh, 01fh, 000h, 000h
	db 000h, 000h, 000h, 000h, 000h
	db 00ch, 012h, 016h, 011h, 016h
	db 000h, 000h, 000h, 000h, 000h
	db 00eh, 011h, 011h, 011h, 00eh
	db 000h, 004h, 00ah, 004h, 000h
	db 000h, 000h, 004h, 000h, 000h
	db 000h, 000h, 000h, 000h, 000h
	db 000h, 000h, 004h, 000h, 000h
	db 000h, 004h, 00ah, 004h, 000h
	db 000h, 000h, 000h, 000h, 000h
	db 000h, 000h, 000h, 000h, 000h
	db 000h, 000h, 000h, 000h, 000h
	db 000h, 00eh, 01fh, 00eh, 000h
	db 001h, 00eh, 00ah, 00eh, 010h
	db 006h, 008h, 00eh, 008h, 006h
	db 00ch, 012h, 012h, 012h, 012h
	db 00eh, 000h, 00eh, 000h, 00eh
	db 004h, 00eh, 004h, 000h, 00eh
	db 008h, 004h, 002h, 004h, 00eh
	db 002h, 004h, 008h, 004h, 00eh
	db 002h, 005h, 004h, 004h, 004h
	db 004h, 004h, 004h, 014h, 008h
	db 004h, 000h, 00eh, 000h, 004h
	db 00ah, 014h, 000h, 00ah, 014h
	db 004h, 00eh, 004h, 000h, 000h
	db 000h, 00eh, 00eh, 00eh, 000h
	db 000h, 000h, 004h, 000h, 000h
	db 003h, 002h, 01ah, 00ah, 004h
	db 000h, 000h, 000h, 000h, 000h
	db 000h, 000h, 000h, 000h, 000h
	db 000h, 000h, 000h, 000h, 000h
	db 000h, 000h, 000h, 000h, 000h

align 4	
