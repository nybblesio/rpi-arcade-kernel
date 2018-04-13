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
RAND_MAX = 32767

BUTTON_TOGGLE_READY = 0
BUTTON_TOGGLE_START = 1
BUTTON_TOGGLE_STOP  = 2
BUTTON_TOGGLE_RESET = 3

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

ACTOR_Y_POS         = 0
ACTOR_X_POS         = 2
ACTOR_SPR_START     = 4
ACTOR_SPR_COUNT     = 5
ACTOR_FLAGS         = 6
ACTOR_FRAME_IDX     = 7
ACTOR_ANIM          = 8
ACTOR_ANIM_FUNC     = 12
ACTOR_ANIM_TIMER    = 16
ACTOR_UPD_FUNC      = 20
ACTOR_UPD_TIMER     = 24
ACTOR_UPD_MS        = 28
ACTOR_USER1         = 32
ACTOR_USER2         = 33
ACTOR_USER3         = 34
ACTOR_USER4         = 35
ACTOR_SZ            = 36

F_ACTOR_NONE      = 00000000b
F_ACTOR_VISIBLE   = 00000001b
F_ACTOR_COLLIDED  = 00000010b
F_ACTOR_END       = 10000000b

PLAYER_LIVES = 0
PLAYER_TREES = 2
PLAYER_SCORE = 4
PLAYER_SZ    = 8

ANIM_DEF_NUM_FRAMES = 0
ANIM_DEF_NUM_MS     = 2
ANIM_DEF_SZ         = 4

FRAME_START_NUMBER     = 0
FRAME_START_TILE_COUNT = 1
FRAME_START_PAD1       = 2
FRAME_START_PAD2       = 3
FRAME_START_SZ         = 4

FRAME_TILE_INDEX       = 0
FRAME_TILE_X_OFFSET    = 4
FRAME_TILE_Y_OFFSET    = 6
FRAME_TILE_PALETTE     = 8
FRAME_TILE_FLAGS       = 9
FRAME_TILE_SZ          = 12

F_PLAYER_NONE   = 00000000b
F_PLAYER_RIGHT  = 00000001b
F_PLAYER_LEFT   = 00000010b
F_PLAYER_CHOP   = 00000100b
F_PLAYER_FALL   = 00001000b
F_PLAYER_CRASH  = 00010000b
F_PLAYER_PUSH   = 00100000b

F_TREE_NONE     = 00000000b
F_TREE_HAS_BIRD = 00000001b
F_TREE_FALLEN   = 00000010b
F_TREE_KILL_FALL= 00000100b
F_TREE_SAFE_FALL= 00001000b

F_BIRD_NONE     = 00000000b
F_BIRD_LEFT     = 00000001b
F_BIRD_RIGHT    = 00000010b
F_BIRD_UP       = 00000100b
F_BIRD_DOWN     = 00001000b

; =========================================================
;
; Game Entry Point
;
; =========================================================
include     'macros.s'
include     'kernel_abi_constants.s'
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
    db  flags       
    db  0           ; frame index
    dw  0           ; animation ptr
    dw  0           ; animation reset func ptr
    dw  0           ; animation timer
    dw  0           ; update func ptr
    dw  0           ; update timer
    dw  0           ; update timer duration
    db  0           ; user data 
    db  0           ; "
    db  0           ; "
    db  0           ; "
}

macro animdef name*, num_frames*, num_ms* {
align 4
common
label name
    dh  num_frames
    dh  num_ms
}

macro framestart num, num_tiles {
    db  num
    db  num_tiles
    db  0
    db  0
}

macro frameend {
}

macro frametile tile, xoff, yoff, pal, flags {
    dw  tile
    dh  xoff
    dh  yoff
    db  pal
    db  flags
    db  2 dup(0)    ; pad
}

macro actor name {
    adr             x25, name
}

macro actorr reg {
    mov             w25, reg
}

macro actor_setf flag* {
    mov             w26, flag
    actor_stuser1   w26
}

macro actor_orrf flag* {
    actor_lduser1   w26
    mov             w27, flag
    orr             w26, w26, w27
    actor_stuser1   w26
}

macro actor_clrf flag* {
    actor_lduser1   w26
    mov             w27, flag
    bic             w26, w26, w27
    actor_stuser1   w26
}

macro actor_ldf reg* {
    actor_lduser1   reg  
}

macro actor_upd func* {
    adr             x26, func
    str             w26, [x25, ACTOR_UPD_FUNC]
}

macro actor_pos ypos, xpos {
    mov             w26, ypos
    mov             w27, xpos
    strh            w26, [x25, ACTOR_Y_POS]
    strh            w27, [x25, ACTOR_X_POS]
}

