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
macro page_ld {
    pload       x0, w0, frame_buffer.data1
    pload       x1, w1, page
    pload       x2, w2, page_bytes
    madd        w0, w1, w2, w0
}

macro string ypos, xpos, str, len, color {
    sub         sp, sp, #48
    mov         x20, ypos
    mov         x21, xpos
    stp         x20, x21, [sp]
    mov         x20, str
    mov         x21, len
    stp         x20, x21, [sp, #16]
    mov         x20, color
    mov         x21, 0
    stp         x20, x21, [sp, #32]
    bl          draw_string
}

; =========================================================
;
; Data Section
;
; =========================================================
align 16
frame_buffer_commands:
    dw                      frame_buffer_commands_end - frame_buffer_commands
    fb_request              mail_command_t 0

    physical_display        mail_command_t Set_Physical_Display,   8,   SCREEN_WIDTH, SCREEN_HEIGHT
    virtual_buffer          mail_command_t Set_Virtual_Buffer,     8,   SCREEN_WIDTH, SCREEN_HEIGHT * 2
    color_depth             mail_command_t Set_Depth,              4,   8
    init_virtual_offset     mail_command_t Set_Virtual_Offset,     8,   0,            0
    palette                 mail_command_t Set_Palette,          264,   0,            64

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

    frame_buffer            mail_command_t Allocate_Buffer,        8,   0,            0

    fb_end_marker           mail_command_t 0
frame_buffer_commands_end:

align 16
set_virtual_offset_commands:
    dw                      set_virtual_offset_commands_end - set_virtual_offset_commands
    set_vo_request          mail_command_t 0

    virtual_offset          mail_command_t Set_Virtual_Offset,     8,   0,            0

    set_vo_end_marker       mail_command_t 0
set_virtual_offset_commands_end:

align 4
page:       dw  1
page_bytes: dw  SCREEN_WIDTH * SCREEN_HEIGHT
fps:        dw  0
fps_count:  dw  0

timerdef    timer_fps, 2, 1000, video_fps_callback

dmadef      clear_page, \
            DMA_TDMODE + DMA_DEST_INC + DMA_DEST_WIDTH + DMA_SRC_INC + DMA_SRC_WIDTH, \
            SCREEN_WIDTH + ((SCREEN_HEIGHT - 1) * 65536), \
            65536

align 4

; =========================================================
;
; video_fps_callback
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
video_fps_callback:
    sub         sp, sp, #32
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    pload       x0, w0, fps_count
    pstore      x1, w0, fps
    mov         w0, 0
    pstore      x1, w0, fps_count
    mov         w1, F_TIMER_ENABLED
    adr         x0, timer_fps
    str         w1, [x0, TIMER_STATUS]
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    add         sp, sp, #32
    ret

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
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    adr         x0, frame_buffer_commands
    bl          write_mailbox
    ldr         w0, [frame_buffer.data1]
    b2p         w0
    adr         x1, frame_buffer.data1
    str         w0, [x1]
    timer_start timer_fps
    ldp         x0, x30, [sp]
    add         sp, sp, #16
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
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    pload       x2, w1, page
    cbz         w1, .page_1
    mov         w1, 0
    pstore      x2, w1, page
    mov         w1, SCREEN_HEIGHT
    pstore      x2, w1, virtual_offset.data2
    b           .set_offset
.page_1:
    mov         w1, 1
    pstore      x2, w1, page
    mov         w1, 0
    pstore      x2, w1, virtual_offset.data2
.set_offset:
    mov         w1, 0
    pstore      x2, w1, set_vo_request.tag
    pstore      x2, w1, virtual_offset.indicator
    adr         x0, set_virtual_offset_commands
    bl          write_mailbox
    pload       x0, w0, fps_count
    add         w0, w0, 1
    pstore      x1, w0, fps_count
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; page_clear
;
; stack:
;   x0, x30 saved
;
; registers:
;   w1, w2 scratch registers
;
; =========================================================
page_clear:
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    mov         w1, 0
    mov         w2, (SCREEN_HEIGHT * SCREEN_WIDTH) / 8
.pixel:
    str         x1, [x0], 8
    subs        w2, w2, 1
    b.ne        .pixel
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; draw_filled_rect
;
; stack:
;   y pos
;   x pos
;   width
;   height
;   color
;   pad
;
; registers:
;
; =========================================================
draw_filled_rect:
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    ldp         x5, x6, [sp, #48]
    mov         w7, SCREEN_WIDTH
    madd        w8, w1, w7, w2
    add         w0, w0, w8
.row:   
    mov         w8, w3
.pixel: 
    strb        w5, [x0], 1
    subs        w8, w8, 1
    b.ne        .pixel
    add         w0, w0, SCREEN_WIDTH
    sub         w0, w0, w3
    subs        w4, w4, 1
    b.ne        .row
    ldp         x0, x30, [sp]
    add         sp, sp, #64 
    ret

; =========================================================
;
; draw_hline
;
; stack:
;   (none)
;
; registers:
;   w1 color
;   w2 y
;   w3 x
;   w4 width
;   w29 page pointer             
;
;   w20 scratch register
;
; =========================================================
draw_hline:
    mov         w20, SCREEN_WIDTH
    madd        w20, w20, w1, w2
    add         w29, w29, w20        
.pixel: 
    strb        x2, [x29], 1
    subs        w4, w4, 1
    b.ne        .pixel
    ret

; =========================================================
;
; draw_vline
;
; stack:
;   (none)
;
; registers:
;   w1 is the palette index to fill
;   w2 is y
;   w3 is x
;   w4 is height
;   w29 page buffer pointer
;            
;   w20 scratch register
;
; =========================================================
draw_vline:
    mov         w20, SCREEN_WIDTH
    madd        w20, w20, w2, w3
    add         w29, w29, w20        
.pixel: 
    strb        w2, [x29], 1
    add         w29, w29, SCREEN_WIDTH - 1
    subs        w4, w4, 1
    b.ne        .pixel
    ret

; =========================================================
;
; draw_string
;
; stack frame:
;  
;   y position
;   x position
;   pointer to string
;   string length
;   color
;   pad
;
; registers:
;   w0 has back buffer pointer  
;
; =========================================================
draw_string:
    sub         sp, sp, #112
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    stp         x5, x6, [sp, #48]
    stp         x7, x8, [sp, #64]
    stp         x9, x10, [sp, #80]
    stp         x11, x12, [sp, #96]
    ldp         x1, x2, [sp, #112]  ; y, x
    ldp         x3, x4, [sp, #128]  ; str_ptr, len
    ldp         x5, x6, [sp, #144]  ; color, pad

    mov         w6, SCREEN_WIDTH
    madd        w6, w6, w1, w2
    add         w0, w0, w6
    mov         w6, w0
    adr         x7, nitram_micro_font
.char:  
    mov         w8, FONT_HEIGHT
    ldrb        w9, [x3], 1
    cmp         w9, CHAR_SPACE
    b.eq        .next_char
    cmp         w9, 0
    b.eq        .next_char
    madd        w9, w9, w8, w7
.row:   
    ldrb        w10, [x9], 1
    mov         w11, 00000000_00000000_00000000_00010000b
.pixel: 
    ands        w12, w10, w11
    b.eq        .next
    strb        w5, [x0]
.next:  
    add         x0, x0, 1
    lsr         w11, w11, 1
    cbnz        w11, .pixel
    add         x0, x0, SCREEN_WIDTH - FONT_WIDTH
    subs        w8, w8, 1
    b.ne        .row
.next_char:    
    add         w6, w6, FONT_WIDTH + 1
    mov         w0, w6
    subs        w4, w4, 1
    b.ne        .char

    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    ldp         x5, x6, [sp, #48]
    ldp         x7, x8, [sp, #64]
    ldp         x9, x10, [sp, #80]
    ldp         x11, x12, [sp, #96]
    add         sp, sp, #160
    ret
