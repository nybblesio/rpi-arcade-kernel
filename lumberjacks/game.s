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
code64
processor   cpu64_v8
format      binary as 'img'

include     'constants.s'
include     'macros.s'
include     'pool.s'
include     'mailbox.s'
include     'dma.s'
include     'font.s'
include     'video.s'

; =========================================================
;
; Game Entry Point
;
; =========================================================
include 'game_abi.s'

org GAME_ABI_BOTTOM

initialize_vector:  dw  game_init
tick_vector:        dw  game_tick

; =========================================================
;
; draw_tile
;
; stack:
;   ypos
;   xpos
;   tile
;   palette
;
; registers:
;   (none)
;
; =========================================================
draw_tile:        
        ldp     x2, x3, [sp]
        ldp     x5, x4, [sp, #16]
        mov     w1, TILE_BYTES
        mul     w5, w5, w1
        mov     w1, PALETTE_SIZE
        mul     w6, w4, w1

        mov     w1, SCREEN_WIDTH
        mul     w1, w1, w2
        add     w1, w1, w3
        add     w0, w0, w1

        adr     x1, timber_bg
        add     x1, x1, x5
        mov     w3, TILE_HEIGHT
.raster:    
        mov     w4, TILE_WIDTH
.pixel:
        ldrb    x5, [x1], 1
        add     x5, x5, x6
        strb    x5, [x0], 1
        subs    w4, w4, 1
        b.ne    draw_tile.pixel
        add     x0, x0, SCREEN_WIDTH - TILE_WIDTH
        subs    w3, w3, 1
        b.ne    draw_tile.raster
        ret

macro tile ypos, xpos, tile, pal {
        sub     sp, sp, #32
        mov     w1, ypos
        mov     w2, xpos
        stp     x1, x2, [sp]
        mov     w3, tile
        mov     w4, pal
        stp     x3, x4, [sp, #16]
        bl      draw_tile
        add     sp, sp, #32
}

; =========================================================
;
; draw_stamp
;
; this function draws a 32x32 sprite stamp to the active
; back buffer.  stamps are indexed bitmaps and support up to
; 15 colors per pixel.  index 0 is always transparent, regardless
; of its color value in the palette.
;
; stack:
;   ypos
;   xpos
;   tile
;   palette
;
; registers:
;   (none)
;
; =========================================================
draw_stamp:        
        ldp     x2, x3, [sp]
        mov     w1, SCREEN_WIDTH
        mul     w1, w1, w2
        add     w1, w1, w3
        add     w0, w0, w1

        ldp     x5, x4, [sp, #16]
        mov     w1, SPRITE_BYTES
        mul     w5, w5, w1
        mov     w1, PALETTE_SIZE
        mul     w6, w4, w1

        adr     x1, timber_fg
        add     x1, x1, x5
        mov     w3, SPRITE_HEIGHT
.raster:    
        mov     w4, SPRITE_WIDTH
.pixel:
        ldrb    x5, [x1], 1
        cbz     x5, draw_stamp.skip
        add     x5, x5, x6
        strb    x5, [x0], 1
        b       draw_stamp.done
.skip:  add     x0, x0, 1
.done:  subs    w4, w4, 1
        b.ne    draw_stamp.pixel
        add     x0, x0, SCREEN_WIDTH - SPRITE_WIDTH
        subs    w3, w3, 1
        b.ne    draw_stamp.raster
        ret

macro stamp ypos, xpos, tile, pal {
        sub     sp, sp, #32
        mov     w1, ypos
        mov     w2, xpos
        stp     x1, x2, [sp]
        mov     w3, tile
        mov     w4, pal
        stp     x3, x4, [sp, #16]
        bl      draw_stamp
        add     sp, sp, #32
}

macro sprite number, ypos, xpos, tile, pal, flags {
        adr     x0, sprite_control
        mov     w1, 6 * 4
        mov     w2, number
        mul     x1, x1, x2
        add     x0, x0, x1
        mov     w1, tile
        mov     w2, ypos
        mov     w3, xpos
        mov     w4, pal
        mov     w5, flags
        str     w1, [x0], 4
        str     w2, [x0], 4
        str     w3, [x0], 4
        str     w4, [x0], 4
        str     w5, [x0], 4
}

; =========================================================
;
; game_init
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
game_init:
        sprite  0, 32, 32, 1, 0, 0  
        sprite  1, 64, 32, 2, 0, 0
        ret

; =========================================================
;
; game_tick
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
game_tick:
        ; background render loop
        adr     x10, background_control        
        mov     w11, 30
        mov     w12, 0              ; y
        mov     w13, 0              ; x 
.bg_row:        
        mov     w14, 32
.bg_tile:
        ldr     w15, [x10], 4       ; tile number
        ldr     w16, [x10], 4       ; palette
        add     x10, x10, 8         ; skip user data
        tile    w12, w13, w15, w16
        add     w13, w13, TILE_WIDTH
        subs    w14, w14, 1
        b.ne    .bg_tile
        mov     w13, 0
        add     w12, w12, TILE_HEIGHT
        subs    w11, w11, 1
        b.ne    .bg_row

        ; sprite render loop
        adr     x10, sprite_control
        mov     w11, 128
.sprite_tile:
        ldr     w12, [x10], 4       ; tile number
        ldr     w13, [x10], 4       ; y position
        ldr     w14, [x10], 4       ; x position
        ldr     w15, [x10], 4       ; palette number
        ldr     w16, [x10], 4       ; flags
        add     x10, x10, 4         ; skip user flags
        stamp   w13, w14, w12, w15
        subs    w11, w11, 1
        b.ne    .sprite_tile

        ret

; =========================================================
;
; Data Section
;
; =========================================================
align 16
sprite_control:
rept 128 {
        dw      0       ; tile number
        dw      0       ; y position
        dw      0       ; x position
        dw      0       ; palette # 0-3
        dw      0       ; flags: hflip, vflip, rotate, etc....
        dw      0       ; user data
}

align 16
background_control:
rept 960 num {
        dw      num     ; tile number
        dw      0       ; palette # 0-3
        dw      0       ; user data 1
        dw      0       ; user data 2
}

align 16
sound:          
        dw      256 dup(0)

align 8
timber_fg:
        file    'assets/timfg.bin'

align 8
timber_bg:
        file    'assets/timbg.bin'
