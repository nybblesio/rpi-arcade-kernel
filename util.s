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
; fill_buffer
;
; stack:
;   (none)
;   
; registers:
;   w1 is character to fill
;   w2 is the length
;   x3 is buffer address
;
; =========================================================
fill_buffer:
    sub         sp, sp, #16
    stp         x0, x30, [sp]
.empty: 
    strb        w1, [x3], 1
    subs        w2, w2, 1
    b.ne        .empty
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret
