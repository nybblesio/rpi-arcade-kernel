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

LEFT_MARGIN = 7
RIGHT_MARGIN = 7
TOP_MARGIN = 12
BOTTOM_MARGIN = 12

CHARS_PER_LINE = (SCREEN_WIDTH - (LEFT_MARGIN + RIGHT_MARGIN)) / (FONT_WIDTH + 1)
LINES_PER_PAGE = (SCREEN_HEIGHT - (TOP_MARGIN + BOTTOM_MARGIN)) / (FONT_HEIGHT + 1)

; =========================================================
;
; Macros Section
;
; =========================================================
macro con_caret ypos, xpos, color {
    sub     sp, sp, #32
    mov     x20, ypos
    mov     x21, xpos
    stp     x20, x21, [sp]
    mov     x20, color
    mov     x21, 0
    stp     x20, x21, [sp, #16]
    bl      console_caret
}

macro con_write str, len, color {
    sub     sp, sp, #32
    mov     x20, str
    mov     x21, len
    stp     x20, x21, [sp]
    mov     x20, color
    mov     x21, 0
    stp     x20, x21, [sp, #16]
    bl      console_write
}

; =========================================================
;
; Data Section
;
; =========================================================
align 4
console_buffer:
    db  (LINES_PER_PAGE * CHARS_PER_LINE) * 2 dup (CHAR_SPACE, $0f)

align 4
con_line_buffer:
    db CHARS_PER_LINE dup ('*')

align 4
caret_y:        db  0
caret_x:        db  0
caret_color:    db  $f
caret_show:     db  0

strdef con_title_str,     "Arcade Kernel Kit, v0.1"
strdef con_copyright_str, "Copyright (C) 2018 Jeff Panici. All Rights Reserved."
strdef con_license1_str,  "This software is "
strdef con_license2_str,  "licensed"
strdef con_license3_str,  " under the MIT license."

align 16

; =========================================================
;
; console_welcome
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
console_welcome:
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    con_caret   0, 0, $0f
    adr         x0, con_title_str
    ldr         w1, [x0], 4
    con_write   x0, x1, $0f
    con_caret   1, 0, $0f
    adr         x0, con_copyright_str
    ldr         w1, [x0], 4
    con_write   x0, x1, $0f
    con_caret   2, 0, $0f
    adr         x0, con_license1_str
    ldr         w1, [x0], 4
    con_write   x0, x1, $0f
    adr         x0, con_license2_str
    ldr         w1, [x0], 4
    con_write   x0, x1, $03
    adr         x0, con_license3_str
    ldr         w1, [x0], 4
    con_write   x0, x1, $0f
    con_caret   4, 0, $0f
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; console_caret
;
; stack:
;   y pos
;   x pos
;   color
;   pad
;
; registers:
;   (none)
;
; =========================================================
console_caret:
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    pstoreb     x0, w1, caret_y
    pstoreb     x0, w2, caret_x
    pstoreb     x0, w3, caret_color
    ldp         x0, x30, [sp]
    add         sp, sp, #48
    ret
    
; =========================================================
;
; console_write
;
; stack:
;   str_ptr
;   len
;   color
;   pad
;
; registers:
;   (none)
;
; =========================================================
console_write:
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    ldp         x0, x1, [sp, #16]   ; str_ptr, len
    ldp         x2, x3, [sp, #32]   ; color, pad
    ploadb      x4, w4, caret_y
    ploadb      x5, w5, caret_x
    mov         w6, CHARS_PER_LINE
    madd        w6, w6, w4, w5
    mov         w13, 2
    mul         w6, w6, w13
    adr         x7, console_buffer
    add         w7, w7, w6
.loop:
    ldrb        w10, [x0], 1
    strb        w10, [x7], 1
    strb        w2, [x7], 1
    add         w5, w5, 1
    subs        w1, w1, 1
    b.ne        .loop
    pstoreb     x0, w5, caret_x
    ldp         x0, x30, [sp]
    add         sp, sp, #48
    ret

; =========================================================
;
; console_draw
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
console_draw:
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    lbb
    adr         x1, console_buffer
    mov         w2, TOP_MARGIN      ; draw y position 
    mov         w3, LEFT_MARGIN     ;      x position
    mov         w4, LINES_PER_PAGE  ; number of lines to render
    mov         w13, FONT_WIDTH + 1
    adr         x5, con_line_buffer
.row:
    mov         x11, x5
    mov         w6, 0               ; last active color
    mov         w7, CHARS_PER_LINE
    mov         w14, 0
.char:
    ldrb        w9, [x1], 1         ; ascii
    ldrb        w10, [x1], 1        ; color index
    cmp         w9, CHAR_SPACE
    b.eq        .skip
    mov         w14, 1
.skip:    
    cbnz        w6, .check
    mov         w6, w10
    b           .next
.check:
    cmp         w10, w6
    b.ne        .draw
.next:    
    strb        w9, [x11], 1
    subs        w7, w7, 1    
    b.ne        .char
.draw:
    sub         w12, w11, w5
    cbz         w14, .no_draw
    string      x2, x3, x5, x12, x6 
.no_draw:    
    mov         w6, w10
    madd        w3, w12, w13, w3
    mov         x11, x5
    cbnz        w7, .next
    add         w2, w2, FONT_HEIGHT + 1
    mov         w3, LEFT_MARGIN
    subs        w4, w4, 1
    b.ne        .row
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret
