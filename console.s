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
    sub         sp, sp, #32
    mov         x25, ypos
    mov         x26, xpos
    stp         x25, x26, [sp]
    mov         x25, color
    mov         x26, 0
    stp         x25, x26, [sp, #16]
    bl          console_caret
}

macro con_write str, len, color {
    sub         sp, sp, #32
    mov         x25, str
    mov         x26, len
    stp         x25, x26, [sp]
    mov         x25, color
    mov         x26, 0
    stp         x25, x26, [sp, #16]
    bl          console_write
}

macro log [params] {
    local       .start, .end, .skip
    b           .skip
.start:
    strlist     params
.end:
    align 4
.skip:    
    con_write   .start, .end - .start, $0f
}

macro log_nl [params] {
    log         params
    bl          console_caret_nl
}

macro log_level level, color, [params] {
    con_write   level, LEVEL_LABEL_LEN, color
    log_nl      params
}

macro info [params] {
    log_level   info_level, $04, params
}

macro debug [params] {
    log_level   debug_level, $04, params
}

macro warn [params] {
    log_level   warn_level, $09, params
}

macro error [params] {
    log_level   error_level, $03, params
}

macro log_reg level, color, reg, name, [params] {
    con_write   level, LEVEL_LABEL_LEN, color
    log         params
    con_write   name, REG_LABEL_LEN, $0f
    str_hex32   reg, number_buffer + 1
    con_write   number_buffer, 9, $0f
    bl          console_caret_nl
}

macro info_reg reg, name, [params] {
    log_reg     info_level, $04, reg, name, params
}

macro debug_reg reg, name, [params] {
    log_reg     debug_level, $04, reg, name, params
}

macro log_label level, color, label, [params] {
    con_write   level, LEVEL_LABEL_LEN, color
    log         params
    adr         x20, label
    str_hex32   w20, number_buffer + 1
    con_write   number_buffer, 9, $0f
    bl          console_caret_nl
}

macro info_label label, [params] {
    log_label   info_level, $04, label, params
}

macro debug_label label, [params] {
    log_label   debug_level, $04, label, params
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
caret_show:     db  1

str_number_buffer:  dw  9
number_buffer:      db  '$', 9 dup(CHAR_SPACE)

REG_LABEL_LEN = 6
reg_w0:  db "w0  = "
reg_w1:  db "w1  = "
reg_w2:  db "w2  = "
reg_w3:  db "w3  = "
reg_w4:  db "w4  = "
reg_w5:  db "w5  = "
reg_w6:  db "w6  = "
reg_w7:  db "w7  = "
reg_w8:  db "w8  = "
reg_w9:  db "w9  = "
reg_w10: db "w10 = "
reg_w11: db "w11 = "
reg_w12: db "w12 = "
reg_w13: db "w13 = "
reg_w14: db "w14 = "
reg_w15: db "w15 = "
reg_w16: db "w16 = "
reg_w17: db "w17 = "
reg_w18: db "w18 = "
reg_w19: db "w19 = "
reg_w20: db "w20 = "
reg_w21: db "w21 = "
reg_w22: db "w22 = "
reg_w23: db "w23 = "
reg_w24: db "w24 = "
reg_w25: db "w25 = "
reg_w26: db "w26 = "
reg_w27: db "w27 = "
reg_w28: db "w28 = "
reg_w29: db "w29 = "
reg_w30: db "w30 = "

reg_joy00: db "j00 = "
reg_joy01: db "j01 = "

LEVEL_LABEL_LEN = 7
info_level:  db " INFO: "
debug_level: db "DEBUG: "
warn_level:  db " WARN: "
error_level: db "ERROR: "

strdef con_title_str,     "Arcade Kernel Kit, v0.1"
strdef con_copyright_str, "Copyright (C) 2018 Jeff Panici. All Rights Reserved."
strdef con_license1_str,  "This software is "
strdef con_license2_str,  "licensed"
strdef con_license3_str,  " under the MIT license."

timerdef timer_caret_blink, 1, 250, caret_blink_callback

align 4

; =========================================================
;
; watches_draw
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
watches_draw:
    sub         sp, sp, #64
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    stp         x5, x6, [sp, #48]
    adr         x1, watches
    mov         w2, 32
.loop:
    ldrb        w3, [x1, WATCH_FLAGS]
    cbz         w3, .skip
    ldrh        w3, [x1, WATCH_Y_POS]
    ldrh        w4, [x1, WATCH_X_POS]
    ldrb        w5, [x1, WATCH_LEN]
    ldr         w6, [x1, WATCH_STR]
    string      w3, w4, w6, w5, $0f
.skip:
    add         w1, w1, WATCH_SZ
    subs        w2, w2, 1
    b.ne        .loop
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    ldp         x5, x6, [sp, #48]
    add         sp, sp, #64
    ret

; =========================================================
;
; caret_draw
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
caret_draw:
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    ploadb      x2, w1, caret_show
    cbz         w1, .skip
    sub         sp, sp, #48
    ploadb      x1, w1, caret_y
    mov         w2, FONT_HEIGHT + 1
    mul         w1, w1, w2
    add         w1, w1, TOP_MARGIN
    ploadb      x2, w2, caret_x
    mov         w3, FONT_WIDTH + 1
    mul         w2, w2, w3
    add         w2, w2, LEFT_MARGIN
    stp         x1, x2, [sp]
    mov         x1, 6
    stp         x1, x1, [sp, #16]
    ploadb      x1, w1, caret_color
    mov         x2, 0
    stp         x1, x2, [sp, #32]
    bl          draw_filled_rect
.skip:
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; caret_blink_callback
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
caret_blink_callback:
    sub         sp, sp, #32
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    ploadb      x0, w0, caret_show
    cbz         w0, .one
    mov         w1, 0
    pstoreb     x0, w1, caret_show
    b           .done
.one:
    mov         w1, 1
    pstoreb     x0, w1, caret_show 
.done: 
    timer_flags timer_caret_blink, F_TIMER_ENABLED
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    add         sp, sp, #32
    ret

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
    con_write   x0, x1, $06
    adr         x0, con_license3_str
    ldr         w1, [x0], 4
    con_write   x0, x1, $0f
    con_caret   4, 0, $0f
    timer_start timer_caret_blink
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; console_caret_nl
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
console_caret_nl:
    sub         sp, sp, #48
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    mov         w2, LINES_PER_PAGE
    ploadb      x0, w0, caret_y
    add         w0, w0, 1
    cmp         w0, w2
    b.lo        .done
    adr         x3, console_buffer
    mov         w4, CHARS_PER_LINE * 2
    add         w2, w3, w4
    mov         w4, ((LINES_PER_PAGE - 1) * CHARS_PER_LINE) * 2
    mem_copy8   w2, w3, w4
    add         w2, w3, w4
    mov         w1, $0f
    mov         w3, CHAR_SPACE
    mov         w4, CHARS_PER_LINE
.loop:
    strb        w3, [x2], 1 
    strb        w1, [x2], 1
    subs        w4, w4, 1
    b.ne        .loop
    mov         w0, LINES_PER_PAGE - 1
.done:    
    pstoreb     x1, w0, caret_y
    mov         w0, 0
    pstoreb     x1, w0, caret_x
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    add         sp, sp, #48
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
    sub         sp, sp, #48
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    ldp         x1, x2, [sp, #48]
    ldp         x3, x4, [sp, #64]
    pstoreb     x0, w1, caret_y
    pstoreb     x0, w2, caret_x
    pstoreb     x0, w3, caret_color
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    add         sp, sp, #80
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
    sub         sp, sp, #64
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    stp         x5, x6, [sp, #48]
    ldp         x0, x1, [sp, #64]   ; str_ptr, len
    ldp         x2, x3, [sp, #80]   ; color, pad
    ploadb      x4, w4, caret_y
    ploadb      x5, w5, caret_x
    mov         w6, CHARS_PER_LINE
    madd        w4, w6, w4, w5
    lsl         w4, w4, 1
    adr         x6, console_buffer
    add         w6, w6, w4
.loop:
    ldrb        w4, [x0], 1
    strb        w4, [x6], 1
    strb        w2, [x6], 1
    add         w5, w5, 1
    subs        w1, w1, 1
    b.ne        .loop
    pstoreb     x0, w5, caret_x
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    ldp         x5, x6, [sp, #48]
    add         sp, sp, #96
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
    string      w2, w3, w5, w12, w6 
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
