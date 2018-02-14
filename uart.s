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
        adr     x0, aux_base
        ldr     w0, [x0]
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
;   w2 scratch register
;
; =========================================================
uart_recv:
        adr     x0, aux_base
        ldr     w0, [x0]
        ldr     w2, [x0, AUX_MU_LSR_REG]
        ands    w2, w2, $01
        b.ne    .ready
        mov     w1, 0
        ret
.ready: ldr     w1, [x0, AUX_MU_IO_REG]
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
;   w2 scratch register
;
; =========================================================
uart_send:
        adr     x0, aux_base
        ldr     w0, [x0]
        ldr     w2, [x0, AUX_MU_LSR_REG]
        ands    w2, w2, $20
        b.ne    .ready
        ret
.ready: str     w1, [x0, AUX_MU_IO_REG]
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
        adr     x0, aux_base
        ldr     w0, [x0]
.loop:  ldr     w1, [x0, AUX_MU_LSR_REG]
        tst     w1, $100
        b.eq    .loop
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
        adr     x0, aux_base
        ldr     w0, [x0]
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
        adr     x0, aux_base
        ldr     w0, [x0]
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
        adr     x0, gpio_base
        ldr     w0, [x0]
        ldr     w1, [x0, GPIO_GPFSEL1]
        ldr     w2, [gpio_sel1_uart_mask1]
        and     w1, w1, w2
        str     w1, [x0, GPIO_GPFSEL1]
        adr     x0, aux_base
        ldr     w0, [x0]
        mov     w1, 3
        str     w1, [x0, AUX_MU_CNTL_REG]
        ret
