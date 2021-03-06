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
; mem_copy64
;
; stack:
;   src ptr
;   dest ptr
;   size
;
; registers:
;   (none)
;
; =========================================================
mem_copy64:
    sub         sp, sp, #48
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    ldp         x0, x1, [sp, #48]
    ldp         x2, x3, [sp, #64]
.loop: 
    ldr         x4, [x0], 8
    str         x4, [x1], 8
    subs        w2, w2, 1
    b.ne        .loop
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    add         sp, sp, #80
    ret

macro mem_copy64 src, dest, len {
    sub         sp, sp, #32
    mov         w25, src
    mov         w26, dest
    stp         x25, x26, [sp]
    mov         w25, len
    mov         w26, 0
    stp         x25, x26, [sp, #16]
    bl          mem_copy64
}

; =========================================================
;
; mem_copy8
;
; stack:
;   src ptr
;   dest ptr
;   size
;
; registers:
;   (none)
;
; =========================================================
mem_copy8:
    sub         sp, sp, #48
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    ldp         x0, x1, [sp, #48]
    ldp         x2, x3, [sp, #64]
.loop: 
    ldrb        w4, [x0], 1
    strb        w4, [x1], 1 
    subs        w2, w2, 1
    b.ne        .loop
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    add         sp, sp, #80
    ret

macro mem_copy8 src, dest, len {
    sub         sp, sp, #32
    mov         w25, src
    mov         w26, dest
    stp         x25, x26, [sp]
    mov         w25, len
    mov         w26, 0
    stp         x25, x26, [sp, #16]
    bl          mem_copy8
}

; =========================================================
;
; mem_fill8
;
; stack:
;   buffer ptr
;   length
;   value
;   pad
;
; registers:
;   (none)
;
; =========================================================
mem_fill8:
    sub         sp, sp, #48
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    ldp         x0, x1, [sp, #48]
    ldp         x2, x3, [sp, #64]
.loop: 
    strb        w2, [x0], 1
    subs        w1, w1, 1
    b.ne        .loop
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    add         sp, sp, #80
    ret

macro mem_fill8 buffer, len, value {
    sub         sp, sp, 32
    mov         w20, buffer
    mov         w21, len
    stp         x20, x21, [sp]
    mov         w20, value
    mov         w21, 0
    stp         x20, x21, [sp, #16]
    bl          mem_fill8
}
