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
; Constants Section
;
; =========================================================
RAND_MAX = 32767

; =========================================================
;
; Variables Section
;
; =========================================================
prng_constant1:
    dw  8253729

prng_constant2:
    dw  2396403

prng_seed:
    dw  5323

align 4

; =========================================================
;
; rand
;
; stack:
;   lower limit
;   upper limit
;
; registers:
;   (none)
;
; =========================================================
; return min + rand() / (RAND_MAX / (max - min + 1) + 1);
rand:
    sub         sp, sp, #64
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    stp         x5, x6, [sp, #48]

    pload       x0, w0, prng_seed
    pload       x1, w1, prng_constant1
    pload       x2, w2, prng_constant2
    madd        w0, w0, w1, w2
    pstore      x1, w0, prng_seed
    and         w0, w0, RAND_MAX - 1

    ldp         x1, x2, [sp, #64]
    sub         w4, w2, w1
    add         w4, w4, 1
    mov         w5, RAND_MAX
    udiv        w5, w5, w4
    add         w5, w5, 1

    udiv        w6, w0, w5
    add         w6, w6, w1
    mov         w26, w6

    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    ldp         x5, x6, [sp, #48]
    add         sp, sp, #80
    ret

macro rand lower_limit*, upper_limit* {
    sub         sp, sp, #16
    mov         w26, lower_limit
    mov         w27, upper_limit
    stp         x26, x27, [sp]
    bl          rand
}

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
