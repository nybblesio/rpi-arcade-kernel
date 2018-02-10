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
macro lbb {
        adr     x1, frame_buffer.data1
        ldr     w0, [x1]
        ldr     w1, page
        ldr     w2, page_bytes
        madd    w0, w1, w2, w0
}

macro clear color {
        mov     w29, w0
        mov     w1, color
        bl      clear_screen        
}

macro string ypos, xpos, str, len, color {
        mov     w29, w0
        mov     w1, ypos
        mov     w2, xpos
        adr     w4, str
        mov     w5, len
        mov     w6, color
        bl      draw_string
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

align 8
page        dw  1
page_bytes  dw  SCREEN_WIDTH * SCREEN_HEIGHT

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
        mov     w0, frame_buffer_commands
        bl      write_mailbox
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
        adr     x2, page
        adr     x3, virtual_offset.data2
        ldr     w1, [x2]
        cbz     w1, .page_1
        mov     w1, 0
        str     w1, [x2]
        mov     w1, 480
        str     w1, [x3]
        b       .set_offset
.page_1:
        mov     w1, 1
        str     w1, [x2]
        mov     w1, 0
        str     w1, [x3]
.set_offset:
        mov     w0, set_virtual_offset_commands        
        bl      write_mailbox
        ret

; =========================================================
;
; draw_filled_rect
;
; stack:
;   (none)
;
; registers:
;   w1 color
;   w2 y
;   w3 x
;   w4 width
;   w5 height
;   w29 page display pointer
;             
;   w20 scratch register
;
; =========================================================
draw_filled_rect:
        mov     w20, SCREEN_WIDTH
        madd    w20, w20, w1, w2
        add     w29, w29, w20        
.row:   mov     w20, w4
.pixel: strb    w2, [x29], 1
        subs    w20, w20, 1
        b.ne    .pixel
        add     w29, w29, SCREEN_WIDTH
        sub     w29, w29, w4
        subs    w5, w5, 1
        b.ne    .row
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
        mov     w20, SCREEN_WIDTH
        madd    w20, w20, w1, w2
        add     w29, w29, w20        
.pixel: strb    x2, [x29], 1
        subs    w4, w4, 1
        b.ne    .pixel
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
        mov     w20, SCREEN_WIDTH
        madd    w20, w20, w2, w3
        add     w29, w29, w20        
.pixel: strb    w2, [x29], 1
        add     w29, w29, SCREEN_WIDTH - 1
        subs    w4, w4, 1
        b.ne    .pixel
        ret

; =========================================================
;
; clear_screen
;
; stack:
;   (none)
;
; registers:
;   w1 color
;   w29 page buffer
;
;   w3, w4  scratch registers
;
; =========================================================
clear_screen:
        mov     w4, SCREEN_HEIGHT
        mov     w3, SCREEN_WIDTH
        mul     w3, w3, w4
        lsr     w3, w3, 3
.pixel:
        str     x1, [x29], 8
        subs    w3, w3, 1
        b.ne    .pixel
        ret

; =========================================================
;
; draw_string
;
; stack frame: 
;   (none)
;
; registers:
;   w1 y position
;   w2 x position
;   w3 pointer to string
;   w4 string length
;   w5 pointer to font bitmap
;   w6 color
;   w29 page buffer
;
;   w20 scratch register
;   w21 pointer to font bitmap start
;   w22 size of font glyph in bytes
;   w23 font height counter
;   w24 offset into character glyph
;
; =========================================================
draw_string:
        mov     w20, SCREEN_WIDTH
        madd    w20, w20, w1, w2
        add     w29, w29, w20
        mov     w26, w29
        mov     w21, w5
        mov     w22, FONT_WIDTH * FONT_HEIGHT
.char:  ldrb    w20, [x3], 1
        madd    w24, w20, w22, w21
        mov     w23, FONT_HEIGHT
.row:   ldrb    w25, [x24], 1
        mov     w20, 00000000_00000000_00000000_00010000b
.pixel: tst     w25, w20
        b.eq    .next
        strb    w6, [x29], 1
.next:  lsr     w20, w20, 1
        cbnz    w20, .pixel
        add     w29, w29, SCREEN_WIDTH - FONT_WIDTH
        subs    w23, w23, 1
        b.ne    .row
        add     w26, w26, FONT_WIDTH + 1
        mov     w29, w26
        subs    w4, w4, 1
        b.ne    .char
        ret
