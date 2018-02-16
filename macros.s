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

; =========================================================
;
; Macros
;
; =========================================================
macro delay cycles {
        local   .loop
        mov     w12, cycles
.loop:  subs    w12, w12, 1
        b.ne    .loop        
}

macro strlist [params] {
        forward db  params
}

macro strdef [params] {
common
        local   .strend
        dw      .strend - .strstart
.strstart:        
        strlist params
.strend:
}
