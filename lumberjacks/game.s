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

; =========================================================
;
; Game Entry Point
;
; =========================================================
include     'macros.s'
include     'kernel_abi.s'

org GAME_BOTTOM

game_init_vector: 
    dw  game_init

game_tick_vector: 
    dw  game_tick 

strpad      title, 32, "Lumberjacks"
strpad      author, 32, "Jeff Panici"
version:    db 1
revision:   db 2

include     'constants.s'
include     'macros.s'

; =========================================================
;
; Macros Section
;
; =========================================================
macro tile ypos, xpos, tile, pal {
    sub         sp, sp, #32
    mov         w20, ypos
    mov         w21, xpos
    stp         x20, x21, [sp]
    mov         w20, tile
    mov         w21, pal
    stp         x20, x21, [sp, #16]
    bl          draw_tile
}

macro stamp ypos, xpos, tile, pal {
    sub         sp, sp, #32
    mov         w20, ypos
    mov         w21, xpos
    stp         x20, x21, [sp]
    mov         w20, tile
    mov         w21, pal
    stp         x20, x21, [sp, #16]
    bl          draw_stamp
}

macro spr number {
    adr         x20, sprite_control
    mov         w21, 6 * 4
    mov         w22, number
    madd        w20, w22, w21, w20
}

macro spr_pos ypos, xpos {
    mov         w21, ypos
    mov         w22, xpos
    str         w21, [x20, SPR_Y_POS]
    str         w22, [x20, SPR_X_POS]
}

macro spr_addx pixels {
    ldr         w21, [x20, SPR_X_POS]
    add         w21, w21, pixels
    str         w21, [x20, SPR_X_POS]
}

macro spr_subx pixels {
    ldr         w21, [x20, SPR_X_POS]
    sub         w21, w21, pixels
    str         w21, [x20, SPR_X_POS]
}

macro spr_addy pixels {
    ldr         w21, [x20, SPR_Y_POS]
    add         w21, w21, pixels
    str         w21, [x20, SPR_Y_POS]
}

macro spr_suby pixels {
    ldr         w21, [x20, SPR_Y_POS]
    sub         w21, w21, pixels
    str         w21, [x20, SPR_Y_POS]
}

macro spr_tile tile {
    mov         w21, tile
    str         w21, [x20, SPR_TILE]
}

macro spr_pal pal {
    mov         w21, pal
    str         w21, [x20, SPR_PAL]
}

macro spr_flags flags {
    mov         w21, flags
    str         w21, [x20, SPR_FLAGS]
}

macro spr_user data {
    mov         w21, data
    str         w21, [x20, SPR_USER]
}


align 4

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
    sub         sp, sp, #80
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    stp         x5, x6, [sp, #48]
    stp         x7, x8, [sp, #64]
    ldp         x1, x2, [sp, #80]
    ldp         x3, x4, [sp, #96]

    mov         w5, TILE_BYTES
    mul         w3, w3, w5
    mov         w5, PALETTE_SIZE
    mul         w4, w4, w5

    mov         w5, SCREEN_WIDTH
    madd        w6, w1, w5, w2
    add         w0, w0, w6

    adr         x5, timber_bg
    add         w5, w5, w3
    mov         w6, TILE_HEIGHT
.raster:    
    mov         w7, TILE_WIDTH
.pixel:
    ldrb        w8, [x5], 1
    add         w8, w8, w4
    strb        w8, [x0], 1
    subs        w7, w7, 1
    b.ne        .pixel
    add         w0, w0, SCREEN_WIDTH - TILE_WIDTH
    subs        w6, w6, 1
    b.ne        .raster
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    ldp         x5, x6, [sp, #48]
    ldp         x7, x8, [sp, #64]
    add         sp, sp, #112
    ret

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
    sub         sp, sp, #80
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    stp         x5, x6, [sp, #48]
    stp         x7, x8, [sp, #64]
    ldp         x1, x2, [sp, #80]
    ldp         x3, x4, [sp, #96]

    mov         w5, SPRITE_BYTES
    mul         w3, w3, w5
    mov         w5, PALETTE_SIZE
    mul         w4, w4, w5

    mov         w5, SCREEN_WIDTH
    madd        w6, w1, w5, w2
    add         w0, w0, w6

    adr         x5, timber_fg
    add         w5, w5, w3
    mov         w6, SPRITE_HEIGHT
.raster:    
    mov         w7, SPRITE_WIDTH
.pixel:
    ldrb        w8, [x5], 1
    cbz         w8, .skip
    add         w8, w8, w4
    strb        w8, [x0], 1
    b           .done
.skip:  
    add         w0, w0, 1
.done:  
    subs        w7, w7, 1
    b.ne        .pixel
    add         w0, w0, SCREEN_WIDTH - SPRITE_WIDTH
    subs        w6, w6, 1
    b.ne        .raster

    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    ldp         x5, x6, [sp, #48]
    ldp         x7, x8, [sp, #64]
    add         sp, sp, #112
    ret

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
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    spr         0
    spr_pos     32, 32
    spr_tile    1
    spr         1
    spr_pos     64, 32
    spr_tile    2
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; game_update
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
game_update:
    sub         sp, sp, #16
    stp         x0, x30, [sp]

    ldp         x0, x30, [sp]
    add         sp, sp, #16
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
    sub         sp, sp, #80
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    stp         x5, x6, [sp, #48]
    stp         x7, x8, [sp, #64]

    bl          game_update

    adr         x1, background_control        
    mov         w2, 30
    mov         w3, 0              ; y
    mov         w4, 0              ; x 
.bg_row:        
    mov         w5, 32
.bg_tile:
    ldr         w6, [x1], 4       ; tile number
    ldr         w7, [x1], 4       ; palette
    add         w1, w1, 8         ; skip user data
    tile        w3, w4, w6, w7
    add         w4, w4, TILE_WIDTH
    subs        w5, w5, 1
    b.ne        .bg_tile
    mov         w4, 0
    add         w3, w3, TILE_HEIGHT
    subs        w2, w2, 1
    b.ne        .bg_row

    adr         x1, sprite_control
    mov         w2, 128
.sprite_tile:
    ldr         w3, [x1], 4         ; tile number
    ldr         w4, [x1], 4         ; y position
    ldr         w5, [x1], 4         ; x position
    ldr         w6, [x1], 4         ; palette number
    ldr         w7, [x1], 4         ; flags
    add         w1, w1, 4         ; skip user flags
    stamp       w4, w5, w3, w6
    subs        w2, w2, 1
    b.ne        .sprite_tile

    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    ldp         x5, x6, [sp, #48]
    ldp         x7, x8, [sp, #64]
    add         sp, sp, #80
    ret

; =========================================================
;
; Data Section
;
; =========================================================
SPR_TILE  = 0
SPR_Y_POS = 4
SPR_X_POS = 8
SPR_PAL   = 12
SPR_FLAGS = 16
SPR_USER  = 20

align 4
sprite_control:
rept 128 {
    dw  0       ; tile number
    dw  0       ; y position
    dw  0       ; x position
    dw  0       ; palette # 0-3
    dw  0       ; flags: hflip, vflip, rotate, etc....
    dw  0       ; user data
}

BG_TILE  = 0
BG_PAL   = 4
BG_USER1 = 8
BG_USER2 = 12

align 4
background_control:
rept 960 num {
    dw  num     ; tile number
    dw  0       ; palette # 0-3
    dw  0       ; user data 1
    dw  0       ; user data 2
}

timber_fg:
    file    'assets/timfg.bin'

timber_bg:
    file    'assets/timbg.bin'
