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

TIMER_COUNT      = 32;

F_TIMER_DISABLED = 00000000_00000000_00000000_00000000b;
F_TIMER_ENABLED  = 00000000_00000000_00000000_00000001b;
F_TIMER_FIRED    = 00000000_00000000_00000000_00000010b;

TIMER_ID       = 0
TIMER_STATUS   = 4
TIMER_DURATION = 8
TIMER_TIMEOUT  = 12
TIMER_CALLBACK = 16

; =========================================================
;
; Macro Section
;
; =========================================================
macro timerdef lbl, id, duration, callback {
    align 4
    label lbl
    dw  id
    dw  F_TIMER_ENABLED
    dw  duration
    dw  0               ; next timeout
    dw  callback
}

; =========================================================
;
; Data Section
;
; =========================================================a
align 4

timer_settings1 dw  $00f90000
timer_settings2 dw  $00f90200

timers:
    dw  TIMER_COUNT dup(0)

; =========================================================
;
; timer_start
;
; stack:
;   (none)
;
; registers:
;   w1 pointer to timer structure
;   w2 is the pointer to the newly added timer
;
; =========================================================
timer_start:
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    adr         x0, timers
    mov         w3, TIMER_COUNT
.loop:
    ldr         w2, [x0]
    cbnz        w2, .next
    str         w1, [x0]
    mov         w2, w0
    b           .done
.next:
    add         x0, x0, 4
    subs        w3, w3, 1
    b.ne        .loop
    mov         w2, 0
.done:    
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

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
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    adr         x10, timers
    mov         w1, TIMER_COUNT
.loop:
    ldr         w2, [x10], 4     ; ptr to timer
    cbz         w2, .next
    ldr         w3, [x2, TIMER_STATUS]
    cmp         w3, F_TIMER_ENABLED
    b.ne        .next
    ldr         w4, [x2, TIMER_TIMEOUT]
    cbz         w4, .reset
    bl          timer_tick
    cmp         w0, w4
    b.cc        .next
    ldr         w5, [x2, TIMER_CALLBACK]
    blr         x5
    ;mov         w6, F_TIMER_FIRED
    ;orr         w3, w3, w6
    ;str         w3, [x2, TIMER_STATUS]
.reset:
    ldr         w3, [x2, TIMER_DURATION]
    bl          timer_tick
    add         w3, w0, w3
    str         w3, [x2, TIMER_TIMEOUT]
.next:    
    subs        w1, w1, 1
    b.ne        .loop
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; timer_tick
;
; stack:
;   (none)
;
; registers:
;   w0 return tick value
;
; =========================================================
timer_tick:
    pload       x0, w0, arm_timer_counter
    ldr         w0, [x0]
    ret

; =========================================================
;
; timer_init
;
; stack:
;   (none)
;
; registers:
;   w0 arm timer controller address
;   w1 timer settings 1 & 2
;
; =========================================================
timer_init:
    pload       x0, w0, arm_timer_controller
    pload       x1, w1, timer_settings1
    str         w1, [x0]
    pload       x1, w1, timer_settings2
    str         w1, [x0]
    ret

