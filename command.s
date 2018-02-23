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
align 4
label lbl
    local   .def_end, .def_start
    local   .name_end, .name_start

.def_start:
    dw      .def_end - .def_start       ; length of command definiton
    dw      .name_end - .name_start     ; length of name string

.name_start:        
    db  name
.name_end:

    local   .desc_end, .desc_start
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
parse_buffer_str:
        dw PARSE_BUFFER_LENGTH
parse_buffer:
        db PARSE_BUFFER_LENGTH dup (CHAR_SPACE)

commands:
    cmddef  cmd_clear, "clear", \
        "Clears the terminal and places the next command line at the top.", \
        cmd_clear_func, \
        0

    cmddef  cmd_reset, "reset", \
        "Clears the terminal and displays the welcome banner.", \
        cmd_reset_func, \
        0

    cmddef  cmd_dump_reg, "reg", \
        "Dump the value of the specified register.", \
        0, \
        1
    parmdef cmd_dump_reg_param, "register", F_PARAM_TYPE_REGISTER, FALSE

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
; find_command
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
find_command:
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    adr         x0, parse_buffer
    mov         w1, 0
    adr         x2, commands
    ldr         w4, [x2], 4     ; size of the command def
    ldr         w5, [x2], 4     ; size of the name string
.next:  
    cmp         w1, PARSE_BUFFER_LENGTH
    b.eq        .fail
    ldrb        w3, [x0], 1
    ldrb        w6, [x2]
    cmp         w3, w6
    b.eq        .maybe
.cmd:   
    add         x2, x2, x4
    ldr         w4, [x2], 4     ; size of the command def
    cbz         w4, .fail
    ldr         w5, [x2], 4     ; size of the name string
.more:  
    add         w1, w1, 1
    b           .next
.maybe: 
    subs        w5, w5, 1
    b.eq        .cmd
    add         x2, x2, 1 
    b           .more
.fail:  
    mov         x2, 0
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; send_parse_error
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
send_parse_error:
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    uart_str    parse_error
    uart_str    bold_attr
    uart_str    underline_attr
    uart_str    parse_buffer_str
    uart_str    no_attr
    uart_nl
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret
