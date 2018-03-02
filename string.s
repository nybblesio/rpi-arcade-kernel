; =========================================================
; 
; Aracde Kernel Kit
; AArch64 Assembly Language
;
; Lumberjacks
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
macro str_hex8 value, dest {
    sub         sp, sp, #32
    mov         w25, value
    mov         w26, 8
    stp         x25, x26, [sp]
    mov         w25, dest
    mov         w26, 0
    stp         x25, x26, [sp, #16]
    bl          string_hex
}

macro str_hex16 value, dest {
    sub         sp, sp, #32
    mov         w25, value
    mov         w26, 16
    stp         x25, x26, [sp]
    mov         w25, dest
    mov         w26, 0
    stp         x25, x26, [sp, #16]
    bl          string_hex
}

macro str_hex32 value, dest {
    sub         sp, sp, #32
    mov         w25, value
    mov         w26, 32
    stp         x25, x26, [sp]
    mov         w25, dest
    mov         w26, 0
    stp         x25, x26, [sp, #16]
    bl          string_hex
}

; TODO: this is unsafe
macro str_isprt value {
    mov         w20, value
    bl          string_isprt
}

macro str_nbr   lbl, len, base {
    sub         sp, sp, #32
    mov         w20, lbl
    mov         w21, len
    stp         x20, x21, [sp]
    mov         w20, base
    mov         w21, 0
    stp         x20, x21, [sp, #16]
    bl          string_number
    ldp         x20, x21, [sp]
    add         sp, sp, #16
}

; =========================================================
;
; string_number
;
; stack:
;   str_ptr
;   len
;   base
;   pad
;
;   value (output)
;   pad (output)
;
; registers:
;   (none)
;
; =========================================================
string_number:
    sub         sp, sp, #80
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    stp         x5, x6, [sp, #48]
    stp         x7, x8, [sp, #64]
    ldp         x1, x2, [sp, #80]   ; str, len
    ldp         x3, x4, [sp, #96]   ; base, pad
    mov         w7, 0               ; accumulator
    cbz         w2, .exit
    mov         w6, 0               ; not negative
    ldrb        w5, [x1]
    cmp         w5, '-'
    b.ne        .parse
    mov         w6, 1               ; negative
    add         w1, w1, 1
    subs        w2, w2, 1
    b.eq        .exit               ; if length is only 1 and it was '-', bail
.loop:
    mul         w7, w7, w3          ; multiply acc by base
    ldrb        w5, [x1]
.parse:
    cmp         w5, 'a'
    b.lo        .ok
    cmp         w5, 'z'
    b.hi        .ok
    bic         w5, w5, 00100000b
    nop                             ; i'm sure why this is required but without it
                                    ; the following subs hangs the cpu
.ok:    
    subs        w5, w5, '0'         ; < '0'
    b.lo        .done
    cmp         w5, $10             
    b.ls        .check
    subs        w5, w5, $17         
    add         w5, w5, $10
.check:
    cmp         w5, w3
    b.hs        .done
    add         w7, w7, w5
    add         w1, w1, 1
    subs        w2, w2, 1
    b.ne        .loop
.done:
    cbz         w6, .exit
    neg         w7, w7
.exit:
    stp         x7, x3, [sp, #96]   ; return values
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    ldp         x5, x6, [sp, #48]
    ldp         x7, x8, [sp, #64]
    add         sp, sp, #96         
    ret

; =========================================================
;
; string_isprt
;
; stack:
;   (none)
;
; registers:
;   w20 value to check
;   w21 result (1 yes, 0 no)
;
; =========================================================
string_isprt:
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    mov         w21, 0
    cmp         w20, $7f        ; DEL
    b.eq        .done
    cmp         w20, $1f
    b.ls        .done
    mov         w21, 1
.done:    
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; string_hex
;
; stack:
;   word to convert
;   bits
;   str_ptr
;   pad
;
; registers:
;   (none)
;
; =========================================================
string_hex:
    sub         sp, sp, #48
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    ldp         x0, x1, [sp, #48]
    ldp         x2, x3, [sp, #64]
.loop:    
    mov         w4, w0
    sub         w1, w1, 4
    lsr         w4, w4, w1
    and         w4, w4, $0f
    cmp         w4, 9
    b.gt        .gt
    add         w4, w4, $30
    b           .write
.gt:    
    add         w4, w4, $37
.write:  
    strb        w4, [x2], 1
    cbnz        w1, .loop
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    add         sp, sp, #80
    ret

; =========================================================
;
; string_eq
;
; stack:
;   str1_ptr
;   str1_len
;   str2_ptr
;   str2_len
;
; registers:
;   (none)
;
; =========================================================
string_eq:
    sub         sp, sp, #48
    stp         x0, x30, [sp]
    stp         x2, x3, [sp, #16]
    stp         x4, x5, [sp, #32]
    ldp         x0, x1, [sp, #48]
    ldp         x2, x3, [sp, #64]
    cmp         w1, w3
    b.ne        .notequal
.loop:
    ldrb        w3, [x0], 1
    ldrb        w4, [x2], 1
    cmp         w3, w4
    b.ne        .notequal
    subs        w1, w1, 1
    b.ne        .loop
    mov         w1, 1
    b           .ok
.notequal:
    mov         w1, 0
.ok:    
    ldp         x0, x30, [sp]
    ldp         x2, x3, [sp, #16]
    ldp         x4, x5, [sp, #32]
    add         sp, sp, #80
    ret
