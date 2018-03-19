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
macro uart_spc {
    uart_chr   ' '
}

macro uart_nl {
    uart_chr    $0d
    uart_chr    $0a
}

macro uart_hex8 value {
    uart_chr    '$'
    sub         sp, sp, #16
    mov         w25, value
    mov         w26, 8
    stp         x25, x26, [sp]
    bl          uart_send_hex
}

macro uart_hex16 value {
    uart_chr    '$'
    sub         sp, sp, #16
    mov         w25, value
    mov         w26, 16
    stp         x25, x26, [sp]
    bl          uart_send_hex
}

macro uart_hex32 value {
    uart_chr    '$'
    sub         sp, sp, #16
    mov         w25, value
    mov         w26, 32
    stp         x25, x26, [sp]
    bl          uart_send_hex
}

macro uart_chr char {
    sub         sp, sp, #16
    mov         w25, char
    mov         w26, 0
    stp         x25, x26, [sp]
    bl          uart_send
}

macro uart_str label* {
    sub         sp, sp, #16
    adr         x25, label
    ldr         w26, [x25], 4
    stp         x25, x26, [sp]
    bl          uart_send_string
}

macro uart_strl label*, len* {
    sub         sp, sp, #16
    adr         x25, label
    mov         w26, len
    stp         x25, x26, [sp]
    bl          uart_send_string
}

macro uart_log [params] {
    local       .start, .end, .skip
    b           .skip
.start:
    strlist     params
.end:
    align 4
.skip:    
    uart_strl   .start, .end - .start
    uart_nl
}

; =========================================================
;
; Variables
;
; =========================================================
flow_state: db 0

align 4

; =========================================================
;
; uart_status
;
; stack:
;   (none)
;
; registers:
;   w0 scratch register
;   w1 status value
;
; =========================================================
uart_status:
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    adr         x0, aux_base
    ldr         w0, [x0]
    ldr         w1, [x0, AUX_MU_LSR_REG]
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; uart_flow
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
uart_flow:
    sub         sp, sp, #32
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    pload       x0, w0, aux_base
    ldr         w1, [x0, AUX_MU_STAT_REG]
    and         w1, w1, 00000000_00000111_10000000_00000000b
    lsr         w1, w1, 16
    and         w1, w1, $ff
    cbz         w1, .xon
    ploadb      x0, w0, flow_state
    cbnz        w0, .exit
    cmp         w1, 5
    b.ls        .exit
.xoff:
    ploadb      x0, w0, flow_state
    cbnz        w0, .exit
    uart_chr    XOFF
    mov         w0, 1
    pstoreb     x1, w0, flow_state
    b           .exit
.xon:
    ploadb      x0, w0, flow_state
    cbz         w0, .exit
    uart_chr    XON
    mov         w0, 0
    pstoreb     x1, w0, flow_state
.exit:    
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    add         sp, sp, #32
    ret

; =========================================================
;
; uart_recv
;
; stack:
;   (none)
;
; registers:
;   w0 scratch register
;   w1 character received
;   w2 scratch register
;
; =========================================================
uart_recv:
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    bl          uart_flow
    pload       x0, w0, aux_base
    ldr         w2, [x0, AUX_MU_LSR_REG]
    ands        w2, w2, $01
    b.ne        .ready
    mov         w1, 0
    b           .done
.ready: 
    ldr         w1, [x0, AUX_MU_IO_REG]
    and         w1, w1, $ff
