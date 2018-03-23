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

TIMER_COUNT         = 32

F_TIMER_DISABLED    = 00000000_00000000b
F_TIMER_ENABLED     = 00000000_00000001b

TIMER_ID            = 0
TIMER_STATUS        = 4
TIMER_DURATION      = 8
TIMER_TIMEOUT       = 12
TIMER_CALLBACK      = 16

; =========================================================
;
; Macro Section
;
; =========================================================
macro delay duration {
    sub         sp, sp, 16
    mov         w25, duration
    mov         w26, 0
    stp         x25, x26, [sp]
    bl          timer_wait
}

; 1Mhz = 1000 cycles per millisecond
; e.g. 250ms = 250 * 1000 = 250000
macro timerdef name, id, duration, callback {
align 4
common
label name
    dw  id
    dw  F_TIMER_ENABLED
    dw  duration * 1600 ; 250MHz/250MHz = 1MHz = 1000 cycles per millisecond
                        ; @ 400MHz
    dw  0               ; next timeout
    dw  callback
}

macro timer_flags addr*, flags* {
    adr         x25, addr
    mov         w26, flags
    str         w26, [x25, TIMER_STATUS]
}

; =========================================================
;
; Data Section
;
; =========================================================
align 4

; these settings assume a 250MHz core clock
; if the core clock is running at 400Mhz then it's 2000 cycles per millisecond
timer_settings1 dw  $00f90000
timer_settings2 dw  $00f90200

align 4
timers:
    dw  TIMER_COUNT dup(0)

; =========================================================
;
; timer_wait
;
; stack:
;   wait (in cycles per second)
;   pad
;
; registers:
;   (none)
;
; =========================================================
timer_wait:
    sub         sp, sp, #32
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    ldp         x1, x2, [sp, #32]
    pload       x0, w0, arm_timer_counter
    ldr         w2, [x0]
    add         w2, w2, w1
.loop:
    ldr         w1, [x0]
    cmp         w1, w2
    b.hi        .done
    b           .loop
.done:
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    add         sp, sp, #48
    ret

; =========================================================
;
; timer_start
;
; stack:
;   (in) timer structure address
;   (in) pad
;
;   (out) pointer to timer entry
;   (out) pad
;
; registers:
;   (none)
;
; =========================================================
timer_start:
    sub         sp, sp, #48
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    ldp         x3, x4, [sp, #48]
    adr         x0, timers
    mov         w1, TIMER_COUNT
.loop:
    ldr         w2, [x0]
    cbnz        w2, .next
    str         w3, [x0]
    b           .done
.next:
    add         w0, w0, 4
    subs        w1, w1, 1
    b.ne        .loop
    mov         w0, 0
.done: 
    mov         w1, 0
    stp         x0, x1, [sp, #48]
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    add         sp, sp, #48
    ret

macro timer_start addr {
    sub         sp, sp, #16
    adr         x25, addr
    mov         x26, 0
    stp         x25, x26, [sp]
    bl          timer_start
    ldp         x25, x26, [sp]
    add         sp, sp, #16
}

; =========================================================
;
; timer_reset
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
timer_reset:
    sub         sp, sp, #48
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    adr         x0, timers
    mov         w1, TIMER_COUNT
    mov         w3, 0
.loop:
    ldr         w2, [x0], 4
    cbz         w2, .next
    str         w3, [x2, TIMER_TIMEOUT]
.next:
    subs        w1, w1, 1
    b.ne        .loop
.done: 
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    add         sp, sp, #48
    ret

macro timer_reset {
    bl          timer_reset
}

; =========================================================
;
; timer_update
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
timer_update:
    sub         sp, sp, #64
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    stp         x5, x6, [sp, #48]
    pload       x4, w4, arm_timer_counter
    adr         x0, timers
    mov         w1, TIMER_COUNT
.loop:
    ldr         w2, [x0], 4     ; ptr to timer
    cbz         w2, .next
    ldr         w3, [x2, TIMER_STATUS]
    tst         w3, F_TIMER_ENABLED
    b.eq        .next
    ldr         w3, [x2, TIMER_TIMEOUT]
    cbz         w3, .reset
    ldr         w5, [x4]
    cmp         w5, w3
    b.cc        .next
    ldr         w3, [x2, TIMER_STATUS]
    bic         w3, w3, F_TIMER_ENABLED
    str         w3, [x2, TIMER_STATUS]
    ldr         w3, [x2, TIMER_CALLBACK]
    cbz         w3, .next
    blr         x3
.reset:
    ldr         w3, [x2, TIMER_DURATION]
    ldr         w5, [x4]
    add         w3, w5, w3
    str         w3, [x2, TIMER_TIMEOUT]
.next:    
    subs        w1, w1, 1
    b.ne        .loop
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    ldp         x5, x6, [sp, #48]
    add         sp, sp, #64
    ret

; =========================================================
;
; timer_init
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
timer_init:
    sub         sp, sp, #32
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    pload       x0, w0, arm_timer_controller
    pload       x1, w1, timer_settings1
    str         w1, [x0]
    pload       x1, w1, timer_settings2
    str         w1, [x0]
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    add         sp, sp, #32
    ret
