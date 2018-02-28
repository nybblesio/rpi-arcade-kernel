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
F_PARAM_TYPE_REGISTER = 00000001b
F_PARAM_TYPE_NUMBER   = 00000010b
F_PARAM_TYPE_BOOLEAN  = 00000100b
F_PARAM_TYPE_STRING   = 00001000b

TOKEN_OFFSET_COUNT    = 32

CMD_DEF_NAME_LEN      = 0
CMD_DEF_NAME          = 1
CMD_DEF_DESC_LEN      = 17
CMD_DEF_DESC          = 18
CMD_DEF_CALLBACK      = 248
CMD_DEF_PARAM_COUNT   = 252

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
    db  29 - (.end - .start) dup (CHAR_SPACE)
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

align 4
commands:
    cmddef cmd_help, "help", \
        "Display the list of available commands.", \
        cmd_help_func, \
        0

    cmddef cmd_dump_mem, "m", \
        "Dump a range of memory as a hex byte and ASCII table.", \
        cmd_dump_func, \
        0

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
        0
    ;parmdef cmd_dump_reg_param, "register", F_PARAM_TYPE_REGISTER, FALSE

    ; end sentinel
    dw          0

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
    uart_hex    w0
    uart_nl
    uart_strl   reg_w1, REG_LABEL_LEN
    uart_hex    w1
    uart_nl
    uart_strl   reg_w2, REG_LABEL_LEN
    uart_hex    w2
    uart_nl
    uart_strl   reg_w3, REG_LABEL_LEN
    uart_hex    w3
    uart_nl
    uart_strl   reg_w4, REG_LABEL_LEN
    uart_hex    w4
    uart_nl
    uart_strl   reg_w5, REG_LABEL_LEN
    uart_hex    w5
    uart_nl
    uart_strl   reg_w6, REG_LABEL_LEN
    uart_hex    w6
    uart_nl
    uart_strl   reg_w7, REG_LABEL_LEN
    uart_hex    w7
    uart_nl
    uart_strl   reg_w8, REG_LABEL_LEN
    uart_hex    w8
    uart_nl
    uart_strl   reg_w9, REG_LABEL_LEN
    uart_hex    w9
    uart_nl
    uart_strl   reg_w10, REG_LABEL_LEN
    uart_hex    w10
    uart_nl
    uart_strl   reg_w11, REG_LABEL_LEN
    uart_hex    w11
    uart_nl
    uart_strl   reg_w12, REG_LABEL_LEN
    uart_hex    w12
    uart_nl
    uart_strl   reg_w13, REG_LABEL_LEN
    uart_hex    w13
    uart_nl
    uart_strl   reg_w14, REG_LABEL_LEN
    uart_hex    w14
    uart_nl
    uart_strl   reg_w15, REG_LABEL_LEN
    uart_hex    w15
    uart_nl
    uart_strl   reg_w16, REG_LABEL_LEN
    uart_hex    w16
    uart_nl
    uart_strl   reg_w17, REG_LABEL_LEN
    uart_hex    w17
    uart_nl
    uart_strl   reg_w18, REG_LABEL_LEN
    uart_hex    w18
    uart_nl
    uart_strl   reg_w19, REG_LABEL_LEN
    uart_hex    w19
    uart_nl
    uart_strl   reg_w20, REG_LABEL_LEN
    uart_hex    w20
    uart_nl
    uart_strl   reg_w21, REG_LABEL_LEN
    uart_hex    w21
    uart_nl
    uart_strl   reg_w22, REG_LABEL_LEN
    uart_hex    w22
    uart_nl
    uart_strl   reg_w23, REG_LABEL_LEN
    uart_hex    w23
    uart_nl
    uart_strl   reg_w24, REG_LABEL_LEN
    uart_hex    w24
    uart_nl
    uart_strl   reg_w25, REG_LABEL_LEN
    uart_hex    w25
    uart_nl
    uart_strl   reg_w26, REG_LABEL_LEN
    uart_hex    w26
    uart_nl
    uart_strl   reg_w27, REG_LABEL_LEN
    uart_hex    w27
    uart_nl
    uart_strl   reg_w28, REG_LABEL_LEN
    uart_hex    w28
    uart_nl
    uart_strl   reg_w29, REG_LABEL_LEN
    uart_hex    w29
    uart_nl
    uart_strl   reg_w30, REG_LABEL_LEN
    uart_hex    w30
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
; cmd_dump_func
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
cmd_dump_func:
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    info        cmd_dump_msg, 20
    ldp         x0, x30, [sp]
    add         sp, sp, #16
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
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    info        cmd_j0_msg, 21
    uart_str    joy0_state_label
    pload       x0, w0, joy0_state
    str_hex8    w0, number_buffer + 1
    uart_str    str_number_buffer
    ldp         x0, x30, [sp]
    add         sp, sp, #16
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
    uart_str    joy1_state_label
    pload       x0, w0, joy1_state
    str_hex8    w0, number_buffer + 1
    uart_str    str_number_buffer
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
    sub         sp, sp, #64
    stp         x0, x30, [sp]
    stp         x2, x3, [sp, #16]
    stp         x4, x5, [sp, #32]
    stp         x6, x7, [sp, #48]
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
    mov         w1, w6
    add         w1, w1, 256
    b           .loop
.found:
    mov         w1, w6
    b           .done
.notfound:
    mov         w1, 0
.done:    
    ldp         x0, x30, [sp]
    ldp         x2, x3, [sp, #16]
    ldp         x4, x5, [sp, #32]
    ldp         x6, x7, [sp, #48]
    add         sp, sp, #64
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
