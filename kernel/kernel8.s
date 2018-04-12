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
include 'font.s'
include 'pool.s'
include 'dma.s'
include 'util.s'
include 'uart.s'
include 'timer.s'
include 'mailbox.s'
include 'video.s'
include 'console.s'
include 'string.s'
include 'joy.s'
include 'interrupt.s'
include 'terminal.s'
include 'command.s'

align 4

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
    uart_nl
    bl          term_prompt
    bl          console_welcome

.loop:
    bl          timer_update
    bl          term_update
    page_ld
    ploadb      x1, w1, game_enabled
    cbz         w1, .no_game
    pload       x1, w1, game_tick_vector
    cbz         w1, .no_game
    bl          joy_read
    blr         x1
    b           .skip

.no_game:    
    bl          page_clear
    bl          console_draw
    bl          caret_draw
    
.skip:    
    bl          watches_draw
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
; Data Section
;
; =========================================================

; =========================================================
;
; Kernel/Game Interface Section
;
; =========================================================
game_enabled:   db 0

align 4
joy0_state: dw 0
joy1_state: dw 0

org KERNEL_ABI_BOTTOM

include 'kernel_abi_constants.s'

joy0_r:     db 0
joy0_l:     db 0
joy0_x:     db 0
joy0_a:     db 0
joy0_right: db 0
joy0_left:  db 0
joy0_down:  db 0
joy0_up:    db 0
joy0_start: db 0
joy0_select:db 0
joy0_y:     db 0
joy0_b:     db 0

joy1_r:     db 0
joy1_l:     db 0
joy1_x:     db 0
joy1_a:     db 0
joy1_right: db 0
joy1_left:  db 0
joy1_down:  db 0
joy1_up:    db 0
joy1_start: db 0
joy1_select:db 0
joy1_y:     db 0
joy1_b:     db 0

watches:
rept 32 {
    dh  0 ;ypos
    dh  0 ;xpos
    db  0 ;flags
    db  0 ;len
    db  0 ;pad
    db  0 ;pad
    dw  0 ;str ptr
}

org KERNEL_ABI_TOP

game_top:

game_load_vector:   dw  0
game_unload_vector: dw  0
game_tick_vector:   dw  0
game_run_vector:    dw  0
game_stop_vector:   dw  0

title:            db    32 dup(?)
author:           db    32 dup(?)
version:          db    0
revision:         db    0

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
