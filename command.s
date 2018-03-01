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
; Constants Section
;
; =========================================================
PARAM_TYPE_REGISTER = 1
PARAM_TYPE_NUMBER   = 2

TOKEN_OFFSET_COUNT    = 32

CMD_DEF_NAME_LEN      = 0
CMD_DEF_NAME          = 1
CMD_DEF_DESC_LEN      = 17
CMD_DEF_DESC          = 18
CMD_DEF_CALLBACK      = 248
CMD_DEF_PARAM_COUNT   = 252

PARAM_DEF_NAME_LEN    = 0
PARAM_DEF_NAME        = 1
PARAM_DEF_TYPE        = 29
PARAM_DEF_REQUIRED    = 30

; =========================================================
;
; Macros Section
;
; =========================================================
macro parmdef lbl, name, type, required {
align 4
label lbl
    local   .end, .start
    db .end - .start
.start:        
    db  name
.end:
    db  28 - (.end - .start) dup (CHAR_SPACE)
    db  type
    db  required
}

macro cmddef lbl, name, desc, callback, param_count {
label lbl
    db .name_end - .name
.name:
    db name
.name_end:
    db 16 - (.name_end - .name) dup(CHAR_SPACE)

    db .desc_end - .desc
.desc:
    db  desc
.desc_end:
    db  230 - (.desc_end - .desc) dup(CHAR_SPACE)

    dw  callback
    dw  param_count
}

; =========================================================
;
; Data Section
;
; =========================================================
align 4
command_buffer:
        db TERM_CHARS_PER_LINE dup (CHAR_SPACE)

align 4        
command_buffer_offset:  dw  0

align 4
token_offsets:
    db  TOKEN_OFFSET_COUNT dup(0)

PARAMS_COUNT = 8
align 4
params:
    dw  PARAMS_COUNT dup(0)

align 4
commands:
    cmddef cmd_help, "help", \
        "Display the list of available commands.", \
        cmd_help_func, \
        0

    cmddef cmd_dump_mem, "m", \
        "Dump a range of memory as a hex byte and ASCII table.", \
        cmd_dump_mem_func, \
        2
    parmdef cmd_dump_mem_addr, "addr", PARAM_TYPE_NUMBER, TRUE
    parmdef cmd_dump_mem_size, "size", PARAM_TYPE_NUMBER, TRUE

    cmddef cmd_clear, "clear", \
        "Clears the terminal and places the next command line at the top.", \
        cmd_clear_func, \
        0

    cmddef cmd_reset, "reset", \
        "Clears the terminal and displays the welcome banner.", \
        cmd_reset_func, \
        0

    cmddef cmd_dump_joy0, "j0", \
        "Dump the state of joy controller 0.", \
        cmd_joy0_func, \
        0

    cmddef cmd_dump_joy1, "j1", \
        "Dump the state of joy controller 1.", \
        cmd_joy1_func, \
        0

    cmddef cmd_dump_reg, "r", \
        "Dump the value of the specified register.", \
        cmd_reg_func, \
        1
    parmdef cmd_dump_reg_param, "register", PARAM_TYPE_REGISTER, FALSE

    ; end sentinel
    dw          0

JOY_LABEL_LEN = 13
cmd_joy_r:      db "JOY_R      = "
cmd_joy_l:      db "JOY_L      = "
cmd_joy_x:      db "JOY_X      = "
cmd_joy_a:      db "JOY_A      = "
cmd_joy_right:  db "JOY_RIGHT  = "
cmd_joy_left:   db "JOY_LEFT   = "
cmd_joy_down:   db "JOY_DOWN   = "
cmd_joy_up:     db "JOY_UP     = "
cmd_joy_start:  db "JOY_START  = "
cmd_joy_select: db "JOY_SELECT = "
cmd_joy_y:      db "JOY_Y      = "
cmd_joy_b:      db "JOY_B      = "

cmd_j0_msg:     db "execute 'j0' command."
cmd_j1_msg:     db "execute 'j1' command."
cmd_reg_msg:    db "execute 'r' command."
cmd_help_msg:   db "execute 'help' command."
cmd_dump_msg:   db "execute 'm' command."
cmd_clear_msg:  db "execute 'clear' command."
cmd_reset_msg:  db "execute 'reset' command."

align 16

