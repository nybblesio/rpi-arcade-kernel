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
; Data Section
;
; =========================================================
;align 16
;tile_copy   dma_control DMA_TDMODE + DMA_DEST_INC + DMA_DEST_WIDTH + DMA_SRC_INC + DMA_SRC_WIDTH

; =========================================================
;
; Macros
;
; =========================================================
struc dma_control flags*, len, stride {
        .flags  dw      flags
        .src    dw      0
        .dest   dw      0
        if len eq
                .len    dw      0
        else
                .len    dw      len
        end if
        if stride eq
                .stride dw      0
        else                                 
                .stride dw      stride
        end if                
        .next   dw      0
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
        mov     x0, PERIPHERAL_BASE
        orr     x0, x0, DMA_ENABLE
        mov     w1, DMA_EN0
        str     w1, [x0]
        ret