macro actor_animt anim_reg, actor_reg {
    mov             w28, 1600
    ldrh            w27, [anim_reg, ANIM_DEF_NUM_MS]
    mul             w27, w27, w28
    pload           x26, w26, arm_timer_counter
    ldr             w26, [x26]
    add             w26, w26, w27
    str             w26, [actor_reg, ACTOR_ANIM_TIMER]
}

macro actor_updt duration* {
    mov             w26, duration
    str             w26, [x25, ACTOR_UPD_MS]
    mov             w27, 1600
    mul             w27, w26, w27
    pload           x26, w26, arm_timer_counter
    ldr             w26, [x26]
    add             w26, w26, w27
    str             w26, [x25, ACTOR_UPD_TIMER]
}

macro actor_flags flags {
    mov             w26, flags
    strb            w26, [x25, ACTOR_FLAGS]
}

macro actor_lduser1 reg {
    ldrb            reg, [x25, ACTOR_USER1]
}

macro actor_stuser1 reg {
    strb            reg, [x25, ACTOR_USER1]
}

macro actor_addx pixels, upper_bound {
    local           .clamp
    ldrh            w26, [x25, ACTOR_X_POS]
    add             w26, w26, pixels
    cmp             w26, upper_bound
    b.hs            .clamp
    strh            w26, [x25, ACTOR_X_POS]
.clamp:    
}

macro actor_subx pixels, lower_bound {
    local           .clamp, .ok
    ldrh            w26, [x25, ACTOR_X_POS]
    cbz             w26, .clamp
    mov             w27, pixels
    cmp             w26, w27
    b.hi            .ok
    mov             w27, w26
.ok:
    sub             w26, w26, w27
    cmp             w26, lower_bound
    b.ls            .clamp
    strh            w26, [x25, ACTOR_X_POS]
.clamp:    
}

macro actor_addy pixels, upper_bound {
    local           .clamp
    ldrh            w26, [x25, ACTOR_Y_POS]
    add             w26, w26, pixels
    cmp             w26, upper_bound
    b.hs            .clamp
    strh            w26, [x25, ACTOR_Y_POS]
.clamp:    
}

