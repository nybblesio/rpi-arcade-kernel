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

LEFT_MARGIN = 6
RIGHT_MARGIN = 6
TOP_MARGIN = 10
BOTTOM_MARGIN = 10

CHARS_PER_LINE = (SCREEN_WIDTH - (LEFT_MARGIN + RIGHT_MARGIN)) / FONT_WIDTH
LINES_PER_PAGE = (SCREEN_HEIGHT - (TOP_MARGIN + BOTTOM_MARGIN)) / FONT_HEIGHT

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

strdef con_welcome_str, "Arcade Kernel Kit, v0.1"

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
    adr         x0, con_welcome_str
    ldr         x1, [x0], 4
    con_write   x0, x1, $0f
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
    ldp         x6, x7, [sp, #16]
    ldp         x8, x9, [sp, #32]
    ploadb      x0, w1, caret_y
    ploadb      x0, w2, caret_x
    lsl         w11, w2, 1
    mov         w3, CHARS_PER_LINE * 2
    madd        w4, w3, w1, w11
    adr         x5, console_buffer
    add         w5, w5, w4
.loop:
    ldrb        w10, [x6], 1
    strb        w10, [x5], 1
    strb        w8, [x5], 1
    add         w2, w2, 1
    subs        w7, w7, 1
    b.ne        .loop
    pstoreb     x0, w2, caret_x
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
    adr         x5, con_line_buffer
.row:
    mov         x11, x5
    mov         w6, 0               ; last active color
    mov         w7, CHARS_PER_LINE
.char:
    ldrb        w9, [x1], 1         ; ascii
    ldrb        w10, [x1], 1        ; color index
    ;cbnz        w6, .check
    ;mov         w6, w10
    ;b           .next
;.check:
;    cmp         w10, w6
;    b.ne        .draw
.next:    
    strb        w9, [x11], 1
    subs        w7, w7, 1    
    b.ne        .char
.draw:
    sub         w12, w11, w5
    ;string      x2, x3, x5, x12, x6 
    ;mov         w6, w10
    ;add         w3, w3, w12
    ;mov         x11, x5
    ;cbnz        w7, .next
    add         w2, w2, 1
    mov         w3, LEFT_MARGIN
    subs        w4, w4, 1
    b.ne        .row
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret
