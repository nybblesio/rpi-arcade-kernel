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
include 'video.s'

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
align 16
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

        bl      dma_init
        bl      timer_init
        bl      uart_init
        ;bl      joy_init
        bl      video_init

        uart_string clr_screen
        uart_string kernel_title
        uart_string kernel_copyright
        uart_string kernel_license1
        uart_string kernel_license2
        uart_string kernel_help

        uart_hex    $beef
        uart_space
        uart_char   '>'
        uart_space

        ;
        ; registers w10-w19 are generally free/safe to use
        ;
.loop:
        ; handle the serial interface 
        bl      uart_recv
        cbz     w1, .no_char
        bl      uart_send

.no_char:        
        ;bl      joy_read
        lbb
;        
;        adr     x10, console_buffer
;        mov     w1, 0               ; y position
;        mov     w2, 0               ; x position
;        mov     w16, LINES_PER_PAGE 
;.row:   adr     x3, line_buffer
;        adr     x5, nitram_micro_font
;        mov     w4, 0
;        mov     w15, 0              ; last color
;        mov     w11, CHARS_PER_LINE
;.char:  ldrb    w13, [x10], 1       ; character
;        ldrb    w14, [x10], 1       ; color
;        cmp     w14, w15
;        b.ne    .span
;.span:  mov     w15, w14
;        bl      draw_string
;        adr     x3, line_buffer
;        mov     w4, 0
;        subs    w11, w11, 1
;        b.ne    .char
;        add     w1, w1, FONT_HEIGHT + 1
;        subs    w16, w16, 1
;        b.ne    .loop
;
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
        sub     sp, sp, $10000
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
        sub     sp, sp, $20000
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
        sub     sp, sp, $30000
.loop:  b       .loop

; =========================================================
;
; Data Section
;
; =========================================================

CHARS_PER_LINE = SCREEN_WIDTH / 8
LINES_PER_PAGE = SCREEN_HEIGHT / 8

align 8
console_buffer:
        db  (LINES_PER_PAGE * CHARS_PER_LINE) * 2 dup (0, 4)
column  db  0
row     db  0

align 8
line_buffer:
        db CHARS_PER_LINE dup (0)
lb_offs db  0

struc caret_t {
        .y      db  0
        .x      db  0
        .color  db  $f
        .show   db  0
}

caret   caret_t

align 8
clr_screen:         strdef  $1b, "[2J", $1b, "[1;1H"

align 8
kernel_title:       strdef  $1b, "[7m", \
                            "                Arcade Kernel Kit, v0.1              ", $1b, "[m", $0d, $0a

align 8
kernel_copyright:   strdef  "Copyright (C) 2018 Jeff Panici.  All rights reserved.", $0d, $0a

align 8
kernel_license1:    strdef  "This software is licensed under the MIT license.", $0d, $0a

align 8
kernel_license2:    strdef  "See the LICENSE file for details.", $0d, $0a, $0d, $0a

align 8
kernel_help:        strdef  "Use the ", $1b, "[1m", "help", $1b, "[m", \
                                " command to learn more about how the", $0d, $0a, \
                                "serial console works.", $0d, $0a, $0d, $0a

; =========================================================
;
; Game Interface Section
;
; =========================================================

include 'game_abi.s'

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
org $ffc0000

        db  $40000 dup(0)

kernel_stack:
