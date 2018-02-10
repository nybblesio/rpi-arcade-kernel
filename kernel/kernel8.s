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
include     'timer.s'
include     'dma.s'
include     'mailbox.s'
include     'uart.s'
include     'joy.s'
include     'font.s'
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
.hang:  b       .hang

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
        bl      timer_init
        bl      joy_init

.loop:
        lbb

        bl      page_swap
        b       .loop

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
.loop:  b       .loop

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
.loop:  b       .loop

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
.loop:  b       .loop

; =========================================================
;
; Data Section
;
; =========================================================

CHARS_PER_LINE = SCREEN_WIDTH / 8
LINES_PER_PAGE = SCREEN_HEIGHT / 8

console_buffer:
        db  (LINES_PER_PAGE * CHARS_PER_LINE) * 2 dup (0, 4);

column  db  0
row     db  0

struc caret_t {
        .y      db  0
        .x      db  0
        .color  db  $f
        .show   db  0
}

caret   caret_t

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