.done: 
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; uart_recv_block
;
; stack:
;   (none)
;
; registers:
;   w0 scratch register
;   w1 character received
;   w2 scratch register
;
; =========================================================
uart_recv_block:
    sub         sp, sp, #32
    stp         x0, x30, [sp]
    stp         x2, x3, [sp, #16]
    bl          uart_flow
    pload       x0, w0, aux_base
.empty: 
    ldr         w2, [x0, AUX_MU_LSR_REG]
    ands        w2, w2, $01
    b.eq        .empty
.ready: 
    ldr         w1, [x0, AUX_MU_IO_REG]
    and         w1, w1, $ff
    ldp         x0, x30, [sp]
    ldp         x2, x3, [sp, #16]
    add         sp, sp, #32
    ret

; =========================================================
;
; uart_send
;
; stack:
;   character to send
;   pad
;
; registers:
;   (none)
;
; =========================================================
uart_send:
    sub         sp, sp, #32
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    ldp         x1, x0, [sp, #32]
    pload       x0, w0, aux_base
.full:  
    ldr         w2, [x0, AUX_MU_LSR_REG]
    ands        w2, w2, $20
    b.eq        .full
.ready: 
    str         w1, [x0, AUX_MU_IO_REG]
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    add         sp, sp, #48
    ret

; =========================================================
;
; uart_send_hex
;
; stack:
;   word to send as hex
;   number of bits
;
; registers:
;   (none)
;
; =========================================================
uart_send_hex:
    sub         sp, sp, #48
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    ldp         x1, x2, [sp, #48]
    pload       x0, w0, aux_base
.full:  
    ldr         w3, [x0, AUX_MU_LSR_REG]
    ands        w3, w3, $20
    b.eq        .full
    mov         w3, w1
    sub         w2, w2, 4
    lsr         w3, w3, w2
    and         w3, w3, $0f
    cmp         w3, 9
    b.gt        .gt
    add         w3, w3, $30
    b           .send
.gt:    
    add         w3, w3, $37
.send:  
    str         w3, [x0, AUX_MU_IO_REG]
    cbnz        w2, .full
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    add         sp, sp, #64
    ret

; =========================================================
;
; uart_send_string
;
; stack:
;   str_ptr
;   len
;
; registers:
;   (none)
;
; =========================================================
uart_send_string:
    sub         sp, sp, #48
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    ldp         x1, x2, [sp, #48]
    pload       x0, w0, aux_base
.next:  
    ldr         w3, [x0, AUX_MU_LSR_REG]
    ands        w3, w3, $20
    b.eq        .next
    ldrb        w3, [x1], 1
    str         w3, [x0, AUX_MU_IO_REG]
    subs        w2, w2, 1
    b.ne        .next
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    add         sp, sp, #64
    ret

; =========================================================
;
; uart_flush
;
; stack:
;   (none)
;
; registers:
;   w0-w1 scratch register
;
; =========================================================
uart_flush:
    sub         sp, sp, #16
    stp         x0, x30, [sp]        
    adr         x0, aux_base
    ldr         w0, [x0]
.busy:  
    ldr         w1, [x0, AUX_MU_LSR_REG]
    tst         w1, $100
    b.eq        .busy
.ready: 
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; uart_check
;
; stack:
;   (none)
;
; registers:
;   w0 scratch register
;   w1 status mask
;
; =========================================================
uart_check:
    sub         sp, sp, #16
    stp         x0, x30, [sp]        
    adr         x0, aux_base
    ldr         w0, [x0]
    ldr         w1, [x0, AUX_MU_LSR_REG]
    ands        w1, w1, $01
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; uart_init
;
; stack:
;   (none)
;
; registers:
;   w0-w3 scratch register
;
; =========================================================
uart_init:
    sub         sp, sp, #16
    stp         x0, x30, [sp]        
    pload       x0, w0, aux_base
    mov         w1, 1
    str         w1, [x0, AUX_ENABLES]
    mov         w1, 0
    str         w1, [x0, AUX_MU_IER_REG]
    mov         w1, 0
    str         w1, [x0, AUX_MU_CNTL_REG]
    mov         w1, 3
    str         w1, [x0, AUX_MU_LCR_REG]
    mov         w1, 0
    str         w1, [x0, AUX_MU_MCR_REG]
    mov         w1, 0
    str         w1, [x0, AUX_MU_IER_REG]
    mov         w1, $C6
    str         w1, [x0, AUX_MU_IIR_REG]
    ;mov         w1, 270
    ; baud rate calculation: ((400000000/115200)/8) - 1
    mov         w1, 433
    str         w1, [x0, AUX_MU_BAUD_REG]
    pload       x0, w0, gpio_base
    ldr         w1, [x0, GPIO_GPFSEL1]
    ldr         w2, [gpio_sel1_uart_mask1]
    and         w1, w1, w2
    str         w1, [x0, GPIO_GPFSEL1]
    pload       x0, w0, aux_base
    ;mov         w1, 00000000_00000000_00000000_00001111b ; enable tx, rx, and auto flow control for both
    mov         w1, 00000000_00000000_00000000_00000011b ; enable tx, rx
    str         w1, [x0, AUX_MU_CNTL_REG]
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret
