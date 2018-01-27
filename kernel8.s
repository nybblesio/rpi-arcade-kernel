; -------------------------------------------------------------------------
;
; nybbles arcade kernel
; raspberry pi 3
;
; -------------------------------------------------------------------------

code64
processor   cpu64_v8
format      binary as 'img'
include     'lib/macros.inc'
include     'lib/r_pi2.inc'

; -------------------------------------------------------------------------
;
; constants
;
; -------------------------------------------------------------------------
SCREEN_WIDTH            = 640
SCREEN_HEIGHT           = 480
SCREEN_BITS_PER_PIXEL   = 8

SYSTEM_FONT_SIZE        = 8

; -------------------------------------------------------------------------
;
; macros
;
; -------------------------------------------------------------------------
macro bus_to_phys reg {
        and     w0, w0, $3fffffff
}

; -------------------------------------------------------------------------
;
; entry point
;
; -------------------------------------------------------------------------

        org     $0000
        b       multi_core_start

; -------------------------------------------------------------------------
;
; structures, variables, and dragons -- oh my!
;
; -------------------------------------------------------------------------
struc string text* {
        .       db  text
        .size   =   $ - .
}

struc bus_cmd tag*, size, data1, data2 {
        .tag    dw  tag

        if ~size eq
                .size   dw  size
                .flags  dw  size
        end if

        if ~data1 eq
                .data1  dw  data1
        end if

        if ~data2 eq
                .data2  dw  data2
        end if
}

align 16
frame_buffer_commands:
        dw                  frame_buffer_commands_end - frame_buffer_commands

        start_marker        bus_cmd     0
        physical_display    bus_cmd     Set_Physical_Display, 8, SCREEN_WIDTH, SCREEN_HEIGHT
        virtual_buffer      bus_cmd     Set_Virtual_Buffer,   8, SCREEN_WIDTH, SCREEN_HEIGHT
        color_depth         bus_cmd     Set_Depth,            4,   8
        virtual_offset      bus_cmd     Set_Virtual_Offset,   8,   0,   0
        palette             bus_cmd     Set_Palette,          $10, 0,   2
                            dw          0, $ffffffff
        frame_buffer        bus_cmd     Allocate_Buffer,      8,   0,   0

        end_marker          bus_cmd     0
frame_buffer_commands_end:

align 8
title                       string      "Nybbles Arcade Kernel"

align 8
system_font:
        include             'font8x8.s'
        
; -------------------------------------------------------------------------
;
; multi-core start up
;
; -------------------------------------------------------------------------
multi_core_start:
        mrs         x0, MPIDR_EL1
        ands        x0, x0, 3
        b.ne        core_busy_loop
        b           main_core_start
core_busy_loop:
        b           core_busy_loop

main_core_start:
        nop

; XXX: need to refactor this to check the mailbox status
;
frame_buffer_init:
        mov         w0, frame_buffer_commands + MAIL_TAGS
        mov         x1, MAIL_BASE
        orr         x1, x1, PERIPHERAL_BASE        
        str         w0, [x1, MAIL_WRITE + MAIL_TAGS]
        ldr         w0, [frame_buffer.data1]
        cbz         w0, frame_buffer_init
        bus_to_phys w0
        adr         x1, frame_buffer.data1
        str         w0, [x1]

; XXX: for testing only
;
        mov         w1, 256 + (SCREEN_WIDTH * 32)
        add         w0, w0, w1
        adr         x1, system_font
        adr         x2, title        
        mov         w3, title.size
draw_string:
        mov         w4, SYSTEM_FONT_SIZE
        ldrb        x5, [x2], 1
        add         x5, x1, x5, lsl 6
draw_char:
        ldr         x6, [x5], SYSTEM_FONT_SIZE
        str         x6, [x0], SYSTEM_FONT_SIZE
        add         x0, x0, SCREEN_WIDTH - SYSTEM_FONT_SIZE
        subs        w4, w4, 1
        b.ne        draw_char
        mov         x4, (SCREEN_WIDTH * SYSTEM_FONT_SIZE) - SYSTEM_FONT_SIZE
        sub         x0, x0, x4
        subs        w3, w3, 1
        b.ne        draw_string

main_core_busy_loop:
        b           main_core_busy_loop
