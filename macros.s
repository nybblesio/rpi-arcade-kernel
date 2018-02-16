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

macro pload reg*, label* {
        adr     x0, label
        ldr     reg, [x0]
}

macro pstore reg*, label* {
        adr     x0, label
        str     reg, [x0]
}

macro strlist [strings] {
        forward db  strings
}

macro strdef [strings] {
common
        local   .strend
        dw      .strend - $
        strlist strings
.strend:
}
