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
; Constants Section
;
; =========================================================
SPR_TILE        = 0
SPR_Y_POS       = 4
SPR_X_POS       = 8
SPR_PAL         = 12
SPR_FLAGS       = 13
SPR_RESERVE1    = 14
SPR_RESERVE2    = 15
SPR_USER1       = 16
SPR_USER2       = 20
SPR_BITMAP      = 24
SPR_CON_SZ      = 1048
SPR_CON_COUNT   = 128

F_SPR_NONE      = 00000000_00000000_00000000_00000000b
F_SPR_CHANGED   = 00000000_00000000_00000000_00000001b
F_SPR_HFLIP     = 00000000_00000000_00000000_00000010b
F_SPR_VFLIP     = 00000000_00000000_00000000_00000100b
F_SPR_ENABLED   = 00000000_00000000_10000000_00000000b

BG_TILE         = 0
BG_PAL          = 4
BG_FLAGS        = 5
BG_RESERVE1     = 6
BG_RESERVE2     = 7
BG_USER1        = 8
BG_USER2        = 12
BG_BITMAP       = 16
BG_CON_SZ       = 272
BG_ROW_COUNT    = 30
BG_COL_COUNT    = 32

F_BG_NONE       = 00000000_00000000_00000000_00000000b
F_BG_CHANGED    = 00000000_00000000_00000000_00000001b

; =========================================================
;
; Game Entry Point
;
; =========================================================
include     'macros.s'
include     'kernel_abi.s'
include     'constants.s'

org GAME_BOTTOM

game_init_vector: 
    dw  game_init

game_tick_vector: 
    dw  game_tick 

strpad      title, 32, "Lumberjacks"
strpad      author, 32, "Jeff Panici"
version:    db 1
revision:   db 2

