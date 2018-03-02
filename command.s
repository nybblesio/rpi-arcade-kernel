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
PARAM_DEF_TYPE        = 30
PARAM_DEF_REQUIRED    = 31

; =========================================================
;
; Macros Section
;
; =========================================================
macro parmdef lbl, name, type, required {
label lbl
    local .end, .start
    db  .end - .start
.start:        
    db  name
.end:
    db  29 - (.end - .start) dup (CHAR_SPACE)
    db  type
    db  required
label lbl # _end
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
label lbl # _end    
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

strdef  mem_dump_header, TERM_REVERSE, \
    " Address  00 01 02 03 04 05 06 07    ASCII  ", \ 
    TERM_NOATTR, \
    TERM_NEWLINE

align 4

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
    info        "Execute 'r' command in cmd_reg_func."
    uart_strl   reg_w0, REG_LABEL_LEN
    uart_hex32  w0
    uart_spc
    uart_chr    '|'
    uart_spc
    uart_strl   reg_w1, REG_LABEL_LEN
    uart_hex32  w1
    uart_spc
    uart_chr    '|'
    uart_spc
    uart_strl   reg_w2, REG_LABEL_LEN
    uart_hex32  w2
    uart_nl
    uart_strl   reg_w3, REG_LABEL_LEN
    uart_hex32  w3
    uart_spc
    uart_chr    '|'
    uart_spc
    uart_strl   reg_w4, REG_LABEL_LEN
    uart_hex32  w4
    uart_spc
    uart_chr    '|'
    uart_spc
    uart_strl   reg_w5, REG_LABEL_LEN
    uart_hex32  w5
    uart_nl
    uart_strl   reg_w6, REG_LABEL_LEN
    uart_hex32  w6
    uart_spc
    uart_chr    '|'
    uart_spc
    uart_strl   reg_w7, REG_LABEL_LEN
    uart_hex32  w7
    uart_spc
    uart_chr    '|'
    uart_spc
    uart_strl   reg_w8, REG_LABEL_LEN
    uart_hex32  w8
    uart_nl
    uart_strl   reg_w9, REG_LABEL_LEN
    uart_hex32  w9
    uart_spc
    uart_chr    '|'
    uart_spc
    uart_strl   reg_w10, REG_LABEL_LEN
    uart_hex32  w10
    uart_spc
    uart_chr    '|'
    uart_spc
    uart_strl   reg_w11, REG_LABEL_LEN
    uart_hex32  w11
    uart_nl
    uart_strl   reg_w12, REG_LABEL_LEN
    uart_hex32  w12
    uart_spc
    uart_chr    '|'
    uart_spc
    uart_strl   reg_w13, REG_LABEL_LEN
    uart_hex32  w13
    uart_spc
    uart_chr    '|'
    uart_spc
    uart_strl   reg_w14, REG_LABEL_LEN
    uart_hex32  w14
    uart_nl
    uart_strl   reg_w15, REG_LABEL_LEN
    uart_hex32  w15
    uart_spc
    uart_chr    '|'
    uart_spc
    uart_strl   reg_w16, REG_LABEL_LEN
    uart_hex32  w16
    uart_spc
    uart_chr    '|'
    uart_spc
    uart_strl   reg_w17, REG_LABEL_LEN
    uart_hex32  w17
    uart_nl
    uart_strl   reg_w18, REG_LABEL_LEN
    uart_hex32  w18
    uart_spc
    uart_chr    '|'
    uart_spc
    uart_strl   reg_w19, REG_LABEL_LEN
    uart_hex32  w19
    uart_spc
    uart_chr    '|'
    uart_spc
    uart_strl   reg_w20, REG_LABEL_LEN
    uart_hex32  w20
    uart_nl
    uart_strl   reg_w21, REG_LABEL_LEN
    uart_hex32  w21
    uart_spc
    uart_chr    '|'
    uart_spc
    uart_strl   reg_w22, REG_LABEL_LEN
    uart_hex32  w22
    uart_spc
    uart_chr    '|'
    uart_spc
    uart_strl   reg_w23, REG_LABEL_LEN
    uart_hex32  w23
    uart_nl
    uart_strl   reg_w24, REG_LABEL_LEN
    uart_hex32  w24
    uart_spc
    uart_chr    '|'
    uart_spc
    uart_strl   reg_w25, REG_LABEL_LEN
    uart_hex32  w25
    uart_spc
    uart_chr    '|'
    uart_spc
    uart_strl   reg_w26, REG_LABEL_LEN
    uart_hex32  w26
    uart_nl
    uart_strl   reg_w27, REG_LABEL_LEN
    uart_hex32  w27
    uart_spc
    uart_chr    '|'
    uart_spc
    uart_strl   reg_w28, REG_LABEL_LEN
    uart_hex32  w28
    uart_spc
    uart_chr    '|'
    uart_spc
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
    info        "Execute 'help' command in cmd_help_func."
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
    sub         sp, sp, #64
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    stp         x5, x6, [sp, #48]
    info        "Execute 'm' command in cmd_dump_mem_func."
    adr         x2, params
    ldr         w0, [x2, 0]             ; address
    ldr         w1, [x2, 4]             ; size
    cbnz        w1, .begin
    mov         w1, 128
.begin:
    uart_str    mem_dump_header
    mov         w5, 8
    cmp         w1, 8
    b.hs        .line
    mov         w5, w1
.line: 
    mov         w2, 8
    mov         w4, w5
    str_hex32   w0, number_buffer + 1
    uart_strl   number_buffer + 1, 8
    uart_chr    ':'
    uart_spc
.byte:
    cbnz        w4, .read_byte
    uart_spc
    uart_spc
    uart_spc
    b           .next_byte
.read_byte:
    sub         w4, w4, 1
    ldrb        w3, [x0], 1
    str_hex8    w3, number_buffer + 1
    uart_strl   number_buffer + 1, 2
    uart_spc
.next_byte:    
    subs        w2, w2, 1
    b.ne        .byte
    uart_spc
    uart_spc
    mov         w2, 8
    mov         w4, w5
    sub         w0, w0, w2
.ascii:
    cbnz        w4, .read_ascii
    uart_spc
    b           .next
.read_ascii:    
    sub         w4, w4, 1
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
    cmp         w1, 0
    b.eq        .done
    cmp         w1, 8
    b.hs        .full_line
    cmp         w5, 8
    b.lo        .done
    mov         w5, w1
    mov         w1, 0
    b           .line
.full_line:
    subs        w1, w1, 8
    b.ne        .line
.done:
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    ldp         x5, x6, [sp, #48]
    add         sp, sp, #64
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
    info        "Execute 'j0' command in cmd_joy0_func."
    
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
    info        "Execute 'j1' command in cmd_joy1_func."

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
    info        "Execute 'clear' command in cmd_clear_func."
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
    adr         x2, commands
    adr         x3, command_buffer
    mov         w5, 32          ; size of parameter structure
.loop:
    ldrb        w4, [x2, CMD_DEF_NAME_LEN]
    cbz         w4, .notfound
    add         w2, w2, 1
    sub         sp, sp, #32
    stp         x2, x4, [sp]
    stp         x3, x0, [sp, #16]
    bl          string_eq
    sub         w2, w2, 1
    cbnz        w1, .found
    ldr         w4, [x2, CMD_DEF_PARAM_COUNT]
    mul         w4, w4, w5
    add         w2, w2, 256
    add         w2, w2, w4       
    b           .loop
.found:
    mov         w1, w2
    ldr         w6, [x2, CMD_DEF_PARAM_COUNT]
    cbz         w6, .done
    add         w2, w2, 256
    adr         x4, token_offsets
    add         w4, w4, 1
    adr         x7, params
    mov         x8, 0
    str         x8, [x7, 0]
    str         x8, [x7, 8]
    str         x8, [x7, 16]
    str         x8, [x7, 24]
    add         w0, w0, 1
    add         w3, w3, w0
.param:
    cbz         w0, .done
    ldrb        w8, [x2, PARAM_DEF_TYPE]
    ldrb        w9, [x2, PARAM_DEF_REQUIRED]
    mov         w13, w0
    ldrb        w0, [x4], 1
    add         w0, w0, 1
    sub         w11, w0, w13
    sub         w11, w11, 1
    cmp         w11, 0
    b.gt        .ok
    cbnz        w9, .error
.can_omit:
    cmp         w6, 1
    b.ne        .error
    b           .done
.ok:    
    mov         w12, 10
    cmp         w8, PARAM_TYPE_REGISTER
    b.ne        .number_type
    ldrb        w10, [x3]
    cmp         w10, 'w'
    b.ne        .error
    add         w3, w3, 1
    sub         w11, w11, 1
    b           .num
.number_type:
    cmp         w8, PARAM_TYPE_NUMBER
    b.ne        .error
    ldrb        w10, [x3]
    cmp         w10, '%'
    b.ne        .hex
    mov         w12, 2
    add         w3, w3, 1
    sub         w11, w11, 1
    b           .num
.hex:    
    cmp         w10, '$'
    b.ne        .octal
    mov         w12, 16
    add         w3, w3, 1
    sub         w11, w11, 1 
    b           .num
.octal:    
    cmp         w10, '@'
    b.ne        .num
    mov         w12, 8
    add         w3, w3, 1
    sub         w11, w11, 1
    b           .num
.num:
    str_nbr     w3, w11, w12
    str         w20, [x7], 4
.next:
    add         w3, w3, w11
    add         w3, w3, 1
    add         w2, w2, w5
    subs        w6, w6, 1
    b.ne        .param
    b           .done
.error:
    debug       "param parse error"
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
