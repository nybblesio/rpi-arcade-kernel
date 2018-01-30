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
SCREEN_WIDTH            = 512
SCREEN_HEIGHT           = 480
SCREEN_BITS_PER_PIXEL   = 8

; -------------------------------------------------------------------------
;
; macros & structures
;
; -------------------------------------------------------------------------
macro bus_to_phys reg {
        and     w0, w0, $3fffffff
}

macro delay cycles {
        local   .loop
        mov     w12, cycles
.loop:  subs    w12, w12, 1
        b.ne    .loop        
}

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

struc dma_control flags*, len, stride {
        .flags  dw      flags
        .src    dw      0
        .dest   dw      0
        if len eq
                .len    dw      0
        else
                .len    dw      len
        end if
        if stride eq
                .stride dw      0
        else                                 
                .stride dw      stride
        end if                
        .next   dw      0
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
; variables and dragons!
;
; -------------------------------------------------------------------------
align 16
frame_buffer_commands:
        dw                      frame_buffer_commands_end - frame_buffer_commands

        start_marker            bus_cmd 0
        physical_display        bus_cmd Set_Physical_Display,   8,   SCREEN_WIDTH, SCREEN_HEIGHT
        virtual_buffer          bus_cmd Set_Virtual_Buffer,     8,   SCREEN_WIDTH, SCREEN_HEIGHT
        color_depth             bus_cmd Set_Depth,              4,   8
        virtual_offset          bus_cmd Set_Virtual_Offset,     8,   0,            0
        palette                 bus_cmd Set_Palette,          264,   0,            64
        palette_data:        
                ; palette 1
                dw $2492ff00, $ff0000ff, $b60000ff, $ff0049ff 
                dw $db9224ff, $00006dff, $6d6d49ff, $494924ff 
                dw $00006dff, $000000ff, $db6d24ff, $6d2400ff 
                dw $924900ff, $004900ff, $006d00ff, $ffffffff    

                ; palette 2
                dw $6d490000, $922400ff, $db9200ff, $492400ff
                dw $b66d00ff, $6d2400ff, $006d00ff, $0024b6ff 
                dw $ffffffff, $000000ff, $2492ffff, $ff0000ff 
                dw $6d6d6dff, $494949ff, $00006dff, $ffffffff

                ; palette 3
                dw $00000000, $0092ffff, $00006dff, $ff0049ff
                dw $922400ff, $494949ff, $6d6d49ff, $494924ff
                dw $ffffffff, $000000ff, $db6d24ff, $6d2400ff
                dw $924900ff, $004900ff, $006d00ff, $ffffffff

                ; palette 4
                dw $2492ff00, $ff0000ff, $db9200ff, $ff0049ff
                dw $b64900ff, $6d2400ff, $6d6d49ff, $494949ff
                dw $b60000ff, $000000ff, $db6d24ff, $6d2400ff
                dw $924900ff, $004900ff, $006d00ff, $ffffffff

        frame_buffer            bus_cmd Allocate_Buffer,        8,   0,            0

        end_marker              bus_cmd 0
frame_buffer_commands_end:

align 16
tile_copy       dma_control     DMA_TDMODE + DMA_DEST_INC + DMA_DEST_WIDTH + DMA_SRC_INC + DMA_SRC_WIDTH

align 8
title           string          "Nybbles Arcade Kernel"

align 8
sys_font        font            8, 8, sys_font_ptr

align 8
sys_font_ptr:   include         'font8x8.s'

align 8
timber_bg0:     file            'assets/timbg0.bin'
timber_bg1:     file            'assets/timbg1.bin'
timber_fg0:     file            'assets/timfg0.bin'
timber_fg1:     file            'assets/timfg1.bin'
timber_fg2:     file            'assets/timfg2.bin'
timber_fg3:     file            'assets/timfg3.bin'
timber_fg4:     file            'assets/timfg4.bin'
timber_fg5:     file            'assets/timfg5.bin'
timber_fg6:     file            'assets/timfg6.bin'
timber_fg7:     file            'assets/timfg7.bin'

; -------------------------------------------------------------------------
;
; multi-core start up
;
; -------------------------------------------------------------------------
align 16
multi_core_start:
        mrs         x0, MPIDR_EL1
        ands        x0, x0, 3
        b.ne        core_busy_loop
        b           main_core_start
core_busy_loop:
        b           core_busy_loop

main_core_start:
        ; enable DMA channel 0
        mov         x0, PERIPHERAL_BASE
        orr         x0, x0, DMA_ENABLE
        mov         w1, DMA_EN0
        str         w1, [x0]

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

; ------------------------------
;
;
; ------------------------------
        mov         w1, SCREEN_WIDTH
        mov         w2, 245
        mov         w3, 168
        mul         w1, w1, w2
        add         w1, w1, w3
        add         w0, w0, w1

        adr         x1, sys_font.ptr + 8
        adr         x2, title        
        mov         w3, title.size
        ldr         w10, [sys_font.w_stride]
        ldr         w11, [sys_font.h_stride]
draw_string:
        ldr         w4, [sys_font.height]
        ldr         w12, [sys_font.width]
        ldrb        x5, [x2], 1
        add         x5, x1, x5, lsl 6
draw_char:
        ldr         x6, [x5], 8
        str         x6, [x0], 8
        add         x0, x0, x10
        subs        w4, w4, 1
        b.ne        draw_char
        sub         x0, x0, x11
        subs        w3, w3, 1
        b.ne        draw_string

; ------------------------------
;
;
; ------------------------------
        adr         x1, frame_buffer.data1
        ldr         w0, [x1]
        mov         w1, SCREEN_WIDTH
        mov         w2, 32
        mov         w3, 32
        mul         w1, w1, w2
        add         w1, w1, w3
        add         w0, w0, w1

        adr         x1, timber_fg0
        mov         x5, 512
        mov         w3, 32        
draw_raster:        
        mov         w4, 16
draw_pixels:
        ldrb        x6, [x5], 1
        lsr         x7, x6, 4
        and         x8, x6, $0f
        strb        x7, [x0], 1
        strb        x8, [x0, 1]
        add         x0, x0, 2
        subs        w4, w4, 1
        b.ne        draw_pixels
        add         x0, x0, SCREEN_WIDTH - 32
        subs        w3, w3, 1
        b.ne        draw_raster

main_core_busy_loop:
        b           main_core_busy_loop
