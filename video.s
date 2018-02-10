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
; Macros
;
; =========================================================
struc string text* {
        .       db  text
        .size   =   $ - .
}

struc font width*, height*, ptr* {
        .width:         dw      width
        .height:        dw      height
        .w_stride:      dw      SCREEN_WIDTH - width
        .h_stride:      dw      (SCREEN_WIDTH * height) - width
        .ptr:           dw      ptr
}

macro clear color {
        mov     w2, color
        bl      clear_screen        
}

macro text ypos, xpos, str, len, color {
        sub     sp, sp, #48
        mov     w1, ypos
        mov     w2, xpos
        stp     x1, x2, [sp]
        adr     x1, str
        mov     x2, len
        stp     x1, x2, [sp, #16]
        mov     x1, color
        mov     x2, 0
        stp     x1, x2, [sp, #32]        
        bl      draw_string
        add     sp, sp, #48        
}

macro stamp ypos, xpos, tile, pal {
        sub     sp, sp, #32
        mov     w1, ypos
        mov     w2, xpos
        stp     x1, x2, [sp]
        mov     w3, tile
        mov     w4, pal
        stp     x3, x4, [sp, #16]
        bl      draw_stamp
        add     sp, sp, #32
}

macro sprite number, ypos, xpos, tile, pal, flags {
        adr     x0, sprite_control
        mov     w1, 6 * 4
        mov     w2, number
        mul     x1, x1, x2
        add     x0, x0, x1
        mov     w1, tile
        mov     w2, ypos
        mov     w3, xpos
        mov     w4, pal
        mov     w5, flags
        str     w1, [x0], 4
        str     w2, [x0], 4
        str     w3, [x0], 4
        str     w4, [x0], 4
        str     w5, [x0], 4
}

macro tile ypos, xpos, tile, pal {
        sub     sp, sp, #32
        mov     w1, ypos
        mov     w2, xpos
        stp     x1, x2, [sp]
        mov     w3, tile
        mov     w4, pal
        stp     x3, x4, [sp, #16]
        bl      draw_tile
        add     sp, sp, #32
}

macro lbb {
        ldr     w2, page
        ldr     w3, page_bytes
        mul     x2, x2, x3
        adr     x1, frame_buffer.data1
        ldr     w0, [x1]
        add     w0, w0, w2
}

; =========================================================
;
; Data Section
;
; =========================================================
align 16
frame_buffer_commands:
        dw                      frame_buffer_commands_end - frame_buffer_commands
        fb_request              bus_cmd 0

        physical_display        bus_cmd Set_Physical_Display,   8,   SCREEN_WIDTH, SCREEN_HEIGHT
        virtual_buffer          bus_cmd Set_Virtual_Buffer,     8,   SCREEN_WIDTH, SCREEN_HEIGHT * 2
        color_depth             bus_cmd Set_Depth,              4,   8
        init_virtual_offset     bus_cmd Set_Virtual_Offset,     8,   0,            0
        palette                 bus_cmd Set_Palette,          264,   0,            64

        palette_data:        
                ; N.B. palette format is ABGR!
                ; palette 1
                dw $00ff9224, $ff0000ff, $ff0000b6, $ff4900ff 
                dw $ff2492db, $ff6d0000, $ff496d6d, $ff244949 
                dw $ff6d0000, $ff000000, $ff246ddb, $ff00246d 
                dw $ff004992, $ff004900, $ff006d00, $ffffffff    

                ; palette 2
                dw $0000496d, $ff002492, $ff0092db, $ff002449
                dw $ff006db6, $ff00246d, $ff006d00, $ffb62400 
                dw $ffffffff, $ff000000, $ffff9224, $ff0000ff 
                dw $ff6d6d6d, $ff494949, $ff6d0000, $ffffffff

                ; palette 3
                dw $00000000, $ffff9200, $ff6d0000, $ff4900ff
                dw $ff002492, $ff494949, $ff496d6d, $ff244949
                dw $ffffffff, $ff000000, $ff246ddb, $ff00246d
                dw $ff004992, $ff004900, $ff006d00, $ffffffff

                ; palette 4
                dw $00ff9224, $ff0000ff, $ff0092db, $ff4900ff
                dw $ff0049b6, $ff00246d, $ff496d6d, $ff494949
                dw $ff0000b6, $ff000000, $ff246ddb, $ff00246d
                dw $ff004992, $ff004900, $ff006d00, $ffffffff

        frame_buffer            bus_cmd Allocate_Buffer,        8,   0,            0

        fb_end_marker           bus_cmd 0
frame_buffer_commands_end:

align 16
set_virtual_offset_commands:
        dw                      set_virtual_offset_commands_end - set_virtual_offset_commands
        set_vo_request          bus_cmd 0

        virtual_offset          bus_cmd Set_Virtual_Offset,     8,   0,            0

        set_vo_end_marker       bus_cmd 0
set_virtual_offset_commands_end:

align 8
sys_font \
        font    8, 8, sys_font_ptr

align 8
sys_font_ptr:   
        include 'font8x8.s'

align 8
page:           
        dw      1
page_bytes:     
        dw      SCREEN_WIDTH * SCREEN_HEIGHT

; =========================================================
;
; video_init
;
; stack:
;   (none)
;
; registers:
;   w0 is set to frame_buffer pointer upon return
;
; =========================================================
video_init:
        mov     x1, MAIL_BASE
        orr     x1, x1, PERIPHERAL_BASE

.wait1: ldr     x2, [x1, MAIL_STATUS]
        tst     x2, MAIL_FULL
        b.ne    video_init.wait1

        mov     w0, frame_buffer_commands + MAIL_TAGS
        str     w0, [x1, MAIL_WRITE]

.wait2: ldr     x2, [x1, MAIL_STATUS]
        tst     x2, MAIL_EMPTY
        b.ne    video_init.wait2
        ldr     x2, [x1, MAIL_READ]

        ldr     w0, [frame_buffer.data1]
        b2p     w0
        adr     x1, frame_buffer.data1
        str     w0, [x1]
        ret

; =========================================================
;
; page_swap
;
; stack:
;   (none)
;
; registers:
;   (none)
;             
; =========================================================
page_swap:
        adr     x3, virtual_offset.indicator
        mov     x2, 0
        str     x2, [x3]
        adr     x3, virtual_offset.data2
        adr     x1, page
        ldr     w2, [x1]
        cbz     w2, page_swap.page_1
        mov     w2, 0
        str     w2, [x1]
        mov     w2, 480
        str     w2, [x3]
        b       page_swap.set_offset
.page_1:
        mov     w2, 1
        str     w2, [x1]
        mov     w2, 0
        str     w2, [x3]
.set_offset:
.wait1: ldr     x2, [x1, MAIL_STATUS]
        tst     x2, MAIL_FULL
        b.ne    page_swap.wait1

        mov     w0, set_virtual_offset_commands + MAIL_TAGS
        str     w0, [x1, MAIL_WRITE]

.wait2: ldr     x2, [x1, MAIL_STATUS]
        tst     x2, MAIL_EMPTY
        b.ne    page_swap.wait2
        ldr     x2, [x1, MAIL_READ]
        ret

; =========================================================
;
; draw_filled_rect
;
; stack:
;   (none)
;
; registers:
;   w2 is the palette index to fill
;   w3 is y
;   w4 is x
;   w5 is width
;   w6 is height
;             
; =========================================================
draw_filled_rect:
        lbb     
        mov     w6, SCREEN_WIDTH
        mul     w0, w6, w3
        add     w0, w0, w4
.row:        
        mov     w7, w5
.pixel:
        strb    x2, [x0], 1
        subs    w7, w7, 1
        b.ne    draw_filled_rect.pixel
        add     w0, w0, SCREEN_WIDTH
        sub     w0, w0, w5
        subs    w6, w6, 1
        b.ne    draw_filled_rect.row
        ret

; =========================================================
;
; draw_hline
;
; stack:
;   (none)
;
; registers:
;   w2 is the palette index to fill
;   w3 is y
;   w4 is x
;   w5 is width
;             
; =========================================================
draw_hline:
        lbb
        mov     w6, SCREEN_WIDTH
        mul     w0, w6, w3
        add     w0, w0, w4        
.pixel:
        strb    x2, [x0], 1
        subs    w5, w5, 1
        b.ne    draw_hline.pixel
        ret

; =========================================================
;
; draw_vline
;
; stack:
;   (none)
;
; registers:
;   w2 is the palette index to fill
;   w3 is y
;   w4 is x
;   w5 is height
;             
; =========================================================
draw_vline:
        lbb
        mov     w6, SCREEN_WIDTH
        mul     w0, w6, w3
        add     w0, w0, w4        
.pixel:
        strb    x2, [x0], 1
        add     w0, w0, SCREEN_WIDTH - 1
        subs    w5, w5, 1
        b.ne    draw_vline.pixel
        ret

; =========================================================
;
; clear_screen
;
; stack:
;   (none)
;
; registers:
;       w2 is the palette index to fill
;
; =========================================================
clear_screen:
        lbb
        mov     w4, SCREEN_HEIGHT
        mov     w3, SCREEN_WIDTH
        mul     w3, w3, w4
        lsr     w3, w3, 3
.pixel:
        str     x2, [x0], 8
        subs    w3, w3, 1
        b.ne    clear_screen.pixel
        ret

; =========================================================
;
; draw_string
;
; stack frame: 
;   y coordinate
;   x coordinate
;   string address
;   string size
;
; registers:
;   (none)
;
; =========================================================
draw_string:
        lbb
        ldp     x2, x3, [sp]
        mov     w1, SCREEN_WIDTH
        mul     w1, w1, w2
        add     w1, w1, w3
        add     w0, w0, w1

        adr     x1, sys_font.ptr + 8
        ldp     x2, x3, [sp, #16]
        ldr     w10, [sys_font.w_stride]
        ldr     w11, [sys_font.h_stride]
        ldp     x13, x14, [sp, #32]
.raster:     
        ldr     w4, [sys_font.height]
        ldrb    x5, [x2], 1
        add     x5, x1, x5, lsl 6
.row:
        ldr     w12, [sys_font.width]
.pixel:
        ldrb    x6, [x5], 1
        cbz     x6, draw_string.skip
        strb    w13, [x0], 1
        b       draw_string.done
.skip:  add     x0, x0, 1
.done:  subs    w12, w12, 1
        b.ne    draw_string.pixel        
        add     x0, x0, x10
        subs    w4, w4, 1
        b.ne    draw_string.row
        sub     x0, x0, x11
        subs    w3, w3, 1
        b.ne    draw_string.raster
        ret