; =========================================================
;
; cmd_reg_func
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
cmd_reg_func:
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    info        cmd_reg_msg, 20
    uart_strl   reg_w0, REG_LABEL_LEN
    uart_hex32  w0
    uart_nl
    uart_strl   reg_w1, REG_LABEL_LEN
    uart_hex32  w1
    uart_nl
    uart_strl   reg_w2, REG_LABEL_LEN
    uart_hex32  w2
    uart_nl
    uart_strl   reg_w3, REG_LABEL_LEN
    uart_hex32  w3
    uart_nl
    uart_strl   reg_w4, REG_LABEL_LEN
    uart_hex32  w4
    uart_nl
    uart_strl   reg_w5, REG_LABEL_LEN
    uart_hex32  w5
    uart_nl
    uart_strl   reg_w6, REG_LABEL_LEN
    uart_hex32  w6
    uart_nl
    uart_strl   reg_w7, REG_LABEL_LEN
    uart_hex32  w7
    uart_nl
    uart_strl   reg_w8, REG_LABEL_LEN
    uart_hex32  w8
    uart_nl
    uart_strl   reg_w9, REG_LABEL_LEN
    uart_hex32  w9
    uart_nl
    uart_strl   reg_w10, REG_LABEL_LEN
    uart_hex32  w10
    uart_nl
    uart_strl   reg_w11, REG_LABEL_LEN
    uart_hex32  w11
    uart_nl
    uart_strl   reg_w12, REG_LABEL_LEN
    uart_hex32  w12
    uart_nl
    uart_strl   reg_w13, REG_LABEL_LEN
    uart_hex32  w13
    uart_nl
    uart_strl   reg_w14, REG_LABEL_LEN
    uart_hex32  w14
    uart_nl
    uart_strl   reg_w15, REG_LABEL_LEN
    uart_hex32  w15
    uart_nl
    uart_strl   reg_w16, REG_LABEL_LEN
    uart_hex32  w16
    uart_nl
    uart_strl   reg_w17, REG_LABEL_LEN
    uart_hex32  w17
    uart_nl
    uart_strl   reg_w18, REG_LABEL_LEN
    uart_hex32  w18
    uart_nl
    uart_strl   reg_w19, REG_LABEL_LEN
    uart_hex32  w19
    uart_nl
    uart_strl   reg_w20, REG_LABEL_LEN
    uart_hex32  w20
    uart_nl
    uart_strl   reg_w21, REG_LABEL_LEN
    uart_hex32  w21
    uart_nl
    uart_strl   reg_w22, REG_LABEL_LEN
    uart_hex32  w22
    uart_nl
    uart_strl   reg_w23, REG_LABEL_LEN
    uart_hex32  w23
    uart_nl
    uart_strl   reg_w24, REG_LABEL_LEN
    uart_hex32  w24
    uart_nl
    uart_strl   reg_w25, REG_LABEL_LEN
    uart_hex32  w25
    uart_nl
    uart_strl   reg_w26, REG_LABEL_LEN
    uart_hex32  w26
    uart_nl
    uart_strl   reg_w27, REG_LABEL_LEN
    uart_hex32  w27
    uart_nl
    uart_strl   reg_w28, REG_LABEL_LEN
    uart_hex32  w28
    uart_nl
    uart_strl   reg_w29, REG_LABEL_LEN
    uart_hex32  w29
    uart_nl
    uart_strl   reg_w30, REG_LABEL_LEN
    uart_hex32  w30
    uart_nl
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; cmd_help_func
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
cmd_help_func:
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    info        cmd_help_msg, 23
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; cmd_dump_mem_func
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
cmd_dump_mem_func:
    sub         sp, sp, #48
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    info        cmd_dump_msg, 20
    ;adr         x2, params
    ;ldr         w0, [x2, 0]             ; address
    ;ldr         w1, [x2, 4]             ; size
    ;cbnz        w1, .line
    mov         w0, 0
    mov         w1, 128

.line:    
    mov         w2, 8 
    str_hex32   w0, number_buffer + 1
    uart_strl   number_buffer + 1, 8
    uart_chr    ':'
    uart_spc
.byte:
    ldrb        w3, [x0], 1
    str_hex8    w3, number_buffer + 1
    uart_strl   number_buffer + 1, 2
    uart_spc
    subs        w2, w2, 1
    b.ne        .byte
    uart_spc
    uart_spc
    mov         w2, 8
    sub         w0, w0, w2
.ascii:
    ldrb        w3, [x0], 1
    str_isprt   w3
    cbz         w21, .ctrl
    uart_chr    w3
    b           .next
