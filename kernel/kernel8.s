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

code64
processor   cpu64_v8
format      binary as 'img'

include     'constants.s'
include     'macros.s'
include     'dma.s'
include     'mailbox.s'
include     'uart.s'
include     'joy.s'
include     'video.s'

; =========================================================
;
; entry point
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================

align   16
org     $0000

start:
        mrs     x0, MPIDR_EL1
        mov     x1, #$ff000000
        bic     x0, x0, x1
        cbz     x0, kernel_core
        sub     x1, x0, #1
        cbz     x1, watchdog_core
        sub     x1, x0, #2
        cbz     x1, core_two
        sub     x1, x0, #3
        cbz     x1, core_three        
.hang:  b       start.hang

; =========================================================
;
; irq_isr
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
irq_isr:
        eret

; =========================================================
;
; fir_isr
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
firq_isr:
        eret

; =========================================================
;
; kernel_core
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
kernel_core:        
        mov     sp, kernel_stack
        add     sp, sp, $40000

        bl      dma_init
        bl      uart_init
        bl      video_init
        bl      joy_init

        ldr     w0, game_init_vector
        cbz     w0, kernel_core.no_game_init
        blr     x0
.no_game_init:

.loop:
        ldr     w0, game_tick_vector
        cbz     w0, kernel_core.no_game_tick
        blr     x0
.no_game_tick:        
        b       kernel_core.loop

; =========================================================
;
; watchdog_core
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
watchdog_core:
        mov     sp, kernel_stack
        add     sp, sp, $30000
.loop:  b       watchdog_core.loop

; =========================================================
;
; core_two
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
core_two:
        mov     sp, kernel_stack
        add     sp, sp, $20000
.loop:  b       core_two.loop

; =========================================================
;
; core_three
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
core_three:
        mov     sp, kernel_stack
        add     sp, sp, $10000
.loop:  b       core_three.loop

; =========================================================
;
; Data Section
;
; =========================================================

; =========================================================
;
; Game Section
;
; =========================================================
org $8000

game_init_vector    dw  0
game_tick_vector    dw  0

; =========================================================
;
; Stack Section
;
; The kernel stack frame starts at $10000000 and ends at
; $ffc0000, which is the last 256kb of the first 256MB of RAM
; on the Raspberry Pi 3.
;
; Each processor core gets a 64kb stack frame within this
; block of RAM.
;
; =========================================================
org $10000000       ; 256MB

kernel_stack:
        db  $40000 dup(0)
