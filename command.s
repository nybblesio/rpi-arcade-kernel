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

CMD_DEF_SIZE = 0
CMD_DEF_NAME_LEN = 4
CMD_DEF_NAME = 8

; added to length of start + name
CMD_DEF_DESC_LEN = 4
CMD_DEF_DESC = 8

; added to length of start + name + desc
CMD_DEF_CALLBACK = 4
CMD_DEF_PARAM_COUNT = 8

; =========================================================
;
; Macros Section
;
; =========================================================
macro parmdef lbl, name, type, required {
align 4
label lbl
    local   .end, .start
    dw      .end - .start
.start:        
    db  name
.end:
    dw  type
    db  required
}

macro cmddef lbl, name, desc, func, param_count {
    local   .def_end, .def_start
    local   .name_end, .name_start
    local   .desc_end, .desc_start
label lbl
.def_start:
    dw      .def_end - .def_start       ; length of command definiton
    dw      .name_end - .name_start     ; length of name string
.name_start:        
    db  name
.name_end:
    dw      .desc_end - .desc_start     ; length of desc string
.desc_start:        
    db  desc
.desc_end:
    dw  func
    dw  param_count
.def_end:    
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
    cmddef cmd_clear, "clear", \
        "Clears the terminal and places the next command line at the top.", \
        cmd_clear_func, \
        0

    cmddef cmd_reset, "reset", \
        "Clears the terminal and displays the welcome banner.", \
        cmd_reset_func, \
        0

    cmddef cmd_dump_reg, "reg", \
        "Dump the value of the specified register.", \
        0, \
        0
    ;parmdef cmd_dump_reg_param, "register", F_PARAM_TYPE_REGISTER, FALSE

    ; end sentinel
    dw          0

align 16

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
    uart_str    clr_screen
    bl          new_prompt
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
    bl          send_welcome
    bl          new_prompt
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
    log_reg     w0, reg_w0, $0f
    cbz         w0, .notfound
    adr         x1, commands
    adr         x2, command_buffer
.loop:
    ldr         w3, [x1, CMD_DEF_SIZE]
    cbz         w3, .notfound
    ldr         w4, [x1, CMD_DEF_NAME_LEN]
    mov         w6, w1
    mov         w5, w1
    add         w5, w5, 8
    ;sub         sp, sp, #32
    ;stp         x5, x4, [sp]
    ;stp         x2, x0, [sp, #16]
    ;bl          string_eq
    ;cbnz        w1, .done
    mov         w1, w6
    add         w1, w1, w3
    b           .notfound
.found:
    mov         w1, w6
    add         w1, w1, w3
    sub         w1, w1, 8
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
    uart_nl
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret
