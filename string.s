; =========================================================
; 
; Aracde Kernel Kit
; AArch64 Assembly Language
;
; Lumberjacks
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
macro str_hex2 value, dest {
    sub         sp, sp, #32
    mov         w20, value
    mov         w21, 8
    stp         x20, x21, [sp]
    mov         w20, dest
    mov         w21, 0
    stp         x20, x21, [sp, #16]
    bl          string_hex
}

macro str_hex4 value, dest {
    sub         sp, sp, #32
    mov         w20, value
    mov         w21, 16
    stp         x20, x21, [sp]
    mov         w20, dest
    mov         w21, 0
    stp         x20, x21, [sp, #16]
    bl          string_hex
}

macro str_hex8 value, dest {
    sub         sp, sp, #32
    mov         w20, value
    mov         w21, 32
    stp         x20, x21, [sp]
    mov         w20, dest
    mov         w21, 0
    stp         x20, x21, [sp, #16]
    bl          string_hex
}

; =========================================================
;
; string_hex
;
; stack:
;   word to convert
;   bits
;   str_ptr
;   pad
;
; registers:
;   (none)
;
; =========================================================
string_hex:
    sub         sp, sp, #48
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    ldp         x0, x1, [sp, #48]
    ldp         x2, x3, [sp, #64]
.loop:    
    mov         w4, w0
    sub         w1, w1, 4
    lsr         w4, w4, w1
    and         w4, w4, $0f
    cmp         w4, 9
    b.gt        .gt
    add         w4, w4, $30
    b           .write
.gt:    
    add         w4, w4, $37
.write:  
    strb        w4, [x2], 1
    cbnz        w1, .loop
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    add         sp, sp, #80
    ret

; =========================================================
;
; string_eq
;
; stack:
;   str1_ptr
;   str1_len
;   str2_ptr
;   str2_len
;
; registers:
;   (none)
;
; =========================================================
string_eq:
    sub         sp, sp, #48
    stp         x0, x30, [sp]
    stp         x2, x3, [sp, #16]
    stp         x4, x5, [sp, #32]
    ldp         x0, x1, [sp, #48]
    ldp         x2, x3, [sp, #64]
    cmp         w1, w3
    b.ne        .notequal
.loop:
    ldrb        w3, [x0], 1
    ldrb        w4, [x2], 1
    cmp         w3, w4
    b.ne        .notequal
    subs        w1, w1, 1
    b.ne        .loop
    mov         w1, 1
    b           .ok
.notequal:
    mov         w1, 0
.ok:    
    ldp         x0, x30, [sp]
    ldp         x2, x3, [sp, #16]
    ldp         x4, x5, [sp, #32]
    add         sp, sp, #80
    ret