.ctrl:
    uart_chr    '.'
.next:    
    subs        w2, w2, 1
    b.ne        .ascii
    uart_nl
    subs        w1, w1, 8
    b.ne        .line

    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    add         sp, sp, #48
    ret

; =========================================================
;
; cmd_joy0_func
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
cmd_joy0_func:
    sub         sp, sp, #32
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    info        cmd_j0_msg, 21
    
    ploadb      x0, w0, joy0_r
    uart_strl   cmd_joy_r, JOY_LABEL_LEN
    uart_hex8   w0
    uart_nl

    ploadb      x0, w0, joy0_l
    uart_strl   cmd_joy_l, JOY_LABEL_LEN
    uart_hex8   w0
    uart_nl

    ploadb      x0, w0, joy0_x
    uart_strl   cmd_joy_x, JOY_LABEL_LEN
    uart_hex8   w0
    uart_nl

    ploadb      x0, w0, joy0_a
    uart_strl   cmd_joy_a, JOY_LABEL_LEN
    uart_hex8   w0
    uart_nl

    ploadb      x0, w0, joy0_right
    uart_strl   cmd_joy_right, JOY_LABEL_LEN
    uart_hex8   w0
    uart_nl

    ploadb      x0, w0, joy0_left
    uart_strl   cmd_joy_left, JOY_LABEL_LEN
    uart_hex8   w0
    uart_nl

    ploadb      x0, w0, joy0_down
    uart_strl   cmd_joy_down, JOY_LABEL_LEN
    uart_hex8   w0
    uart_nl

    ploadb      x0, w0, joy0_up
    uart_strl   cmd_joy_up, JOY_LABEL_LEN
    uart_hex8   w0
    uart_nl

    ploadb      x0, w0, joy0_start
    uart_strl   cmd_joy_start, JOY_LABEL_LEN
    uart_hex8   w0
    uart_nl

    ploadb      x0, w0, joy0_select
    uart_strl   cmd_joy_select, JOY_LABEL_LEN
    uart_hex8   w0
    uart_nl

    ploadb      x0, w0, joy0_y
    uart_strl   cmd_joy_y, JOY_LABEL_LEN
    uart_hex8   w0
    uart_nl

    ploadb      x0, w0, joy0_b
    uart_strl   cmd_joy_b, JOY_LABEL_LEN
    uart_hex8   w0
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    add         sp, sp, #32
    ret