macro actor_suby pixels, lower_bound {
    local           .clamp, .ok
    ldrh            w26, [x25, ACTOR_Y_POS]
    cbz             w26, .clamp
    mov             w27, pixels
    cmp             w26, w27
    b.hi            .ok
    mov             w27, w26
.ok:    
    sub             w26, w26, w27
    cmp             w26, lower_bound
    b.ls            .clamp
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
include     'dma.s'
include     'string.s'
include     'kernel_abi_macros.s'

; =========================================================
;
; rand
;
; stack:
;   lower limit
;   upper limit
;
; registers:
;   (none)
;
; =========================================================
; return min + rand() / (RAND_MAX / (max - min + 1) + 1);
rand:
    sub         sp, sp, #64
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    stp         x5, x6, [sp, #48]

    pload       x0, w0, prng_seed
    pload       x1, w1, prng_constant1
    pload       x2, w2, prng_constant2
    madd        w0, w0, w1, w2
    pstore      x1, w0, prng_seed
    ;watch_set   0, 470, 16, w0, "prng_seed (w0) = "
    and         w0, w0, RAND_MAX
    ;watch_set   1, 460, 16, w0, "prng_seed % 32767 (w0) = "

    ldp         x1, x2, [sp, #64]
    sub         w4, w2, w1
    add         w4, w4, 1
    mov         w5, RAND_MAX
    udiv        w5, w5, w4
    add         w5, w5, 1
    ;watch_set   2, 450, 16, w5, "(32767 / (max - min + 1) + 1) (w5) = "

    udiv        w6, w0, w5
    add         w6, w6, w1
    ;watch_set   3, 440, 16, w6, "(prng_clamped_seed / w5) + min (w6) = "
    mov         w26, w6

    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    ldp         x5, x6, [sp, #48]
    add         sp, sp, #80
    ret

macro rand lower_limit*, upper_limit* {
    sub         sp, sp, #16
    mov         w26, lower_limit
    mov         w27, upper_limit
    stp         x26, x27, [sp]
    bl          rand
}

; =========================================================
;
; actor_anim
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
actor_anim:
    sub         sp, sp, #48
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    ldp         x0, x1, [sp, #48]
    ldp         x2, x3, [sp, #64]
    ldr         w4, [x0, ACTOR_ANIM_FUNC]
    cbnz        w4, .exit
    ldr         w4, [x0, ACTOR_ANIM]
    cmp         w4, w1
    b.eq        .exit
    str         w1, [x0, ACTOR_ANIM]
    str         w2, [x0, ACTOR_ANIM_FUNC]
    actor_animt x1, x0
    mov         w4, 0
    strb        w4, [x0, ACTOR_FRAME_IDX]
.exit:
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    add         sp, sp, #80
    ret

macro actor_anim anim*, reset_func {
    sub         sp, sp, #32
    adr         x26, anim
    stp         x25, x26, [sp]
    if reset_func eq
        mov     x26, 0
    else
        adr     x26, reset_func
    end if        
    mov         x27, 0
    stp         x26, x27, [sp, #16]
    bl          actor_anim
}
    
; =========================================================
;
; actor_reset
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
actor_reset:
    sub         sp, sp, #32
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    adr         x0, actors
.loop:
    ldrb        w1, [x0, ACTOR_FLAGS]
    tst         w1, F_ACTOR_END
    b.ne        .done
    mov         w1, 0
    strh        w1, [x0, ACTOR_Y_POS]
    strh        w1, [x0, ACTOR_X_POS]
    str         w1, [x0, ACTOR_ANIM]
    str         w1, [x0, ACTOR_ANIM_TIMER]
    str         w1, [x0, ACTOR_ANIM_FUNC]
    strb        w1, [x0, ACTOR_FRAME_IDX]
    mov         w1, F_ACTOR_NONE
    strb        w1, [x0, ACTOR_FLAGS]
    add         x0, x0, ACTOR_SZ
    b           .loop
.done:    
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    add         sp, sp, #32
    ret

macro actor_reset {
    bl          actor_reset
}

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
    pload       x9, w9, arm_timer_counter
.loop:
    ldrb        w1, [x0, ACTOR_FLAGS]
    tst         w1, F_ACTOR_END
    b.ne        .done
    ldr         w2, [x0, ACTOR_UPD_TIMER]
    cbz         w2, .always_upd
    ldr         w3, [x9]
    cmp         w2, w3
    b.lo        .no_upd
    ldr         w4, [x0, ACTOR_UPD_MS]
    mov         w5, 1600
    madd        w3, w4, w5, w3
    str         w3, [x0, ACTOR_UPD_TIMER]
.always_upd:    
    ldr         w2, [x0, ACTOR_UPD_FUNC]
    cbz         w2, .no_upd
    blr         x2
.no_upd:    
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
    ldrh        w3, [x2, ANIM_DEF_NUM_FRAMES]
    add         w2, w2, ANIM_DEF_SZ
    ldrb        w4, [x0, ACTOR_FRAME_IDX]
.frame:
    ldrb        w5, [x2, FRAME_START_NUMBER]
    cmp         w4, w5
    b.eq        .layout_frame
    ldrb        w6, [x2, FRAME_START_TILE_COUNT]
    mov         w7, FRAME_TILE_SZ
    mul         w6, w6, w7
    add         w2, w2, FRAME_START_SZ
    add         w2, w2, w6
    subs        w3, w3, 1
    b.ne        .frame
    b           .next
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
    add         w2, w2, FRAME_TILE_SZ
    subs        w3, w3, 1
    b.ne        .sprite

    ldr         w4, [x9]
    ldr         w2, [x0, ACTOR_ANIM_TIMER]
    cmp         w4, w2
    b.lo        .next
    ldr         w2, [x0, ACTOR_ANIM]
    ldrh        w4, [x2, ANIM_DEF_NUM_FRAMES]
    ldrb        w3, [x0, ACTOR_FRAME_IDX]
    sub         w4, w4, 1
    cmp         w3, w4
    b.eq        .reset_frame
    add         w3, w3, 1
    b           .save_frame
.reset_frame:
    mov         w3, 0
    ldr         w4, [x0, ACTOR_ANIM_FUNC]
    cbz         w4, .save_frame
    sub         sp, sp, #16
    stp         x0, x2, [sp]
    blr         x4
    add         sp, sp, #16
    str         w3, [x0, ACTOR_ANIM_FUNC]
.save_frame:
    strb        w3, [x0, ACTOR_FRAME_IDX]
    actor_animt x2, x0
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
    mov         w5, TILE_BYTES
.pixel:
    ldrb        w7, [x4], 1
    add         w7, w7, w3
    strb        w7, [x0], 1
    subs        w5, w5, 1
    b.ne        .pixel
    tst         w1, F_BG_HFLIP
    b.eq        .vflip
    sub         w0, w0, TILE_BYTES
    mov         w4, w0
    add         w4, w4, TILE_WIDTH - 1
    mov         w5, TILE_HEIGHT
.hline:    
    mov         w7, TILE_WIDTH / 2
.hswap:
    ldrb        w3, [x0]
    ldrb        w8, [x4]
    strb        w8, [x0]
    strb        w3, [x4]
    add         w0, w0, 1
    sub         w4, w4, 1
    subs        w7, w7, 1
    b.ne        .hswap
    add         w0, w0, TILE_WIDTH / 2
    mov         w4, w0
    add         w4, w4, TILE_WIDTH - 1
    subs        w5, w5, 1
    b.ne        .hline
.vflip:
    tst         w1, F_BG_VFLIP
    b.eq        .exit
    ; TODO
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
    mov         w2, SPRITE_BYTES
.pixel:
    ldrb        w6, [x4], 1
    add         w6, w6, w3
    strb        w6, [x0], 1
    subs        w2, w2, 1
    b.ne        .pixel
    tst         w1, F_SPR_HFLIP
    b.eq        .vflip
    sub         w0, w0, SPRITE_BYTES
    mov         w4, w0
    add         w4, w4, SPRITE_WIDTH - 1
    mov         w5, SPRITE_HEIGHT
.hline:
    mov         w7, SPRITE_WIDTH / 2
.hswap:
    ldrb        w3, [x0]
    ldrb        w8, [x4]
    strb        w8, [x0]
    strb        w3, [x4]
    add         w0, w0, 1
    sub         w4, w4, 1
    subs        w7, w7, 1
    b.ne        .hswap
    add         w0, w0, SPRITE_WIDTH / 2
    mov         w4, w0
    add         w4, w4, SPRITE_WIDTH - 1
    subs        w5, w5, 1
    b.ne        .hline
.vflip:
    tst         w1, F_SPR_VFLIP
    b.eq        .exit
    ; TODO
.exit:
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
    actor_reset
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
    cbz         w26, .loop
    state_go    GAME_STATE_ID
.loop:
    actor_update
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
; bird_hint_cb
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
bird_hint_cb:
    sub             sp, sp, #32
    stp             x0, x30, [sp]
    stp             x1, x2, [sp, #16]
    ldp             x0, x1, [sp, #32]
    adr             x2, bird_right
    str             w2, [x0, ACTOR_ANIM]
    mov             w2, F_BIRD_RIGHT
    strb            w2, [x0, ACTOR_USER1]
    adr             x2, bird_update_cb
    str             w2, [x0, ACTOR_UPD_FUNC]
    ldrh            w2, [x0, ACTOR_Y_POS]
    add             w2, w2, 64
    strh            w2, [x0, ACTOR_Y_POS]
    ldrh            w2, [x0, ACTOR_X_POS]
    add             w2, w2, 32
    strh            w2, [x0, ACTOR_X_POS]
    ldp             x0, x30, [sp]
    ldp             x1, x2, [sp, #16]
    add             sp, sp, #32
    ret

; =========================================================
;
; tree_grow_cb
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
tree_grow_cb:
    sub             sp, sp, #32
    stp             x0, x30, [sp]
    stp             x1, x2, [sp, #16]
    ldp             x0, x1, [sp, #32]
    adr             x1, tree_stand
    str             w1, [x0, ACTOR_ANIM]
    rand            10, 4096
    mov             w1, w26
    and             w1,   w1, 00000111b
    rand            10, 4096
    and             w26, w26, 00000111b
    cmp             w1, w26
    b.ne            .done
.bird:
    ldrb            w1, [x0, ACTOR_USER1]
    orr             w1, w1, F_TREE_HAS_BIRD
    strb            w1, [x0, ACTOR_USER1]
    ldrh            w1, [x0, ACTOR_Y_POS]
    ldrh            w2, [x0, ACTOR_X_POS]
    actor           bird1
    sub             w1, w1, 64
    actor_pos       w1, w2
    actor_anim      bird_hint, bird_hint_cb
    actor_flags     F_ACTOR_VISIBLE
.done:    
    ldp             x0, x30, [sp]
    ldp             x1, x2, [sp, #16]
    add             sp, sp, #32
    ret

; =========================================================
;
; tree_spawn
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
tree_spawn:
    sub             sp, sp, #32
    stp             x0, x30, [sp]
    stp             x1, x2, [sp, #16]
    adr             x2, tree9
    pload           x1, w1, current_tree
    cmp             w1, w2
    b.eq            .done
    actorr          w1
    add             w1, w1, ACTOR_SZ
    pstore          x2, w1, current_tree
    rand            220, 400
    mov             w1, w26
    rand            64, 448
    mov             w2, w26
    actor_pos       w1, w2
    actor_anim      tree_grow, tree_grow_cb
    actor_flags     F_ACTOR_VISIBLE
.done:    
    ldp             x0, x30, [sp]
    ldp             x1, x2, [sp, #16]
    add             sp, sp, #32
    ret

macro tree_spawn {
    bl              tree_spawn
}

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
    sub             sp, sp, #32
    stp             x0, x30, [sp]
    stp             x1, x2, [sp, #16]
    bg_set          playfield_bg, playfield_bg_attr

    actor           mustache_man
    actor_pos       256, 128
    actor_upd       p1_update_cb
    actor_anim      mustache_man_stand_right
    actor_flags     F_ACTOR_VISIBLE

    actor           whistle
    actor_pos       68, 200
    actor_anim      whistle_idle
    actor_flags     F_ACTOR_VISIBLE

    actor           foreman
    actor_pos       110, 240
    actor_anim      foreman_watching
    actor_flags     F_ACTOR_VISIBLE

    adr             x1, tree0
    pstore          x2, w1, current_tree

    tree_spawn
    tree_spawn

    ldp             x0, x30, [sp]
    ldp             x1, x2, [sp, #16]
    add             sp, sp, #32
    ret

; =========================================================
;
; p1_chop_cb
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
p1_chop_cb:
    sub             sp, sp, #32
    stp             x0, x30, [sp]
    stp             x1, x2, [sp, #16]
    ldp             x0, x1, [sp, #32]
    mov             x25, x0
    actor_ldf       w1
    tst             w1, F_PLAYER_RIGHT
    b.ne            .right
    mov             w1, BUTTON_TOGGLE_RESET
    pstoreb         x2, w1, button_y_toggle
    adr             x1, mustache_man_stand_left
    b               .flags
.right:
    mov             w1, BUTTON_TOGGLE_RESET
    pstoreb         x2, w1, button_a_toggle
    adr             x1, mustache_man_stand_right
.flags:
    str             w1, [x0, ACTOR_ANIM]
    actor_clrf      F_PLAYER_CHOP
    ldp             x0, x30, [sp]
    ldp             x1, x2, [sp, #16]
    add             sp, sp, #32
    ret

; =========================================================
;
; button_toggle
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
button_toggle:
    sub             sp, sp, #32
    stp             x0, x30, [sp]
    stp             x1, x2, [sp, #16]
    ldp             x0, x1, [sp, #32]
    joy_check       w0
    ldrb            w2, [x1]
    cbz             w2, .is_down
    cmp             w2, BUTTON_TOGGLE_RESET
    b.ne            .is_up
    cbnz            w26, .done
    mov             w2, BUTTON_TOGGLE_READY
    strb            w2, [x1]
    b               .done
.is_up:
    cbnz            w26, .done
    mov             w2, BUTTON_TOGGLE_STOP
    strb            w2, [x1]
    b               .done
.is_down:
    cbz             w26, .done
    mov             w2, BUTTON_TOGGLE_START
    strb            w2, [x1]
.done:
    ldp             x0, x30, [sp]
    ldp             x1, x2, [sp, #16]
    add             sp, sp, #48
    ret

macro button_toggle joy*, var* {
    sub             sp, sp, #16
    mov             w26, joy
    adr             x27, var
    stp             x26, x27, [sp]
    bl              button_toggle
}

; =========================================================
;
; bird_update_cb
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
bird_update_cb:
    sub             sp, sp, #32
    stp             x0, x30, [sp]
    stp             x1, x2, [sp, #16]
    rand            10, 4096
    mov             w1, w26
    and             w1, w1, 00000111b
    and             w26, w26, 00111000b
    cmp             w1, w26
    b.ne            .done
    rand            10, 4096
    tbz             w26, 1, .right
    tbz             w26, 2, .left
    tbz             w26, 3, .up
    tbz             w26, 4, .down
    b               .done    
.right:
    actor           bird1
    actor_setf      F_BIRD_RIGHT
    actor_anim      bird_right
    b               .done
.left:
    actor           bird1
    actor_setf      F_BIRD_LEFT
    actor_anim      bird_left
    b               .done
.up:
    actor           bird1
    actor_setf      F_BIRD_UP
    actor_anim      bird_up
    b               .done
.down:
    actor           bird1
    actor_setf      F_BIRD_DOWN
    actor_anim      bird_down
.done:    
    actor           bird1
    actor_ldf       w1
    tbnz            w1, 1, .move_right
    tbnz            w1, 0, .move_left
    tbnz            w1, 2, .move_up
    tbnz            w1, 3, .move_down
    b               .exit
.move_right:
    actor           bird1
    actor_addx      3, SCREEN_WIDTH - SPRITE_WIDTH
    b               .exit
.move_left:
    actor           bird1
    actor_subx      3, SPRITE_WIDTH
    b               .exit
.move_up:
    actor           bird1
    actor_suby      3, 200
    b               .exit
.move_down:
    actor           bird1
    actor_addy      3, SCREEN_HEIGHT - SPRITE_HEIGHT
.exit:    
    ldp             x0, x30, [sp]
    ldp             x1, x2, [sp, #16]
    add             sp, sp, #32
    ret

; =========================================================
;
; p1_update_cb
;
; stack:
;   (none)
;   
; registers:
;   (none)
;
; =========================================================
p1_update_cb:
    sub             sp, sp, #32
    stp             x0, x30, [sp]
    stp             x1, x2, [sp, #16]
    joy_check       JOY0_LEFT
    cbz             w26, .right    
    actor           mustache_man
    actor_subx      4, 2  
    actor_anim      mustache_man_walk_left
    actor_setf      F_PLAYER_LEFT
    b               .done
.right:    
    joy_check       JOY0_RIGHT
    cbz             w26, .up
    actor           mustache_man
    actor_addx      4, SCREEN_WIDTH - SPRITE_WIDTH
    actor_anim      mustache_man_walk_right
    actor_setf      F_PLAYER_RIGHT
    b               .done
.up:
    joy_check       JOY0_UP
    cbz             w26, .down
    actor           mustache_man
    actor_suby      4, 128
    actor_anim      mustache_man_walk_up
    b               .done
.down:
    joy_check       JOY0_DOWN
    cbz             w26, .check_chop
    actor           mustache_man
    actor_addy      4, 400
    actor_anim      mustache_man_walk_down
    b               .done
.check_chop:
    actor_ldf       w1
    tst             w1, F_PLAYER_CHOP
    b.ne            .stand
.chop_right:
    button_toggle   JOY0_A, button_a_toggle
    ploadb          x1, w1, button_a_toggle
    cmp             w1, BUTTON_TOGGLE_STOP
    b.ne            .chop_left
    actor           mustache_man
    actor_anim      mustache_man_chop_right, p1_chop_cb
    actor_setf      F_PLAYER_RIGHT or F_PLAYER_CHOP
    b               .done
.chop_left:
    button_toggle   JOY0_Y, button_y_toggle
    ploadb          x1, w1, button_y_toggle
    cmp             w1, BUTTON_TOGGLE_STOP
    b.ne            .stand
    actor           mustache_man
    actor_anim      mustache_man_chop_left, p1_chop_cb
    actor_setf      F_PLAYER_LEFT or F_PLAYER_CHOP
    b               .done
.stand:
    actor           mustache_man
    actor_ldf       w1
    tst             w1, F_PLAYER_RIGHT
    b.ne            .stand_right
    actor_anim      mustache_man_stand_left
    b               .done
.stand_right:
    actor_anim      mustache_man_stand_right
.done:
    ldp             x0, x30, [sp]
    ldp             x1, x2, [sp, #16]
    add             sp, sp, #32
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
    sub             sp, sp, #32
    stp             x0, x30, [sp]
    stp             x1, x2, [sp, #16]
    joy_check       JOY0_SELECT
    cbz             w26, .update
    state_go        ATTRACT_STATE_ID
    b               .done
.update:    
    actor_update
.done:    
    ldp             x0, x30, [sp]
    ldp             x1, x2, [sp, #16]
    add             sp, sp, #32
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
    watch_clr   0
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
    watch_clr   0
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
    actor_reset
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
    sub         sp, sp, #48
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]

    on_update
    bg_update

    adr         x2, bg_buffer_dma
    adr         x1, bg_buffer
    str         w1, [x2, DMA_CON_SRC]
    str         w0, [x2, DMA_CON_DEST]
    pload       x1, w1, dma0_base
    dma_start   bg_buffer_dma, w1
    ;dma_wait    w1

    fg_update   w0
    
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    add         sp, sp, #48
    ret

; =========================================================
;
; Variables Data Section
;
; =========================================================

button_a_toggle: db 0
button_y_toggle: db 0

previous_state: db  NONE_STATE_ID
current_state:  db  NONE_STATE_ID
next_state:     db  NONE_STATE_ID

align 4

prng_constant1:
    dw  8253729

prng_constant2:
    dw  2396403

prng_seed:
    dw  5323

align 4
state_callbacks:
    statedef none_state,      0,                  0,                    0       
    statedef attract_state,   attract_enter_cb,   attract_update_cb,    attract_leave_cb
    statedef game_state,      game_enter_cb,      game_update_cb,       game_leave_cb
    statedef game_over_state, game_over_enter_cb, game_over_update_cb,  game_over_leave_cb

align 4
actors:
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
    actordef bird1,        70, 1, 0, 0, F_ACTOR_NONE
    actordef end_of_list,  0,  0, 0, 0, F_ACTOR_END

align 4
current_tree:   dw  tree0

animdef mustache_man_stand_left, 1, 0
framestart 0, 2
    frametile 1, 0,  0, PAL1, F_SPR_HFLIP
    frametile 2, 0, 32, PAL1, F_SPR_HFLIP
frameend

animdef mustache_man_stand_right, 1, 0
framestart 0, 2
    frametile 1, 0,  0, PAL1, F_SPR_NONE
    frametile 2, 0, 32, PAL1, F_SPR_NONE
frameend

animdef mustache_man_walk_right, 4, 100
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

animdef mustache_man_walk_left, 4, 100
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

animdef mustache_man_walk_up, 4, 100
framestart 0, 2
    frametile 31, 0,  0, PAL1, F_SPR_NONE
    frametile 32, 0, 32, PAL1, F_SPR_NONE
frameend
framestart 1, 2
    frametile 33, 0, 0, PAL1, F_SPR_NONE
    frametile 34, 0, 32, PAL1, F_SPR_NONE
frameend
framestart 2, 2
    frametile 35, 0, 0, PAL1, F_SPR_NONE
    frametile 36, 0, 32, PAL1, F_SPR_NONE
frameend
framestart 3, 2
    frametile 37, 0, 0, PAL1, F_SPR_NONE
    frametile 38, 0, 32, PAL1, F_SPR_NONE
frameend

animdef mustache_man_walk_down, 4, 100
framestart 0, 2
    frametile 19, 0,  0, PAL1, F_SPR_NONE
    frametile 20, 0, 32, PAL1, F_SPR_NONE
frameend
framestart 1, 2
    frametile 21, 0, 0, PAL1, F_SPR_NONE
    frametile 22, 0, 32, PAL1, F_SPR_NONE
frameend
framestart 2, 2
    frametile 23, 0, 0, PAL1, F_SPR_NONE
    frametile 24, 0, 32, PAL1, F_SPR_NONE
frameend
framestart 3, 2
    frametile 25, 0, 0, PAL1, F_SPR_NONE
    frametile 26, 0, 32, PAL1, F_SPR_NONE
frameend

animdef mustache_man_push_right, 4, 40

animdef mustache_man_push_left, 4, 40

animdef mustache_man_chop_right, 2, 100
framestart 0, 3
    frametile 46,   0,  0, PAL1, F_SPR_NONE
    frametile 47,   0, 32, PAL1, F_SPR_NONE
    frametile 48, -32, 32, PAL1, F_SPR_NONE
frameend
framestart 1, 3
    frametile 49,  0,  0, PAL1, F_SPR_NONE
    frametile 50,  0, 32, PAL1, F_SPR_NONE
    frametile 51, 32, 32, PAL1, F_SPR_NONE
frameend

animdef mustache_man_chop_left, 2, 100
framestart 0, 3
    frametile 46,  0,  0, PAL1, F_SPR_HFLIP
    frametile 47,  0, 32, PAL1, F_SPR_HFLIP
    frametile 48, 32, 32, PAL1, F_SPR_HFLIP
frameend
framestart 1, 3
    frametile 49,   0,  0, PAL1, F_SPR_HFLIP
    frametile 50,   0, 32, PAL1, F_SPR_HFLIP
    frametile 51, -32, 32, PAL1, F_SPR_HFLIP
frameend

animdef mustache_man_fall_up, 4, 40

animdef mustache_man_fall_down, 4, 40

animdef mustache_man_collide, 4, 40

animdef mustache_man_swarm, 4, 40

animdef mustache_man_shaken, 4, 40

animdef mustache_man_wave, 4, 40

animdef mustache_man_in_a_tree, 4, 40

animdef whistle_idle, 1, 0
framestart 0, 2
    frametile 120, 0,  0, PAL1, F_SPR_NONE
    frametile 121, 0, 32, PAL1, F_SPR_NONE
frameend

animdef whistle_blowing, 2, 60
framestart 0, 2
    frametile 122, 0,  0, PAL1, F_SPR_NONE
    frametile 124, 0, 32, PAL1, F_SPR_NONE
frameend
framestart 1, 2
    frametile 123, 0,  0, PAL1, F_SPR_NONE
    frametile 125, 0, 32, PAL1, F_SPR_NONE
frameend

animdef foreman_watching, 2, 325
framestart 0, 2
    frametile 130, 0,  0, PAL1, F_SPR_NONE
    frametile 132, 0, 32, PAL1, F_SPR_NONE
frameend
framestart 1, 2
    frametile 131, 0,  0, PAL1, F_SPR_NONE
    frametile 133, 0, 32, PAL1, F_SPR_NONE
frameend

animdef tree_stand, 1, 0
framestart 0, 3
    frametile 3,  0, -64, PAL1, F_SPR_NONE
    frametile 4,  0, -32, PAL1, F_SPR_NONE
    frametile 5,  0,   0, PAL1, F_SPR_NONE
frameend

animdef tree_grow, 8, 60
framestart 0, 1
    frametile 169, 0, 0, PAL1, F_SPR_NONE
frameend
framestart 1, 1
    frametile 170, 0, 0, PAL1, F_SPR_NONE
frameend
framestart 2, 2
    frametile 171,  0, -32, PAL1, F_SPR_NONE
    frametile 172,  0,   0, PAL1, F_SPR_NONE
frameend
framestart 3, 3
    frametile 171,  0, -64, PAL1, F_SPR_NONE
    frametile 173,  0, -32, PAL1, F_SPR_NONE
    frametile 172,  0,   0, PAL1, F_SPR_NONE
frameend
framestart 4, 3
    frametile 171,  0, -64, PAL1, F_SPR_NONE
    frametile 173,  0, -32, PAL1, F_SPR_NONE
    frametile 174,  0,   0, PAL1, F_SPR_NONE
frameend
framestart 5, 3
    frametile 171,  0, -64, PAL1, F_SPR_NONE
    frametile 173,  0, -32, PAL1, F_SPR_NONE
    frametile 175,  0,   0, PAL1, F_SPR_NONE
frameend
framestart 6, 3
    frametile 176,  0, -64, PAL1, F_SPR_NONE
    frametile 177,  0, -32, PAL1, F_SPR_NONE
    frametile 178,  0,   0, PAL1, F_SPR_NONE
frameend
framestart 7, 3
    frametile 3,  0, -64, PAL1, F_SPR_NONE
    frametile 4,  0, -32, PAL1, F_SPR_NONE
    frametile 5,  0,   0, PAL1, F_SPR_NONE
frameend

animdef bird_hint, 7, 250
framestart 0, 1
    frametile 179, 0, 0, PAL1, F_SPR_NONE
frameend
framestart 1, 1
    frametile 180, 0, 0, PAL1, F_SPR_NONE
frameend
framestart 2, 1
    frametile 181, 0, 0, PAL1, F_SPR_NONE
frameend
framestart 3, 1
    frametile 181, 0, 0, PAL1, F_SPR_HFLIP
frameend
framestart 4, 1
    frametile 181, 0, 0, PAL1, F_SPR_NONE
frameend
framestart 5, 1
    frametile 181, 0, 0, PAL1, F_SPR_HFLIP
frameend
framestart 6, 1
    frametile 181, 0, 0, PAL1, F_SPR_NONE
frameend

animdef bird_right, 2, 100
framestart 0, 1
    frametile 182, 0, 0, PAL1, F_SPR_NONE
frameend
framestart 1, 1
    frametile 183, 0, 0, PAL1, F_SPR_NONE
frameend

animdef bird_left, 2, 100
framestart 0, 1
    frametile 182, 0, 0, PAL1, F_SPR_HFLIP
frameend
framestart 1, 1
    frametile 183, 0, 0, PAL1, F_SPR_HFLIP
frameend

animdef bird_down, 2, 100
framestart 0, 1
    frametile 184, 0, 0, PAL1, F_SPR_NONE
frameend
framestart 1, 1
    frametile 185, 0, 0, PAL1, F_SPR_NONE
frameend

animdef bird_up, 2, 100
framestart 0, 1
    frametile 186, 0, 0, PAL1, F_SPR_NONE
frameend
framestart 1, 1
    frametile 187, 0, 0, PAL1, F_SPR_NONE
frameend

playerdef player1
playerdef player2

linear_dmadef bg_buffer_dma, \
        DMA_DEST_WIDTH + DMA_DEST_INC + DMA_SRC_WIDTH + DMA_SRC_INC, \
        SCREEN_WIDTH * SCREEN_HEIGHT

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
