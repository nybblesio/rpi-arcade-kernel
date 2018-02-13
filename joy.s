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
; Data Section
;
; =========================================================
align 4
joy_state:  dw  0

; =========================================================
;
; joy_read
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
joy_read:
        ldr     w0, [gpio_base]
        mov     w1, GPIO_11
        str     w1, [x0, GPIO_GPSET0]
        delay   32
        mov     w1, GPIO_11
        str     w1, [x0, GPIO_GPCLR0]
        delay   32
        mov     w1, 0
        mov     w2, 15
.loop:  ldr     w3, [x0, GPIO_GPLEV0]
        tst     w3, GPIO_4
        b.ne    .clock
        mov     w3, 1
        lsl     w3, w3, w2
        orr     w1, w1, w3
.clock: mov     w3, GPIO_10
        str     w3, [x0, GPIO_GPSET0]
        delay   32
        mov     w3, GPIO_10
        str     w3, [x0, GPIO_GPCLR0]
        delay   32
        subs    w2, w2, 1
        b.ge    .loop
        adr     x0, joy_state
        str     w1, [x0]
        ret

; =========================================================
;
; joy_init
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
joy_init:
        ldr     w0, [gpio_base]
        mov     w1, GPIO_FSEL0_OUT + GPIO_FSEL1_OUT
        str     w1, [x0, GPIO_GPFSEL1]
        ret