; =========================================================
;
; cmd_joy1_func
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
cmd_joy1_func:
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    info        cmd_j1_msg, 21

    ploadb      x0, w0, joy1_r
    uart_strl   cmd_joy_r, JOY_LABEL_LEN
    uart_hex8   w0
    uart_nl

    ploadb      x0, w0, joy1_l
    uart_strl   cmd_joy_l, JOY_LABEL_LEN
    uart_hex8   w0
    uart_nl

    ploadb      x0, w0, joy1_x
    uart_strl   cmd_joy_x, JOY_LABEL_LEN
    uart_hex8   w0
    uart_nl

    ploadb      x0, w0, joy1_a
    uart_strl   cmd_joy_a, JOY_LABEL_LEN
    uart_hex8   w0
    uart_nl

    ploadb      x0, w0, joy1_right
    uart_strl   cmd_joy_right, JOY_LABEL_LEN
    uart_hex8   w0
    uart_nl

    ploadb      x0, w0, joy1_left
    uart_strl   cmd_joy_left, JOY_LABEL_LEN
    uart_hex8   w0
    uart_nl

    ploadb      x0, w0, joy1_down
    uart_strl   cmd_joy_down, JOY_LABEL_LEN
    uart_hex8   w0
    uart_nl

    ploadb      x0, w0, joy1_up
    uart_strl   cmd_joy_up, JOY_LABEL_LEN
    uart_hex8   w0
    uart_nl

    ploadb      x0, w0, joy1_start
    uart_strl   cmd_joy_start, JOY_LABEL_LEN
    uart_hex8   w0
    uart_nl

    ploadb      x0, w0, joy1_select
    uart_strl   cmd_joy_select, JOY_LABEL_LEN
    uart_hex8   w0
    uart_nl

    ploadb      x0, w0, joy1_y
    uart_strl   cmd_joy_y, JOY_LABEL_LEN
    uart_hex8   w0
    uart_nl

    ploadb      x0, w0, joy1_b
    uart_strl   cmd_joy_b, JOY_LABEL_LEN
    uart_hex8   w0

    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; cmd_clear_func
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
cmd_clear_func:
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    info        cmd_clear_msg, 24
    uart_str    clr_screen
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; cmd_reset_func
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
cmd_reset_func:
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    info        cmd_reset_msg, 24
    bl          term_welcome
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; command_find
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
command_find:
    sub         sp, sp, #112
    stp         x0, x30, [sp]
    stp         x2, x3, [sp, #16]
    stp         x4, x5, [sp, #32]
    stp         x6, x7, [sp, #48]
    stp         x8, x9, [sp, #64]
    stp         x10, x11, [sp, #80]
    stp         x12, x13, [sp, #96]

    ploadb      x0, w0, token_offsets
    cbz         w0, .notfound
    adr         x1, commands
    adr         x2, command_buffer
.loop:
    ldrb        w3, [x1, CMD_DEF_NAME_LEN]
    cbz         w3, .notfound
    mov         w6, w1
    add         w1, w1, 1
    sub         sp, sp, #32
    stp         x1, x3, [sp]
    stp         x2, x0, [sp, #16]
    bl          string_eq
    cbnz        w1, .found
    mov         w5, 32          ; size of parameter structure
    mov         w1, w6
    ldr         w4, [x1, CMD_DEF_PARAM_COUNT]
    mul         w4, w4, w5
    add         w1, w1, 256
    add         w1, w1, w4      ; bytes of parameters
    b           .loop
.found:
    debug       debug_here1, DEBUG_HERE_LEN

    mov         w1, w6
    ldr         w3, [x1, CMD_DEF_PARAM_COUNT]
    cbz         w3, .done
    add         w6, w6, 256
    adr         x4, token_offsets
    add         w4, w4, 1
    adr         x7, params
    mov         x8, 0
    str         x8, [x7, 0]
    str         x8, [x7, 8]
    str         x8, [x7, 16]
    str         x8, [x7, 24]
.param:
    cbz         w0, .done
    add         w2, w2, w0
    ldrb        w0, [x4], 1
    mov         w11, w0
    ldrb        w8, [x6, PARAM_DEF_TYPE]
    ldrb        w9, [x6, PARAM_DEF_REQUIRED]

    mov         w12, 10
    cmp         w8, PARAM_TYPE_REGISTER
    b.ne        .number_type
    ldrb        w10, [x2]
    cmp         w10, 'w'
    b.ne        .error
    add         w2, w2, 1
    sub         w11, w11, 1
    b           .num
.number_type:
    debug       debug_here2, DEBUG_HERE_LEN

    cmp         w8, PARAM_TYPE_NUMBER
    b.ne        .error
    ldrb        w10, [x2]
    cmp         w10, '%'
    b.ne        .hex
    mov         w12, 2
    add         w2, w2, 1
    sub         w11, w11, 1
    b           .num
.hex:    
    cmp         w10, '$'
    b.ne        .octal

    debug       debug_here4, DEBUG_HERE_LEN

    mov         w12, 16
    add         w2, w2, 1
    sub         w11, w11, 1 
    b           .num
.octal:    
    cmp         w10, '@'
    b.ne        .num
    mov         w12, 8
    add         w2, w2, 1
    sub         w11, w11, 1
    b           .num
.num:
    debug_reg   w2, reg_w2
    debug_reg   w11, reg_w11
    debug_reg   w12, reg_w12
    str_nbr     w2, w11, w12
    debug_reg   w20, reg_w20
    str         w20, [x7], 4
.next:
    add         w6, w6, w5
    subs        w4, w4, 1
    b.ne        .param
    b           .done
.error:
    debug       debug_here3, DEBUG_HERE_LEN
    b           .done
.notfound:
    mov         w1, 0
.done:
    ldp         x0, x30, [sp]
    ldp         x2, x3, [sp, #16]
    ldp         x4, x5, [sp, #32]
    ldp         x6, x7, [sp, #48]
    ldp         x8, x9, [sp, #64]
    ldp         x10, x11, [sp, #80]
    ldp         x12, x13, [sp, #96]
    add         sp, sp, #112
    ret

; =========================================================
;
; command_error
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
command_error:
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    mov         w10, w1
    uart_str    parse_error
    uart_str    bold_attr
    uart_str    underline_attr
    uart_strl   command_buffer, w10
    uart_str    no_attr
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret
