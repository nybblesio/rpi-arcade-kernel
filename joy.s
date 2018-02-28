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

; SNES Controller Communication Protocol
;
; Every 16.67ms (or about 60Hz), the SNES CPU sends out a 12us wide, positive
; going data latch pulse on pin 3. This instructs the ICs in the controller
; to latch the state of all buttons internally. Six microsenconds after the
; fall of the data latch pulse, the CPU sends out 16 data clock pulses on
; pin 2. These are 50% duty cycle with 12us per full cycle. The controllers
; serially shift the latched button states out pin 4 on every rising edge
; of the clock, and the CPU samples the data on every falling edge.
;
; Each button on the controller is assigned a specific id which corresponds
; to the clock cycle during which that button's state will be reported.
; Note that multiple buttons may be depressed at any given moment. Also note
; that a logic "high" on the serial data line means the button is NOT
; depressed.
;
; At the end of the 16 cycle sequence, the serial data line is driven low
; until the next data latch pulse. The only slight deviation from this
; protocol is apparent in the first clock cycle. Because the clock is
; normally high, the first transition it makes after latch signal is
; a high-to-low transition. Since data for the first button (B in this
; case) will be latched on this transition, it's data must actually be
; driven earlier. The SNES controllers drive data for the first button
; at the falling edge of latch. Data for all other buttons is driven at
; the rising edge of clock. Hopefully the following timing diagram will
; serve to illustrate this. Only 4 of the 16 clock cycles are shown for
; brevity.
;
;                         |<------------16.67ms------------>|
;
;                         12us
;                     -->|   |<--
;
;                         ---                               ---
;                        |   |                             |   |
; Data Latch          ---     -----------------/ /----------    
; --------...
;
;
; Data Clock          ----------   -   -   -  -/ /----------------   -  
; ...
;                               | | | | | | | |                   | | | |
;                                -   -   -   -                     -   -
;                                1   2   3   4                     1   2
;
; Serial Data              ----     ---     ----/ /           ---
;                         |    |   |   |   |                 |
; (Buttons B           ---      ---     ---        ----------
; & Select            norm      B      SEL           norm
; pressed).           low                            low
;                             12us
;                          -->|   |<--
;
;
;
;
; SNES Controller Button-to-Clock Pulse Assignment
;
;        Clock Cycle     Button Reported
;        ===========     ===============
;            1               B
;            2               Y
;            3               Select
;            4               Start
;            5               Up on joypad
;            6               Down on joypad
;            7               Left on joypad
;            8               Right on joypad
;            9               A
;            10              X
;            11              L
;            12              R
;            13              none (always high)
;            14              none (always high)
;            15              none (always high)
;            16              none (always high)
;
;
;
; Additional notes:
;
; Clock cycles 13-16 are essentially unused.

; =========================================================
;
; Constants Section
;
; =========================================================
JOY_R      = 0000000000010000b
JOY_L      = 0000000000100000b
JOY_X      = 0000000001000000b
JOY_A      = 0000000010000000b
JOY_RIGHT  = 0000000100000000b
JOY_LEFT   = 0000001000000000b
JOY_DOWN   = 0000010000000000b
JOY_UP     = 0000100000000000b
JOY_START  = 0001000000000000b
JOY_SELECT = 0010000000000000b
JOY_Y      = 0100000000000000b
JOY_B      = 1000000000000000b

; =========================================================
;
; Data Section
;
; =========================================================
align 4
joy0_state: dw 0
joy1_state: dw 0

; =========================================================
;
; joy_read
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
joy_read:
    sub         sp, sp, #48
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    stp         x3, x4, [sp, #32]
    pload       x0, w0, gpio_base
    mov         w1, GPIO_11
    str         w1, [x0, GPIO_GPSET0]
    delay       12
    str         w1, [x0, GPIO_GPCLR0]
    delay       12
    mov         w1, 0
    mov         w2, 15
.loop:  
    ldr         w3, [x0, GPIO_GPLEV0]
    tst         w3, GPIO_4
    b.ne        .clock
    mov         w3, 1
    lsl         w3, w3, w2
    orr         w1, w1, w3
.clock: 
    mov         w3, GPIO_10
    str         w3, [x0, GPIO_GPSET0]
    delay       12
    str         w3, [x0, GPIO_GPCLR0]
    delay       12
    subs        w2, w2, 1
    b.ne        .loop
    pstore      x0, w1, joy0_state
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    ldp         x3, x4, [sp, #32]
    add         sp, sp, #48
    ret

; =========================================================
;
; joy_init
;
; stack:
;   (none)
;
; registers:
;   x0/w0 scratch: gpio_base
;   w1    scratch: GPIO_GPFSEL1 mask
;   w2    GPIO_FSEL0_OUT + GPIO_FSEL1_OUT new mask
;   
; =========================================================
joy_init:
    sub         sp, sp, #32
    stp         x0, x30, [sp]
    stp         x1, x2, [sp, #16]
    pload       x0, w0, gpio_base
    ldr         w1, [x0, GPIO_GPFSEL1]
    mov         w2, GPIO_FSEL0_OUT + GPIO_FSEL1_OUT
    orr         w1, w1, w2
    str         w1, [x0, GPIO_GPFSEL1]
    mov         w1, GPIO_11
    str         w1, [x0, GPIO_GPCLR0]
    mov         w1, GPIO_10
    str         w1, [x0, GPIO_GPCLR0]
    ldp         x0, x30, [sp]
    ldp         x1, x2, [sp, #16]
    add         sp, sp, #32
    ret
