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
; send_command_prompt
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
send_command_prompt:
        sub     sp, sp, #16
        stp     x0, x30, [sp]
        uart_char   '>'
        uart_space
        ldp     x0, x30, [sp]
        add     sp, sp, #16
        ret

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

        bl      send_command_prompt
        
.loop:
        bl      uart_recv
        cbz     w1, .console

        cmp     w1, LINEFEED_CHAR
        b.eq    .return
        cmp     w1, BACKSPACE_CHAR
        b.eq    .bs
        bl      uart_send
        b       .console

.return:
        bl      uart_send
        bl      send_command_prompt
        b       .console

.bs:    uart_char   BACKSPACE_CHAR
        uart_string delete_char
        b       .console

.console:        
        ;bl      joy_read
        lbb
         
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
 
        bl      page_swap
        b       .loop

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
        mov     sp, kernel_stack
        sub     sp, sp, CORE_STACK_SIZE * 1
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
        sub     sp, sp, CORE_STACK_SIZE * 2
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
        sub     sp, sp, CORE_STACK_SIZE * 3
.loop:  b       .loop

; =========================================================
;
; Data Section
;
; =========================================================
BACKSPACE_CHAR  = $08
RETURN_CHAR     = $0d
LINEFEED_CHAR   = $0a

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

TERM_CLS        equ $1b, "[2J"
TERM_CURPOS11   equ $1b, "[1;1H"
TERM_REVERSE    equ $1b, "[7m"
TERM_NOATTR     equ $1b, "[m"
TERM_UNDERLINE  equ $1b, "[4m"
TERM_BLINK      equ $1b, "[5m"
TERM_BOLD       equ $1b, "[1m"
TERM_DELCHAR    equ $1b, "[1P"
TERM_NEWLINE    equ $0d, $0a
TERM_NEWLINE2   equ $0d, $0a, $0d, $0a

delete_char:        strdef  TERM_DELCHAR

clr_screen:         strdef  TERM_CLS, TERM_CURPOS11

kernel_title:       strdef  TERM_REVERSE, \
                            "                Arcade Kernel Kit, v0.1              ", TERM_NOATTR, TERM_NEWLINE

kernel_copyright:   strdef  "Copyright (C) 2018 Jeff Panici.  All rights reserved.", TERM_NEWLINE

kernel_license1:    strdef  "This software is licensed under the MIT license.", TERM_NEWLINE

kernel_license2:    strdef  "See the LICENSE file for details.", TERM_NEWLINE2

kernel_help:        strdef  "Use the ", TERM_BOLD, TERM_UNDERLINE, "help", TERM_NOATTR, \
                                " command to learn more about how the", TERM_NEWLINE, \
                                "serial console works.", TERM_NEWLINE2

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
