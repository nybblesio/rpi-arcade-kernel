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

GAME_ABI_BOTTOM = $10000
GAME_ABI_SIZE   = $1000
GAME_ABI_BASE   = GAME_ABI_BOTTOM - GAME_ABI_SIZE

GAME_TITLE      = $0
GAME_VERSION    = $41
GAME_REVISION   = $42

; =========================================================
;
; Data Section
;
; =========================================================
org GAME_ABI_BASE

title       db  0   dup(64)
version     db  1 
revision    db  0

log_line_buffer:
        db  256 dup(0)
ll_offs db  0