; =========================================================
;
; Macros Section
;
; =========================================================
macro spr number {
    adr         x20, sprite_control
    mov         w21, SPR_CON_SZ
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

macro spr_user1 data {
    mov         w21, data
    str         w21, [x20, SPR_USER1]
}

macro spr_user2 data {
    mov         w21, data
    str         w21, [x20, SPR_USER2]
}

align 4

include     'util.s'

; =========================================================
;
; bg_copy
;
; stack:
;   dest address
;   src address
;   y pos
;   x pos
;
; registers:
;   (none)
;
; =========================================================
bg_copy:        
    sub         sp, sp, #64
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    stp         x5, x6, [sp, #48]

    ldp         x0, x1, [sp, #64]
    ldp         x2, x3, [sp, #80]

    mov         w4, SCREEN_WIDTH
    madd        w4, w2, w4, w3
    add         w0, w0, w4

    mov         w4, TILE_HEIGHT
.raster:    
    mov         w5, TILE_WIDTH
.pixel:
    ldrb        w6, [x1], 1
    strb        w6, [x0], 1
    subs        w5, w5, 1
    b.ne        .pixel
    add         w0, w0, SCREEN_WIDTH - TILE_WIDTH
    subs        w4, w4, 1
    b.ne        .raster

    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    ldp         x5, x6, [sp, #48]
    add         sp, sp, #96
    ret

macro bg_copy page_addr, src_addr, ypos, xpos {
    sub         sp, sp, #32
    mov         w25, page_addr
    mov         w26, src_addr
    stp         x25, x26, [sp]
    mov         w25, ypos
    mov         w26, xpos
    stp         x25, x26, [sp, #16]
    bl          bg_copy
}

; =========================================================
;
; bg_tile
;
; stack:
;   buffer address
;   flags
;   tile
;   palette
;
; registers:
;   (none)
;
; =========================================================
bg_tile:
    sub         sp, sp, #80
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    stp         x5, x6, [sp, #48]
    stp         x7, x8, [sp, #64]

    ldp         x0, x1, [sp, #80]
    ldp         x2, x3, [sp, #96]

    mov         w4, TILE_BYTES
    mul         w2, w2, w4
    
    mov         w4, PALETTE_SIZE
    mul         w3, w3, w4

    adr         x4, timber_bg
    add         w4, w4, w2    
    mov         w5, TILE_HEIGHT
.raster:    
    mov         w6, TILE_WIDTH
.pixel:
    ldrb        w7, [x4], 1
    add         w7, w7, w3
    strb        w7, [x0], 1
    subs        w6, w6, 1
    b.ne        .pixel
    subs        w5, w5, 1
    b.ne        .raster

    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    ldp         x5, x6, [sp, #48]
    ldp         x7, x8, [sp, #64]
    add         sp, sp, #112
    ret

macro bg_tile addr, flags, tile, pal {
    sub         sp, sp, #32
    mov         w25, addr
    mov         w26, flags
    stp         x25, x26, [sp]
    mov         w25, tile
    mov         w26, pal
    stp         x25, x26, [sp, #16]
    bl          bg_tile
}

; =========================================================
;
; fg_spr
;
; stack:
;   page address
;   src address
;   y pos
;   x pos
;
; registers:
;   (none)
;
; =========================================================
fg_spr:        
    sub         sp, sp, #64
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    stp         x5, x6, [sp, #48]

    ldp         x0, x1, [sp, #64]
    ldp         x2, x3, [sp, #80]

    mov         w4, SCREEN_WIDTH
    madd        w4, w2, w4, w3
    add         w0, w0, w4

    mov         w4, SPRITE_HEIGHT
.raster:    
    mov         w5, SPRITE_WIDTH
.pixel:
    ldrb        w6, [x1], 1
    cbz         w6, .skip
    strb        w6, [x0]
.skip:  
    add         w0, w0, 1
    subs        w5, w5, 1
    b.ne        .pixel
    add         w0, w0, SCREEN_WIDTH - SPRITE_WIDTH
    subs        w4, w4, 1
    b.ne        .raster

    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    ldp         x5, x6, [sp, #48]
    add         sp, sp, #96
    ret

macro fg_spr page_addr, src_addr, ypos, xpos {
    sub         sp, sp, #32
    mov         w25, page_addr
    mov         w26, src_addr
    stp         x25, x26, [sp]
    mov         w25, ypos
    mov         w26, xpos
    stp         x25, x26, [sp, #16]
    bl          fg_spr
}

; =========================================================
;
; fg_tile
;
; stack:
;   buffer address
;   flags
;   tile
;   palette
;
; registers:
;   (none)
;
; =========================================================
fg_tile:        
    sub         sp, sp, #80
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    stp         x5, x6, [sp, #48]
    stp         x7, x8, [sp, #64]

    ldp         x0, x1, [sp, #80]
    ldp         x2, x3, [sp, #96]
    mov         w4, SPRITE_BYTES
    mul         w2, w2, w4
    mov         w4, PALETTE_SIZE
    mul         w3, w3, w4

    adr         x4, timber_fg
    add         w4, w4, w2
    mov         w2, SPRITE_HEIGHT
.raster:    
    mov         w5, SPRITE_WIDTH
.pixel:
    ldrb        w6, [x4], 1
    add         w6, w6, w3
    strb        w6, [x0], 1
    subs        w5, w5, 1
    b.ne        .pixel
    subs        w2, w2, 1
    b.ne        .raster

    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    ldp         x5, x6, [sp, #48]
    ldp         x7, x8, [sp, #64]
    add         sp, sp, #112
    ret

macro fg_tile addr, flags, tile, pal {
    sub         sp, sp, #32
    mov         w25, addr
    mov         w26, flags
    stp         x25, x26, [sp]
    mov         w25, tile
    mov         w26, pal
    stp         x25, x26, [sp, #16]
    bl          fg_tile
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

macro game_update {
    bl          game_update
}

; =========================================================
;
; bg_update
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
bg_update:
    sub         sp, sp, #80
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    stp         x5, x6, [sp, #48]
    stp         x7, x8, [sp, #64]

    adr         x0, background_control        
    mov         w1, 0              ; y
    mov         w2, 0              ; x 
    mov         w3, BG_ROW_COUNT
.row:        
    mov         w4, BG_COL_COUNT
.column:
    ldrb        w5, [x0, BG_FLAGS]
    tst         w5, F_BG_CHANGED
    b.eq        .next
    ldr         w6, [x0, BG_TILE]
    ldrb        w7, [x0, BG_PAL]
    add         w8, w0, BG_BITMAP
    bg_tile     w8, w5, w6, w7
    bic         w5, w5, F_BG_CHANGED
    strb        w5, [x0, BG_FLAGS]

    ; XXX: this is for testing only!
    ;       will change this to be part of a dma cb chain
    adr         x5, bg_buffer
    bg_copy     w5, w8, w1, w2

.next:
    add         w0, w0, BG_CON_SZ
    add         w2, w2, TILE_WIDTH
    subs        w4, w4, 1
    b.ne        .column

    mov         w2, 0
    add         w1, w1, TILE_HEIGHT
    subs        w3, w3, 1
    b.ne        .row

    ; invoke dma on head of tile blit list
    ; wait on tile blit dmas

    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    ldp         x5, x6, [sp, #48]
    ldp         x7, x8, [sp, #64]
    add         sp, sp, #80
    ret

macro bg_update {
    bl          bg_update
}

; =========================================================
;
; fg_update
;
; stack:
;   frame buffer page address
;   pad
;
; registers:
;   (none)
;
; =========================================================
fg_update:
    sub         sp, sp, #80
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    stp         x5, x6, [sp, #48]
    stp         x7, x8, [sp, #64]

    ldp         x6, x7, [sp, #80]
    adr         x0, sprite_control
    mov         w1, SPR_CON_COUNT
.loop:
    ldrb        w2, [x0, SPR_FLAGS]
    tst         w2, F_SPR_ENABLED
    b.eq        .next
    tst         w2, F_SPR_CHANGED
    b.eq        .blit    
    add         w3, w0, SPR_BITMAP
    ldr         w4, [x0, SPR_TILE]
    ldrb        w5, [x0, SPR_PAL]
    fg_tile     w3, w2, w4, w5
    bic         w2, w2, F_SPR_CHANGED
    strb        w2, [x0, SPR_FLAGS]
.blit:
    ldr         w4, [x0, SPR_Y_POS]
    ldr         w5, [x0, SPR_X_POS]
    fg_spr      w6, w3, w4, w5
.next:    
    add         w0, w0, SPR_CON_SZ
    subs        w1, w1, 1
    b.ne        .loop

    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    ldp         x5, x6, [sp, #48]
    ldp         x7, x8, [sp, #64]
    add         sp, sp, #96
    ret

macro fg_update page_addr {
    sub         sp, sp, #16
    mov         w25, page_addr
    mov         w26, 0
    stp         x25, x26, [sp]
    bl          fg_update
}

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
    sub         sp, sp, #32
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]

    game_update
    bg_update

    ; XXX: this is temporary to test everything
    ;      -and- then we'll introduce dma to break it ;-)
    adr         x1, bg_buffer
    copy        w1, w0, SCREEN_BYTES
    
    fg_update   w0

    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    add         sp, sp, #32
    ret

; =========================================================
;
; Background Map Data Section
;
; =========================================================
playfield_map:


; =========================================================
;
; Bitmap Data Section
;
; =========================================================
timber_fg:
    file    'assets/timfg.bin'

timber_bg:
    file    'assets/timbg.bin'

; =========================================================
;
; Control Data Section
;
; =========================================================
align 4
sprite_control:
rept 128 {
    rw  1       ; tile number
    rw  1       ; y position
    rw  1       ; x position
    rb  1       ; palette # 0-3
    rb  1       ; flags
    rb  2       ; reserved
    rw  1       ; user data 1
    rw  1       ; user data 2
    rb  1024
}

align 4
background_control:
rept 960 {
    rw  1       ; tile number
    rb  1       ; palette # 0-3
    rb  1       ; flags
    rb  2       ; reserved
    rw  1       ; user data 1
    rw  1       ; user data 2
    rb  256
}

align 4
bg_buffer:
    rb  SCREEN_WIDTH * SCREEN_HEIGHT
