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
macro pload addr_reg*, data_reg*, label* {
    adr         addr_reg, label
    ldr         data_reg, [addr_reg]
}

macro ploadb addr_reg*, data_reg*, label* {
    adr         addr_reg, label
    ldrb        data_reg, [addr_reg]
}

macro pstore addr_reg*, data_reg*, label* {
    adr         addr_reg, label
    str         data_reg, [addr_reg]
}

macro pstoreb addr_reg*, data_reg*, label* {
    adr         addr_reg, label
    strb        data_reg, [addr_reg]
}

macro strlist [params] {
    forward db  params
}

macro strdef name, [params] {
align 4
common
label name
    local   .end, .start
    dw      .end - .start
.start:        
    strlist params
.end:
}

macro strpad name, len, [params] {
common
label name
    local   .end, .start
.start:        
    strlist params
.end:
    db len - (.end - .start) dup(CHAR_SPACE)
}
