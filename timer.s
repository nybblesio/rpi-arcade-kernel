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

ARM_TIMER_CTL = $b408
ARM_TIMER_CNT = $b420

; =========================================================
;
; Data Section
;
; =========================================================
timer_settings1 dw  $f90000
timer_settings2 dw  $f90200

; =========================================================
;
; timer_tick
;
; stack:
;   (none)
;
; registers:
;   x1 address to timer control register
;   w20 return tick value
;
; =========================================================
timer_tick:
        mov     x1, ARM_TIMER_CNT
        orr     x1, x1, PERIPHERAL_BASE
        ldr     w20, [x1]
        ret

; =========================================================
;
; timer_init
;
; stack:
;   (none)
;
; registers:
;   x1 address to timer control register
;   w20 scratch register
;
; =========================================================
timer_init:
        mov     x1, ARM_TIMER_CTL
        orr     x1, x1, PERIPHERAL_BASE
        mov     w20, timer_settings1
        str     w20, [x1]
        mov     w20, timer_settings2
        str     w20, [x1]
        ret

