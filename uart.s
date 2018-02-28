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
    mov         w20, value
    mov         w21, 8
    stp         x20, x21, [sp]
    bl          uart_send_hex
}

macro uart_hex16 value {
    uart_chr    '$'
    sub         sp, sp, #16
    mov         w20, value
    mov         w21, 16
    stp         x20, x21, [sp]
    bl          uart_send_hex
}

macro uart_hex32 value {
    uart_chr    '$'
    sub         sp, sp, #16
    mov         w20, value
    mov         w21, 32
    stp         x20, x21, [sp]
    bl          uart_send_hex
}

macro uart_chr char {
    sub         sp, sp, #16
    mov         w20, char
    mov         w21, 0
    stp         x20, x21, [sp]
    bl          uart_send
}

macro uart_str label* {
    adr         x1, label
    ldr         w2, [x1], 4
    bl          uart_send_string
}

macro uart_strl label*, len* {
    adr         x1, label
    mov         w2, len
    bl          uart_send_string
}

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
    pload       x0, w0, aux_base
    ldr         w2, [x0, AUX_MU_LSR_REG]
    ands        w2, w2, $01
    b.ne        .ready
    mov         w1, 0
    ret
.ready: 
    ldr         w1, [x0, AUX_MU_IO_REG]
    and         w1, w1, $ff
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
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    pload       x0, w0, aux_base
.empty: 
    ldr         w2, [x0, AUX_MU_LSR_REG]
    ands        w2, w2, $01
    b.ne        .ready
    b           .empty
.ready: 
    ldr         w1, [x0, AUX_MU_IO_REG]
    and         w1, w1, $ff
    ldp         x0, x30, [sp]
    add         sp, sp, #16
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
    b.ne        .ready
    b           .full
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
;   (none)
;
; registers:
;   w0 scratch register
;   w1 pointer to string
;   w2 number of characters
;   w3 scratch register
;
; =========================================================
uart_send_string:
    sub         sp, sp, #16
    stp         x0, x30, [sp]        
    pload       x0, w0, aux_base
.next:  
    ldr         w3, [x0, AUX_MU_LSR_REG]
    ands        w3, w3, $20
    b.ne        .ready
    b           .next
.ready: 
    ldrb        w3, [x1], 1
    str         w3, [x0, AUX_MU_IO_REG]
    subs        w2, w2, 1
    b.ne        .next
    ldp         x0, x30, [sp]
    add         sp, sp, #16
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
    b.ne        .ready
    b           .busy
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
    mov         w1, 270
    str         w1, [x0, AUX_MU_BAUD_REG]
    pload       x0, w0, gpio_base
    ldr         w1, [x0, GPIO_GPFSEL1]
    ldr         w2, [gpio_sel1_uart_mask1]
    and         w1, w1, w2
    str         w1, [x0, GPIO_GPFSEL1]
    pload       x0, w0, aux_base
    mov         w1, 3
    str         w1, [x0, AUX_MU_CNTL_REG]
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret
