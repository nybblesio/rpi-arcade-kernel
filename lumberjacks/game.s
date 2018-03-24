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
NONE_STATE_ID      = 0
ATTRACT_STATE_ID   = 1
GAME_STATE_ID      = 2
GAME_OVER_STATE_ID = 3

STATE_ENTER     = 0
STATE_UPDATE    = 4
STATE_LEAVE     = 8
STATE_SZ        = 12

SPR_TILE        = 0
SPR_Y_POS       = 2
SPR_X_POS       = 4
SPR_PAL         = 6
SPR_FLAGS       = 7
SPR_RESERVE1    = 8
SPR_RESERVE2    = 9
SPR_USER1       = 10
SPR_USER2       = 14
SPR_BITMAP      = 18
SPR_CON_SZ      = 1042
SPR_CON_COUNT   = 128

F_SPR_NONE      = 00000000b
F_SPR_CHANGED   = 00000001b
F_SPR_HFLIP     = 00000010b
F_SPR_VFLIP     = 00000100b
F_SPR_ENABLED   = 00001000b

BG_TILE         = 0
BG_PAL          = 2
BG_FLAGS        = 3
BG_RESERVE1     = 4
BG_RESERVE2     = 5
BG_USER1        = 6
BG_USER2        = 10
BG_BITMAP       = 14
BG_CON_SZ       = 270
BG_ROW_COUNT    = 30
BG_COL_COUNT    = 32

F_BG_NONE       = 00000000b
F_BG_CHANGED    = 00000001b
F_BG_HFLIP      = 00000010b
F_BG_VFLIP      = 00000100b

ACTOR_Y_POS     = 0
ACTOR_X_POS     = 2
ACTOR_SPR_START = 4
ACTOR_SPR_COUNT = 5
ACTOR_FLAGS     = 6
ACTOR_FRAME_IDX = 7
ACTOR_RESERVED  = 8
ACTOR_ANIM      = 9
ACTOR_TIMER     = 13
ACTOR_SZ        = 17

F_ACTOR_NONE      = 00000000b
F_ACTOR_VISIBLE   = 00000001b
F_ACTOR_COLLIDED  = 00000010b
F_ACTOR_END       = 10000000b

PLAYER_LIVES = 0
PLAYER_TREES = 2
PLAYER_SCORE = 4
PLAYER_SZ    = 8

ANIM_DEF_NUM_FRAMES = 0
ANIM_DEF_NUM_MS     = 1
ANIM_DEF_SZ         = 2

FRAME_START_NUMBER     = 0
FRAME_START_TILE_COUNT = 1
FRAME_START_SZ         = 2

FRAME_TILE_INDEX       = 0
FRAME_TILE_X_OFFSET    = 4
FRAME_TILE_Y_OFFSET    = 6
FRAME_TILE_PALETTE     = 8
FRAME_TILE_FLAGS       = 9
FRAME_TILE_SZ          = 9

; =========================================================
;
; Game Entry Point
;
; =========================================================
include     'macros.s'
include     'kernel_abi.s'
include     'constants.s'

org GAME_BOTTOM

load_vector:    dw  on_load
unload_vector:  dw  on_unload
tick_vector:    dw  on_tick 
run_vector:     dw  on_run
stop_vector:    dw  on_stop

strpad      title, 32, "Lumberjacks"
strpad      author, 32, "Jeff Panici"
version:    db 1
revision:   db 2

; =========================================================
;
; Macros Section
;
; =========================================================
macro playerdef name {
align 4
common
label name
    dh  0
    dh  0
    dw  0
}

macro statedef name, enter, update, leave {
common
label name
    dw  enter
    dw  update
    dw  leave
}

macro state_load state {
    mov             w25, state
    mov             w26, STATE_SZ
    mul             w25, w25, w26
    adr             x26, state_callbacks
    add             w26, w26, w25
}

macro state_go id {
    mov             w25, id
    pstoreb         x26, w25, next_state    
}

macro actordef name*, spr_no*, spr_count*, xpos*, ypos*, flags* {
common
label name
    dh  ypos
    dh  xpos
    db  spr_no
    db  spr_count
    db  flags   ; flags
    db  0       ; frame index
    db  0       ; reserved
    dw  0       ; animation ptr
    dw  0       ; animation timer ptr
}

