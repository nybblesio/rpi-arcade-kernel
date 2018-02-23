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
; Structure Section
;
; =========================================================
struc caret_t {
        .y      db  0
        .x      db  0
        .color  db  $f
        .show   db  0
}

; =========================================================
;
; Data Section
;
; =========================================================
align 4
console_buffer:
        db  (LINES_PER_PAGE * CHARS_PER_LINE) * 2 dup (0, 4)

align 4
con_line_buffer:
        db CHARS_PER_LINE dup (0)

align 4        
con_line_buffer_offset: db  0

align 8
caret   caret_t

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
        sub     sp, sp, #16
        stp     x0, x30, [sp]

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

        ldp     x0, x30, [sp]
        add     sp, sp, #16
        ret
