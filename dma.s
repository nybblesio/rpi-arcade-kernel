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
; Constants
;
; =========================================================
DMA_CON_FLAGS  = 0
DMA_CON_SRC    = 4
DMA_CON_DEST   = 8
DMA_CON_LEN    = 12
DMA_CON_STRIDE = 16
DMA_CON_NEXT   = 20

; =========================================================
;
; Macros
;
; =========================================================
macro linear_dmadef name*, flags*, len {
align 32
common
label name
    dw  flags
    dw  0
    dw  0
    dw  len
    dw  0
    dw  0       ; next cb
    dw  0       ; reserved
    dw  0       ; reserved
}

; =========================================================
;
; dma_init
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
dma_init:
    pload       x0, w0, dma_enable_base
    mov         w1, DMA_EN0
    str         w1, [x0]
    ret

; =========================================================
;
; dma_start
;
; stack:
;   dma control block address
;   dma base address
;
; registers:
;   (none)
;
; =========================================================
dma_start:
    sub         sp, sp, #48
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    ldp         x0, x1, [sp, #48]
    mov         w2, BUS_ADDRESSES_l2CACHE_DISABLED
    add         w0, w0, w2
    str         w0, [x1, DMA_CONBLK_AD]
    mov         w2, DMA_ACTIVE
    str         w2, [x1, DMA_CS]
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    add         sp, sp, #64
    ret

macro dma_start con_blk_addr, dma_base_addr {
    sub         sp, sp, #16
    adr         x25, con_blk_addr
    mov         w26, dma_base_addr
    stp         x25, x26, [sp]
    bl          dma_start
}

; =========================================================
;
; dma_wait
;
; stack:
;   dma base address
;   pad
;
; registers:
;   (none)
;
; =========================================================
dma_wait:
    sub         sp, sp, #32
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    ldp         x0, x1, [sp, #32]
.loop:    
    ldr         w1, [x0, DMA_CS]
    tst         w1, DMA_ACTIVE
    b.ne        .loop
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    add         sp, sp, #48
    ret

macro dma_wait dma_base_addr {
    sub         sp, sp, #16
    mov         w25, dma_base_addr
    mov         w26, 0
    stp         x25, x26, [sp]
    bl          dma_wait
}