macro animdef name*, num_frames*, num_ms* {
align 4
common
label name
    db  num_frames
    db  num_ms
}

macro framestart num, num_tiles {
    db  num
    db  num_tiles
}

macro frameend {
}

macro frametile tile, xoff, yoff, pal, flags {
    dw  tile
    dh  xoff
    dh  yoff
    db  pal
    db  flags
}

macro actor name {
    adr             x25, name
}

macro actor_pos ypos, xpos {
    mov             w26, ypos
    mov             w27, xpos
    strh            w26, [x25, ACTOR_Y_POS]
    strh            w27, [x25, ACTOR_X_POS]
}

macro actor_anim anim {
    adr             x26, anim
    str             w26, [x25, ACTOR_ANIM]
    mov             w26, 0
    strb            w26, [x25, ACTOR_FRAME_IDX]
    str             w26, [x25, ACTOR_TIMER]
}

macro actor_flags flags {
    mov             w26, flags
    strb            w26, [x25, ACTOR_FLAGS]
}

macro actor_addx pixels, upper_bound {
    local           .clamp
    ldrh            w26, [x25, ACTOR_X_POS]
    cmp             w26, upper_bound
    b.hs            .clamp
    add             w26, w26, pixels
    strh            w26, [x25, ACTOR_X_POS]
.clamp:    
}

macro actor_subx pixels, lower_bound {
    local           .clamp
    ldrh            w26, [x25, ACTOR_X_POS]
    cmp             w26, lower_bound
    b.ls            .clamp
    sub             w26, w26, pixels
    strh            w26, [x25, ACTOR_X_POS]
.clamp:    
}

macro actor_addy pixels, upper_bound {
    local           .clamp
    ldrh            w26, [x25, ACTOR_Y_POS]
    cmp             w26, upper_bound
    b.hs            .clamp
    add             w26, w26, pixels
    strh            w26, [x25, ACTOR_Y_POS]
.clamp:    
}

macro actor_suby pixels, lower_bound {
    local           .clamp
    ldrh            w26, [x25, ACTOR_Y_POS]
    cmp             w26, lower_bound
    b.ls            .clamp
    sub             w26, w26, pixels
    strh            w26, [x25, ACTOR_Y_POS]
.clamp:    
}

macro spr number {
    adr             x25, sprite_control
    mov             w26, SPR_CON_SZ
    mov             w27, number
    madd            w25, w26, w27, w25
}

macro spr_pos ypos, xpos {
    mov             w26, ypos
    mov             w27, xpos
    strh            w26, [x25, SPR_Y_POS]
    strh            w27, [x25, SPR_X_POS]
}

macro spr_addx pixels {
    ldrh            w26, [x25, SPR_X_POS]
    add             w26, w26, pixels
    strh            w26, [x25, SPR_X_POS]
}

macro spr_subx pixels {
    ldrh            w26, [x25, SPR_X_POS]
    sub             w26, w26, pixels
    strh            w26, [x25, SPR_X_POS]
}

macro spr_addy pixels {
    ldrh            w26, [x25, SPR_Y_POS]
    add             w26, w26, pixels
    strh            w26, [x25, SPR_Y_POS]
}

macro spr_suby pixels {
    ldrh            w26, [x25, SPR_Y_POS]
    sub             w26, w26, pixels
    strh            w26, [x25, SPR_Y_POS]
}

macro spr_tile tile {
    mov             w26, tile
    strh            w26, [x25, SPR_TILE]
}

macro spr_pal pal {
    mov             w26, pal
    strb            w26, [x25, SPR_PAL]
}

macro spr_flags flags {
    mov             w26, flags
    strb            w26, [x25, SPR_FLAGS]
}

macro spr_user1 data {
    mov             w26, data
    str             w26, [x25, SPR_USER1]
}

macro spr_user2 data {
    mov             w26, data
    str             w26, [x25, SPR_USER2]
}

align 4

include     'util.s'
include     'pool.s'
include     'timer.s'

