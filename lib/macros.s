; -------------------------------------------------------------------------
;
; nybbles arcade kernel
; raspberry pi 3
;
; -------------------------------------------------------------------------

macro b2p reg {
         and     w0, w0, $3fffffff
}

macro delay cycles {
        local   .loop
        mov     w12, cycles
.loop:  subs    w12, w12, 1
        b.ne    .loop        
}

macro clear color {
        mov     w2, color
        bl      clear_screen        
}

macro text ypos, xpos, str, len, color {
        sub     sp, sp, #48
        mov     w1, ypos
        mov     w2, xpos
        stp     x1, x2, [sp]
        adr     x1, str
        mov     x2, len
        stp     x1, x2, [sp, #16]
        mov     x1, color
        mov     x2, 0
        stp     x1, x2, [sp, #32]        
        bl      draw_string
        add     sp, sp, #48        
}

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

macro lbb {
        ldr     w2, page
        ldr     w3, page_bytes
        mul     x2, x2, x3
        adr     x1, frame_buffer.data1
        ldr     w0, [x1]
        add     w0, w0, w2
}

struc string text* {
        .       db  text
        .size   =   $ - .
}

struc font width*, height*, ptr* {
        .width:         dw      width
        .height:        dw      height
        .w_stride:      dw      SCREEN_WIDTH - width
        .h_stride:      dw      (SCREEN_WIDTH * height) - width
        .ptr:           dw      ptr
}

struc bus_cmd tag*, size, data1, data2 {
        .tag dw  tag

        if ~size eq
                .size dw size
                .indicator  dw  0
        end if

        if ~data1 eq
                .data1 dw data1
        end if

        if ~data2 eq
                .data2 dw data2
        end if
}

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
