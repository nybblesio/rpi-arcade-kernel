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

org     $0000

    b   start

include 'constants.s'
include 'macros.s'
include 'pool.s'
include 'timer.s'
include 'dma.s'
include 'mailbox.s'
include 'uart.s'
include 'joy.s'
include 'font.s'
include 'util.s'
include 'video.s'
include 'interrupt.s'
include 'terminal.s'
include 'command.s'
include 'console.s'

align 16

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
start:
    mrs         x0, MPIDR_EL1
    mov         x1, #$ff000000
    bic         x0, x0, x1
    cbz         x0, kernel_core
    sub         x1, x0, #1
    cbz         x1, watchdog_core
    sub         x1, x0, #2
    cbz         x1, core_two
    sub         x1, x0, #3
    cbz         x1, core_three        
.hang:  
    b           .hang

; =========================================================
;
; kernel_core (core #0)
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
kernel_core:        
    mov         sp, kernel_stack

    bl          dma_init
    bl          timer_init
    bl          uart_init
    bl          joy_init
    bl          video_init
    bl          cmd_reset_func
        
.loop:
    ;bl         joy_read
    bl          terminal_update
    bl          console_draw
    bl          page_swap
    b           .loop

; =========================================================
;
; watchdog_core (core #1)
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
watchdog_core:
    mov         sp, kernel_stack
    sub         sp, sp, CORE_STACK_SIZE * 1
.loop:  
    b           .loop

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
    mov         sp, kernel_stack
    sub         sp, sp, CORE_STACK_SIZE * 2
.loop:  
    b           .loop

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
    mov         sp, kernel_stack
    sub         sp, sp, CORE_STACK_SIZE * 3
.loop:  
    b           .loop

; =========================================================
;
; Game Interface Section
;
; =========================================================
include 'game_abi.s'

org GAME_ABI_BOTTOM

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
STACK_TOP = $10000000
CORE_STACK_SIZE = $10000
CORE_COUNT = 4
STACK_SIZE = CORE_STACK_SIZE * CORE_COUNT

org STACK_TOP - STACK_SIZE

    db  STACK_SIZE dup(0)

kernel_stack:
