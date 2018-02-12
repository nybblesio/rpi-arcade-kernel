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
; uart_lcr
;
; stack:
;   (none)
;
; registers:
;   w0 scratch register
;   w1 status value
;
; =========================================================
uart_lcr:
        ldr     w0, [aux_base]
        ldr     w1, [x0, AUX_MU_LSR_REG]
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
;
; =========================================================
uart_recv:
        ldr     w0, [aux_base]
.loop:  ldr     w1, [x0, AUX_MU_LSR_REG]
        ands    w1, w1, $01
        b.eq    .loop
        ldr     w1, [x0, AUX_MU_IO_REG]
        and     w1, w1, $ff
        ret

; =========================================================
;
; uart_send
;
; stack:
;   (none)
;
; registers:
;   w0 scratch register
;   w1 character to send
;
; =========================================================
uart_send:
        ldr     w0, [aux_base]
.loop:  ldr     w1, [x0, AUX_MU_LSR_REG]
        ands    w1, w1, $20
        b.eq    .loop
        str     w1, [x0, AUX_MU_IO_REG]
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
        ldr     w0, [aux_base]
.loop:  ldr     w1, [x0, AUX_MU_LSR_REG]
        ands    w1, w1, $100
        b.ne    .loop
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
        ldr     w0, [aux_base]
        ldr     w1, [x0, AUX_MU_LSR_REG]
        ands    w1, w1, $01
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
        ldr     w0, [aux_base]
        mov     w1, 1
        str     w1, [x0, AUX_ENABLES]
        mov     w1, 0
        str     w1, [x0, AUX_MU_IER_REG]
        mov     w1, 0
        str     w1, [x0, AUX_MU_CNTL_REG]
        mov     w1, 3
        str     w1, [x0, AUX_MU_LCR_REG]
        mov     w1, 0
        str     w1, [x0, AUX_MU_MCR_REG]
        mov     w1, 0
        str     w1, [x0, AUX_MU_IER_REG]
        mov     w1, $C6
        str     w1, [x0, AUX_MU_IIR_REG]
        mov     w1, 270
        str     w1, [x0, AUX_MU_BAUD_REG]
        ldr     w0, [gpio_base]
        ldr     w1, [x0, GPIO_GPFSEL1]
        ldr     w2, [gpio_sel1_uart_mask1]
        and     w1, w1, w2
        ldr     w2, [gpio_sel1_uart_mask2]
        orr     w1, w1, w2
        str     w1, [x0, GPIO_GPFSEL1]
        ldr     w0, [aux_base]
        mov     w1, 3
        str     w1, [x0, AUX_MU_CNTL_REG]
        ret

;.globl _start
;_start:

;ldr r2,=0x3F215000
;ldr r1,=0x00000001
;str r1,[r2,#0x04]
;ldr r1,=0x00000000
;str r1,[r2,#0x44]
;ldr r1,=0x00000000
;str r1,[r2,#0x60]
;ldr r1,=0x00000003
;str r1,[r2,#0x4C]
;ldr r1,=0x00000000
;str r1,[r2,#0x50]
;ldr r1,=0x00000000
;str r1,[r2,#0x44]
;ldr r1,=0x000000C6
;str r1,[r2,#0x48]
;ldr r1,=0x0000010E
;str r1,[r2,#0x68]

;ldr r0,=0x3F200004
;ldr r1,[r0]
;ldr r3,=0xFFFD2FFF
;and r1,r3
;ldr r3,=0x00012000
;orr r1,r3
;str r1,[r0]

;ldr r1,=0x00000003
;str r1,[r2,#0x60]

;ldr r1,=0x55
;str r1,[r2,#0x40]

;ldr r1,=0x56
;txwait:
;    ldr r0,[r2,#0x54]
;    tst r0,#0x20
;    beq txwait
;    str r1,[r2,#0x40]
;
;b .
