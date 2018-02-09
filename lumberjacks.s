; -------------------------------------------------------------------------
;
; nybbles arcade kernel
; raspberry pi 3
;
; Lumberjacks Demo Game
;
; -------------------------------------------------------------------------

code64
processor   cpu64_v8
format      binary as 'img'
include     'lib/macros.inc'
include     'lib/r_pi2.inc'

; -------------------------------------------------------------------------
;
; entry point
;
; -------------------------------------------------------------------------
        org     $0008

        if ~ BOOTLOADER {
            b   game_initialize
        } else {
            dw  0
        }

; -------------------------------------------------------------------------
;
; arcade kernel will call this first after install
;
; -------------------------------------------------------------------------
initialize_vector:  
    dw  game_initialize

; -------------------------------------------------------------------------
;
; arcade kernel will call this during each VBLANK
;
; -------------------------------------------------------------------------
game_engine_vector: 
    dw  game_engine_tick

game_initialize:
    ret

game_engine_tick:
    ret
