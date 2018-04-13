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

macro joy_check offset {
    mov         x26, KERNEL_ABI_BOTTOM
    mov         w27, offset
    add         w26, w26, w27
    ldrb        w26, [x26]
}

macro watch_set idx, ypos, xpos, reg, [params] {
    common
    local       .start, .value, .end, .skip
    b           .skip
.start:
    strlist     params
    db          '$'
.value:
    db          8 dup('0')
.end:
    align 4
.skip:    
    mov         x26, KERNEL_ABI_BOTTOM
    add         w26, w26, WATCHES_BASE
    mov         w27, WATCH_SZ
    mov         w28, idx
    madd        w26, w27, w28, w26
    mov         w27, F_WATCH_ENABLED
    strb        w27, [x26, WATCH_FLAGS]
    mov         w27, ypos
    strh        w27, [x26, WATCH_Y_POS]
    mov         w27, xpos
    strh        w27, [x26, WATCH_X_POS]
    mov         w27, .end - .start
    strb        w27, [x26, WATCH_LEN]
    adr         x27, .start
    str         w27, [x26, WATCH_STR]
    adr         x27, .value
    str_hex32   reg, w27
}

macro watch_clr idx {
    mov         x26, KERNEL_ABI_BOTTOM
    add         w26, w26, WATCHES_BASE
    mov         w27, WATCH_SZ
    mov         w28, idx
    madd        w26, w28, w27, w26
    mov         w27, F_WATCH_NONE
    strb        w27, [x26, WATCH_FLAGS]
}