; =========================================================
;
; timer_anim_callback
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
timer_anim_callback:
    sub         sp, sp, #64
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    stp         x5, x6, [sp, #48]

    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    ldp         x5, x6, [sp, #48]
    add         sp, sp, #64
    ret

; =========================================================
;
; actor_update
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
actor_update:
    sub         sp, sp, #96
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    stp         x5, x6, [sp, #48]
    stp         x7, x8, [sp, #64]
    stp         x9, x10, [sp, #80]
    adr         x0, actors
.loop:
    ldrb        w1, [x0, ACTOR_FLAGS]
    tst         w1, F_ACTOR_END
    b.ne        .done
    ldrb        w2, [x0, ACTOR_SPR_START]
    ldrb        w3, [x0, ACTOR_SPR_COUNT]
.reset_loop:
    spr         w2
    spr_flags   F_SPR_NONE
    add         w2, w2, 1
    subs        w3, w3, 1
    b.ne        .reset_loop
    tst         w1, F_ACTOR_VISIBLE
    b.eq        .next
.visible:    
    ldr         w2, [x0, ACTOR_ANIM]
    cbz         w2, .next
    ;
    ; need to handle the animation timer stuff
    ;
.layout:
    add         w2, w2, ANIM_DEF_SZ
    ldrb        w3, [x0, ACTOR_FRAME_IDX]
    mov         w5, FRAME_TILE_SZ
    mov         w6, FRAME_START_SZ
.frame_skip:    
    cbz         w3, .layout_frame
    ldrb        w4, [x2, FRAME_START_TILE_COUNT]
    madd        w4, w4, w5, w6
    add         w2, w2, w4
    sub         w3, w3, 1
    b           .frame_skip
.layout_frame:    
    ldrb        w3, [x2, FRAME_START_TILE_COUNT]
    add         w2, w2, FRAME_START_SZ
    ldrb        w4, [x0, ACTOR_SPR_START]
    ldrh        w5, [x0, ACTOR_Y_POS]
    ldrh        w6, [x0, ACTOR_X_POS]
.sprite:
    spr         w4
    ldrh        w7, [x2, FRAME_TILE_Y_OFFSET]
    ldrh        w8, [x2, FRAME_TILE_X_OFFSET]
    add         w7, w7, w5
    add         w8, w8, w6
    spr_pos     w7, w8
    ldr         w7, [x2, FRAME_TILE_INDEX]
    spr_tile    w7
    ldrb        w7, [x2, FRAME_TILE_PALETTE]
    spr_pal     w7
    ldrb        w7, [x2, FRAME_TILE_FLAGS]
    orr         w7, w7, F_SPR_ENABLED
    orr         w7, w7, F_SPR_CHANGED
    spr_flags   w7
    add         w4, w4, 1
    subs        w3, w3, 1
    b.ne        .sprite
.next:
    add         w0, w0, ACTOR_SZ
    b           .loop
.done:
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    ldp         x5, x6, [sp, #48]
    ldp         x7, x8, [sp, #64]
    ldp         x9, x10, [sp, #80]
    add         sp, sp, #96
    ret

macro actor_update {
    bl          actor_update
}

; =========================================================
;
; bg_set
;
; stack:
;   tile table address
;   attr table address
;
; registers:
;   (none)
;
; =========================================================
bg_set:
    sub         sp, sp, #64
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    stp         x5, x6, [sp, #48]
    ldp         x0, x1, [sp, #64]
    adr         x2, background_control
    mov         w3, BG_ROW_COUNT * BG_COL_COUNT
.loop:
    ldrh        w4, [x0], 2
    strh        w4, [x2, BG_TILE]
    ldrh        w4, [x1], 2
    and         w5, w4, $ff
    orr         w5, w5, F_BG_CHANGED
    strb        w5, [x2, BG_FLAGS]
    lsr         w5, w4, 8
    and         w5, w5, $ff
    strb        w5, [x2, BG_PAL]
    add         x2, x2, BG_CON_SZ
    subs        w3, w3, 1
    b.ne        .loop
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    ldp         x5, x6, [sp, #48]
    add         sp, sp, #80
    ret

macro bg_set tile_addr, attr_addr {
    sub         sp, sp, #16
    adr         x25, tile_addr
    adr         x26, attr_addr
    stp         x25, x26, [sp]
    bl          bg_set
}

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
    tst         w1, F_BG_HFLIP
    b.ne        .hflip
    mov         w5, TILE_HEIGHT * TILE_WIDTH
.noflip:
    ldrb        w7, [x4], 1
    add         w7, w7, w3
    strb        w7, [x0], 1
    subs        w5, w5, 1
    b.ne        .noflip
    b           .check_vflip
.hflip:
    mov         w6, TILE_HEIGHT
.hflip_line:    
    add         w4, w4, TILE_WIDTH
    mov         w8, w4
    mov         w5, TILE_WIDTH
.hflip_pixel:
    ldrb        w7, [x4]
    add         w7, w7, w3
    strb        w7, [x0], 1
    sub         w4, w4, 1
    subs        w5, w5, 1
    b.ne        .hflip_pixel
    mov         w4, w8
    subs        w6, w6, 1
    b.ne        .hflip_line
.check_vflip:
    tst         w1, F_BG_VFLIP
    b.eq        .exit
.vflip:
.exit:
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
    ldrh        w6, [x0, BG_TILE]
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
; fg_reset
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
fg_reset:
    sub         sp, sp, #32
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    adr         x0, sprite_control
    mov         w1, SPR_CON_COUNT
.loop:
    mem_fill8   w0, SPR_CON_SZ, 0
    add         w0, w0, SPR_CON_SZ
    subs        w1, w1, 1
    b.ne        .loop
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    add         sp, sp, #32
    ret

macro fg_reset {
    bl          fg_reset
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
    mov         w2, SPRITE_HEIGHT * SPRITE_WIDTH
.pixel:
    ldrb        w6, [x4], 1
    add         w6, w6, w3
    strb        w6, [x0], 1
    subs        w2, w2, 1
    b.ne        .pixel
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
    add         w3, w0, SPR_BITMAP
    ldrb        w2, [x0, SPR_FLAGS]
    tst         w2, F_SPR_ENABLED
    b.eq        .next
    tst         w2, F_SPR_CHANGED
    b.eq        .blit    
    ldrh        w4, [x0, SPR_TILE]
    ldrb        w5, [x0, SPR_PAL]
    fg_tile     w3, w2, w4, w5
    bic         w2, w2, F_SPR_CHANGED
    strb        w2, [x0, SPR_FLAGS]
.blit:
    ldrh        w4, [x0, SPR_Y_POS]
    ldrh        w5, [x0, SPR_X_POS]
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
; attract_enter_cb
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
attract_enter_cb:
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    bg_set      title_bg, title_bg_attr
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; attract_update_cb
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
attract_update_cb:
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    joy_check   JOY0_START
    cbz         w26, .exit
    state_go    GAME_STATE_ID
.exit:    
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; attract_leave_cb
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
attract_leave_cb:
    sub         sp, sp, #16
    stp         x0, x30, [sp]

    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; game_enter_cb
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
game_enter_cb:
    sub             sp, sp, #16
    stp             x0, x30, [sp]
    bg_set          playfield_bg, playfield_bg_attr
    actor           mustache_man
    actor_pos       256, 128
    actor_anim      mustache_man_stand
    actor_flags     F_ACTOR_VISIBLE
    ldp             x0, x30, [sp]
    add             sp, sp, #16
    ret

; =========================================================
;
; game_update_cb
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
game_update_cb:
    sub             sp, sp, #16
    stp             x0, x30, [sp]
    actor           mustache_man
    joy_check       JOY0_LEFT
    cbz             w26, .right    
    actor_subx      2, 0    
    actor_anim      mustache_man_walk_left
    b               .update
.right:    
    joy_check       JOY0_RIGHT
    cbz             w26, .select
    actor_addx      2, SCREEN_WIDTH - SPRITE_WIDTH
    actor_anim      mustache_man_walk_right
    b               .update
.select:    
    joy_check       JOY0_SELECT
    cbz             w26, .update
    state_go        ATTRACT_STATE_ID
    b               .exit
.update:    
    actor_update
.exit:    
    ldp             x0, x30, [sp]
    add             sp, sp, #16
    ret

; =========================================================
;
; game_leave_cb
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
game_leave_cb:
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    actor       mustache_man
    actor_flags F_ACTOR_NONE
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; game_over_enter_cb
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
game_over_enter_cb:
    sub         sp, sp, #16
    stp         x0, x30, [sp]

    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; game_over_update_cb
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
game_over_update_cb:
    sub         sp, sp, #16
    stp         x0, x30, [sp]

    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; game_over_leave_cb
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
game_over_leave_cb:
    sub         sp, sp, #16
    stp         x0, x30, [sp]

    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; on_update
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
on_update:
    sub         sp, sp, #32
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    ploadb      x0, w0, next_state
    cbz         w0, .update
    ploadb      x1, w1, current_state
    cbz         w1, .no_current
    state_load  w1
    ldr         w2, [x26, STATE_LEAVE]
    cbz         w2, .no_current
    blr         x2
.no_current:
    pstoreb     x2, w0, current_state 
    pstoreb     x2, w1, previous_state
    mov         w1, NONE_STATE_ID
    pstoreb     x2, w1, next_state
    state_load  w0
    ldr         w2, [x26, STATE_ENTER]
    cbz         w2, .done
    blr         x2
    b           .done
.update:    
    ploadb      x0, w0, current_state
    state_load  w0
    ldr         w0, [x26, STATE_UPDATE]
    cbz         w0, .done
    blr         x0
.done:    
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    add         sp, sp, #32
    ret

macro on_update {
    bl          on_update
}

; =========================================================
;
; on_load
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
on_load:
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    fg_reset   
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; on_unload
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
on_unload:
    sub         sp, sp, #16
    stp         x0, x30, [sp]

    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; on_run
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
on_run:
    sub         sp, sp, #32
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    adr         x0, player1
    mov         w1, 3
    strh        w1, [x0, PLAYER_LIVES]
    mov         w1, 0
    strh        w1, [x0, PLAYER_TREES]
    str         w1, [x0, PLAYER_SCORE]
    adr         x0, player2
    mov         w1, 3
    strh        w1, [x0, PLAYER_LIVES]
    mov         w1, 0
    strh        w1, [x0, PLAYER_TREES]
    str         w1, [x0, PLAYER_SCORE]
    mov         w1, NONE_STATE_ID
    pstoreb     x0, w1, previous_state
    pstoreb     x0, w1, current_state
    state_go    ATTRACT_STATE_ID
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    add         sp, sp, #32
    ret

; =========================================================
;
; on_stop
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
on_stop:
    sub         sp, sp, #16
    stp         x0, x30, [sp]

    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; on_tick
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
on_tick:
    sub         sp, sp, #32
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]

    on_update
    bg_update

    ; XXX: this is temporary to test everything
    ;      -and- then we'll introduce dma to break it ;-)
    adr         x1, bg_buffer
    mem_copy64  w1, w0, SCREEN_BYTES / 8
    
    fg_update   w0

    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    add         sp, sp, #32
    ret

; =========================================================
;
; Variables Data Section
;
; =========================================================
timerdef timer_anim, 100, 0, timer_anim_callback

previous_state: db  NONE_STATE_ID
current_state:  db  NONE_STATE_ID
next_state:     db  NONE_STATE_ID

align 4
state_callbacks:
    statedef none_state,      0,                  0,                    0       
    statedef attract_state,   attract_enter_cb,   attract_update_cb,    attract_leave_cb
    statedef game_state,      game_enter_cb,      game_update_cb,       game_leave_cb
    statedef game_over_state, game_over_enter_cb, game_over_update_cb,  game_over_leave_cb

align 4
actors:
    actordef bird1,        0,  1, 0, 0, F_ACTOR_NONE
    actordef bear1,        1,  4, 0, 0, F_ACTOR_NONE
    actordef swarm,        5,  1, 0, 0, F_ACTOR_NONE
    actordef whistle,      6,  3, 0, 0, F_ACTOR_NONE
    actordef beehive,      9,  1, 0, 0, F_ACTOR_NONE
    actordef foreman,      10, 4, 0, 0, F_ACTOR_NONE
    actordef other_guy,    14, 4, 0, 0, F_ACTOR_NONE
    actordef mustache_man, 18, 4, 0, 0, F_ACTOR_NONE
    actordef tree0,        22, 4, 0, 0, F_ACTOR_NONE
    actordef tree1,        26, 4, 0, 0, F_ACTOR_NONE
    actordef tree2,        30, 4, 0, 0, F_ACTOR_NONE
    actordef tree3,        34, 4, 0, 0, F_ACTOR_NONE
    actordef tree4,        38, 4, 0, 0, F_ACTOR_NONE
    actordef tree5,        42, 4, 0, 0, F_ACTOR_NONE
    actordef tree6,        46, 4, 0, 0, F_ACTOR_NONE
    actordef tree7,        50, 4, 0, 0, F_ACTOR_NONE
    actordef tree8,        54, 4, 0, 0, F_ACTOR_NONE
    actordef tree9,        58, 4, 0, 0, F_ACTOR_NONE
    actordef end_of_list,  0,  0, 0, 0, F_ACTOR_END

animdef mustache_man_stand, 1, 0
framestart 0, 2
    frametile 1, 0,  0, PAL1, F_SPR_NONE
    frametile 2, 0, 32, PAL1, F_SPR_NONE
frameend

animdef mustache_man_walk_right, 4, 40
framestart 0, 2
    frametile 6, 0,  0, PAL1, F_SPR_NONE
    frametile 7, 0, 32, PAL1, F_SPR_NONE
frameend
framestart 1, 2
    frametile 8, 0, 0, PAL1, F_SPR_NONE
    frametile 9, 0, 32, PAL1, F_SPR_NONE
frameend
framestart 2, 2
    frametile 10, 0, 0, PAL1, F_SPR_NONE
    frametile 11, 0, 32, PAL1, F_SPR_NONE
frameend
framestart 3, 2
    frametile 12, 0, 0, PAL1, F_SPR_NONE
    frametile 13, 0, 32, PAL1, F_SPR_NONE
frameend

animdef mustache_man_walk_left, 4, 40
framestart 0, 2
    frametile 6, 0,  0, PAL1, F_SPR_HFLIP
    frametile 7, 0, 32, PAL1, F_SPR_HFLIP
frameend
framestart 1, 2
    frametile 8, 0, 0, PAL1, F_SPR_HFLIP
    frametile 9, 0, 32, PAL1, F_SPR_HFLIP
frameend
framestart 2, 2
    frametile 10, 0, 0, PAL1, F_SPR_HFLIP
    frametile 11, 0, 32, PAL1, F_SPR_HFLIP
frameend
framestart 3, 2
    frametile 12, 0, 0, PAL1, F_SPR_HFLIP
    frametile 13, 0, 32, PAL1, F_SPR_HFLIP
frameend

animdef mustache_man_walk_up, 4, 40

animdef mustache_man_walk_down, 4, 40

animdef mustache_man_push_right, 4, 40

animdef mustache_man_push_left, 4, 40

animdef mustache_man_chop_right, 4, 40

animdef mustache_man_chop_left, 4, 40

animdef mustache_man_fall_up, 4, 40

animdef mustache_man_fall_down, 4, 40

animdef mustache_man_collide, 4, 40

animdef mustache_man_swarm, 4, 40

animdef mustache_man_shaken, 4, 40

animdef mustache_man_wave, 4, 40

animdef mustache_man_in_a_tree, 4, 40

playerdef player1
playerdef player2

; =========================================================
;
; Background Map Data Section
;
; =========================================================
align 4

title_bg_attr:
    ;     01     02     03     04     05     06    07      08     09     10     11     12     13     14     15     16     17     18     19     20     21     22     23     24     25     26     27     28     29     30     31     32
    ;     00     16     32     48     64     80    96     112    128    144    160    176    192    208    224    240    256    272    288    304    320    336    352    368    384    400    416    432    448    464    480    496
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100

align 4

title_bg:
    ;     01     02     03     04     05     06    07      08     09     10     11     12     13     14     15     16     17     18     19     20     21     22     23     24     25     26     27     28     29     30     31     32
    ;     00     16     32     48     64     80    96     112    128    144    160    176    192    208    224    240    256    272    288    304    320    336    352    368    384    400    416    432    448    464    480    496
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $012a, $012b, $012c, $012d, $012e, $012f, $0130, $0131, $0132, $0133, $0134, $0135, $0136, $0137, $01f3, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0145, $0144, $0143, $0142, $0141, $0140, $013f, $013e, $013d, $013c, $013b, $013a, $0139, $0138, $01f2, $01f1, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0146, $0147, $0148, $0149, $014a, $014b, $014c, $014d, $014e, $014f, $0150, $0151, $0152, $0153, $01ef, $01f0, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0147, $0000, $015e, $015d, $015c, $015b, $015a, $0159, $0158, $0157, $0156, $0155, $0154, $01ee, $01ed, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0147, $0000, $015e, $015f, $0160, $0161, $0162, $0163, $0164, $0165, $0166, $0167, $0168, $01eb, $01ec, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0147, $0000, $015e, $0172, $0171, $0170, $016f, $016e, $016d, $016c, $016b, $016a, $0169, $01ea, $01e9, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0147, $0173, $0174, $0175, $0176, $0177, $0178, $0179, $017a, $017b, $017c, $017d, $017e, $01e7, $01e8, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $018a, $0189, $0188, $0187, $0186, $0000, $0000, $0000, $0000, $0000, $0181, $0180, $017f, $01e6, $01e5, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $018b, $018c, $018d, $018e, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0196, $01e4, $01e3, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $01a0, $019f, $019e, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $01e1, $01e2, $03b5, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $01a1, $01a2, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $01de, $01df, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $01b9, $01b8, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $01dd, $01dc, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $003a, $0043, $004f, $0050, $0059, $0052, $0049, $0047, $0048, $0054, $0000, $004d, $0043, $004d, $004c, $0058, $0058, $0058, $0049, $0056, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0042, $0041, $004c, $004c, $0059, $0000, $004d, $0049, $0044, $0057, $0041, $0059, $0000, $004d, $0046, $0047, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0041, $004c, $004c, $0000, $0052, $0049, $0047, $0048, $0054, $0053, $0000, $0052, $0045, $0053, $0045, $0052, $0056, $0045, $0044, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000

align 4

playfield_bg_attr:
    ;     01     02     03     04     05     06    07      08     09     10     11     12     13     14     15     16     17     18     19     20     21     22     23     24     25     26     27     28     29     30     31     32
    ;     00     16     32     48     64     80    96     112    128    144    160    176    192    208    224    240    256    272    288    304    320    336    352    368    384    400    416    432    448    464    480    496
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0102, $0102, $0100, $0102, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0102, $0102, $0102, $0100, $0102, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0102, $0100, $0102, $0100, $0100, $0100, $0100, $0100, $0100, $0102, $0100, $0102
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0102, $0102, $0100, $0100, $0100, $0100, $0100, $0102, $0100, $0102
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0102, $0100, $0100, $0100, $0102, $0102, $0100, $0100, $0100, $0102, $0102, $0102, $0102, $0102, $0102, $0102, $0102, $0102, $0102
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0102, $0102, $0100, $0100, $0100, $0102, $0102, $0102, $0102, $0102, $0102, $0100, $0102, $0102, $0102
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0102, $0102, $0100, $0100, $0100, $0102, $0102, $0102, $0102, $0102, $0100, $0100, $0100, $0102, $0102
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0102, $0100, $0100, $0100, $0100, $0102, $0102, $0102, $0102, $0102, $0102, $0102, $0102, $0102, $0102
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0102, $0100, $0100, $0100, $0100, $0102, $0102, $0102, $0102, $0102, $0102, $0102, $0102, $0102, $0102
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0102, $0100, $0100, $0100, $0100, $0102, $0102, $0102, $0102, $0102, $0102, $0102, $0102, $0102, $0102
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0102, $0102, $0102, $0102, $0102, $0102, $0100, $0102, $0102, $0102
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0102, $0100, $0100, $0102, $0102
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0102, $0102, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0102, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0102, $0102, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0102, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0102, $0102, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0102, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0102, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0102
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0102
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100
    dh  $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100, $0100

align 4

playfield_bg:
    ;     01     02     03     04     05     06     07    08      09     10     11     12     13     14     15     16     17     18     19     20     21     22     23     24     25     26     27     28     29     30     31     32 
    ;     00     16     32     48     64     80     96    112    128    144    160    176    192    208    224    240    256    272    288    304    320    336    352    368    384    400    416    432    448    464    480    496 
    dh  $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $0011, $0012, $0013, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a
    dh  $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $0014, $0015, $0016, $0017, $0027, $0028, $0027, $0028, $0028, $0027, $0025, $0026, $0024, $0023, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a
    dh  $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $0018, $0019, $001a, $002b, $002a, $0029, $0029, $0029, $0029, $002a, $002b, $0029, $002c, $002d, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a, $000a
    dh  $00a8, $000a, $00aa, $00ab, $00ac, $00ad, $00ae, $00af, $0082, $001c, $001d, $001e, $001f, $002f, $002f, $00bf, $005d, $001f, $002f, $005c, $005b, $002f, $002e, $00aa, $00b0, $00b1, $00b2, $00b3, $00b4, $00aa, $000a, $00a8
    dh  $00a7, $000a, $00aa, $0009, $0009, $0009, $0009, $0009, $0082, $0064, $0063, $0062, $0061, $0060, $005f, $005f, $005f, $005f, $0060, $0061, $0062, $0063, $0064, $0082, $0009, $0009, $00a9, $0009, $0009, $00aa, $000a, $00a7
    dh  $00a6, $009a, $0099, $0093, $0092, $0091, $0088, $0087, $0081, $0065, $0066, $0067, $0067, $0066, $006a, $005e, $005e, $006a, $0069, $0068, $0068, $0069, $0065, $0081, $0087, $0088, $0091, $0092, $0093, $0099, $009a, $00a6
    dh  $00a5, $009b, $009c, $0000, $0000, $0090, $0089, $0086, $0080, $006e, $006d, $0009, $0009, $00de, $006b, $0009, $0009, $006b, $006c, $0009, $0009, $006c, $006e, $0080, $0086, $0089, $0090, $0000, $0000, $009c, $009b, $00a5
    dh  $00a3, $00a4, $0000, $0000, $0000, $008f, $008a, $0085, $007f, $006f, $00d9, $00da, $00da, $00f7, $0070, $0009, $0009, $0070, $00dd, $00dc, $00dc, $00dd, $006f, $007f, $0085, $008a, $008f, $0000, $0000, $0000, $00a4, $00a3
    dh  $00a2, $009e, $009d, $0098, $0095, $008e, $008b, $0084, $007e, $007b, $007a, $0077, $0076, $0072, $0071, $0009, $0009, $0071, $0077, $0076, $0077, $007a, $007b, $007e, $0084, $008b, $008e, $0095, $0098, $009d, $009e, $00a2
    dh  $00a1, $009f, $00a0, $0097, $0096, $008d, $008c, $0083, $007d, $007c, $0079, $0078, $0075, $0074, $0073, $0009, $0009, $0073, $0074, $0075, $0078, $0079, $007c, $007d, $0083, $008c, $008d, $0096, $0097, $00a0, $009f, $00a1
    dh  $00b5, $00b6, $00b7, $00b8, $00b9, $00ba, $00bb, $00bc, $00bd, $00be, $00c0, $00c1, $00c2, $00c3, $00c4, $0094, $0094, $00c4, $00c3, $00c2, $00c1, $00c0, $00be, $00bd, $00bc, $00bb, $00ba, $00b9, $00b8, $00b7, $00b6, $00b5
    dh  $001b, $00cc, $00cd, $0003, $00cf, $001b, $001b, $001b, $001b, $001b, $001b, $001b, $001b, $001b, $001b, $0000, $0000, $001b, $001b, $001b, $001b, $001b, $001b, $001b, $001b, $001b, $001b, $00cf, $0003, $00cd, $00cc, $001b
    dh  $00d4, $00d3, $0003, $00fc, $00d0, $0021, $0000, $0000, $0000, $0000, $0000, $0021, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0022, $0000, $00d0, $0003, $0003, $00d3, $00d4
    dh  $00fd, $0003, $0003, $00d8, $0000, $0000, $0000, $0000, $0022, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0021, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $00cf, $0003, $0003, $0003
    dh  $0003, $0003, $0101, $00db, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $00db, $0003, $0003, $0003
    dh  $0003, $0003, $00f3, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0022, $0000, $0000, $0000, $0000, $00e2, $00ed, $0003, $0003
    dh  $0003, $00ed, $00f4, $0000, $0000, $0000, $0000, $0000, $0000, $0021, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $00f6, $0003, $0003
    dh  $0003, $00f6, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $00f9, $00ed, $0003
    dh  $00f8, $00f9, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $00cf, $0003
    dh  $00f6, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0021, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $00db, $0003
    dh  $00f4, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $00f3
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $00f9
    dh  $0022, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0022, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0021, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dh  $0022, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0022, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000

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
    rh  1       ; tile number
    rh  1       ; y position
    rh  1       ; x position
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
    rh  1       ; tile number
    rb  1       ; palette # 0-3
    rb  1       ; flags
    rb  2       ; reserved
    rw  1       ; user data 1
    rw  1       ; user data 2
    rb  256
}

align 8
bg_buffer:
    rb  SCREEN_WIDTH * SCREEN_HEIGHT
