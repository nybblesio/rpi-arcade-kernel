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

KERNEL_ABI_BOTTOM = $20000
KERNEL_ABI_SIZE   = $1000
KERNEL_ABI_TOP    = KERNEL_ABI_BOTTOM + KERNEL_ABI_SIZE
GAME_BOTTOM       = KERNEL_ABI_TOP

JOY0_R      = 0
JOY0_L      = 1
JOY0_X      = 2
JOY0_A      = 3
JOY0_RIGHT  = 4
JOY0_LEFT   = 5
JOY0_DOWN   = 6
JOY0_UP     = 7
JOY0_START  = 8
JOY0_SELECT = 9
JOY0_Y      = 10
JOY0_B      = 11

JOY1_R      = 12
JOY1_L      = 13
JOY1_X      = 14
JOY1_A      = 15
JOY1_RIGHT  = 16
JOY1_LEFT   = 17
JOY1_DOWN   = 18
JOY1_UP     = 19
JOY1_START  = 20
JOY1_SELECT = 21
JOY1_Y      = 22
JOY1_B      = 23

macro joy_check offset {
    mov     x26, KERNEL_ABI_BOTTOM
    mov     w27, offset
    add     w26, w26, w27
    ldrb    w26, [x26]
}
