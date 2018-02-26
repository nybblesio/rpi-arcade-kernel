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
; Data Section
;
; =========================================================
timer_settings1 dw  $00f90000
timer_settings2 dw  $00f90200

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

