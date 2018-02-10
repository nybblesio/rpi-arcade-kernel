; -------------------------------------------------------------------------
;
; nybbles arcade kernel
; raspberry pi 3
;
; -------------------------------------------------------------------------

code64
processor   cpu64_v8
format      binary as 'img'
include     'lib/macros.s'
include     'lib/rpi2.s'

; -------------------------------------------------------------------------
;
; entry point
;
; -------------------------------------------------------------------------

        org     $0000
        b       multi_core_start

stack_frame:
        db      $8000 - stack_frame dup (0)

; -------------------------------------------------------------------------
;
; constants
;
; -------------------------------------------------------------------------
SCREEN_WIDTH            = 512
SCREEN_HEIGHT           = 480
SCREEN_BITS_PER_PIXEL   = 8

TILE_WIDTH              = 16
TILE_HEIGHT             = 16
TILE_BYTES              = TILE_WIDTH * TILE_HEIGHT

SPRITE_WIDTH            = 32
SPRITE_HEIGHT           = 32
SPRITE_BYTES            = SPRITE_WIDTH * SPRITE_HEIGHT

PALETTE_SIZE            = 16

; -------------------------------------------------------------------------
;
; variables and dragons!
;
; -------------------------------------------------------------------------
align 16
frame_buffer_commands:
        dw                      frame_buffer_commands_end - frame_buffer_commands
        fb_request              bus_cmd 0

        physical_display        bus_cmd Set_Physical_Display,   8,   SCREEN_WIDTH, SCREEN_HEIGHT
        virtual_buffer          bus_cmd Set_Virtual_Buffer,     8,   SCREEN_WIDTH, SCREEN_HEIGHT * 2
        color_depth             bus_cmd Set_Depth,              4,   8
        init_virtual_offset     bus_cmd Set_Virtual_Offset,     8,   0,            0
        palette                 bus_cmd Set_Palette,          264,   0,            64

        palette_data:        
                ; N.B. palette format is ABGR!
                ; palette 1
                dw $00ff9224, $ff0000ff, $ff0000b6, $ff4900ff 
                dw $ff2492db, $ff6d0000, $ff496d6d, $ff244949 
                dw $ff6d0000, $ff000000, $ff246ddb, $ff00246d 
                dw $ff004992, $ff004900, $ff006d00, $ffffffff    

                ; palette 2
                dw $0000496d, $ff002492, $ff0092db, $ff002449
                dw $ff006db6, $ff00246d, $ff006d00, $ffb62400 
                dw $ffffffff, $ff000000, $ffff9224, $ff0000ff 
                dw $ff6d6d6d, $ff494949, $ff6d0000, $ffffffff

                ; palette 3
                dw $00000000, $ffff9200, $ff6d0000, $ff4900ff
                dw $ff002492, $ff494949, $ff496d6d, $ff244949
                dw $ffffffff, $ff000000, $ff246ddb, $ff00246d
                dw $ff004992, $ff004900, $ff006d00, $ffffffff

                ; palette 4
                dw $00ff9224, $ff0000ff, $ff0092db, $ff4900ff
                dw $ff0049b6, $ff00246d, $ff496d6d, $ff494949
                dw $ff0000b6, $ff000000, $ff246ddb, $ff00246d
                dw $ff004992, $ff004900, $ff006d00, $ffffffff

        frame_buffer            bus_cmd Allocate_Buffer,        8,   0,            0

        fb_end_marker           bus_cmd 0
frame_buffer_commands_end:

align 16
set_virtual_offset_commands:
        dw                      set_virtual_offset_commands_end - set_virtual_offset_commands
        set_vo_request          bus_cmd 0

        virtual_offset          bus_cmd Set_Virtual_Offset,     8,   0,            0

        set_vo_end_marker       bus_cmd 0
set_virtual_offset_commands_end:

align 16
tile_copy       dma_control     DMA_TDMODE + DMA_DEST_INC + DMA_DEST_WIDTH + DMA_SRC_INC + DMA_SRC_WIDTH

align 16
sprite_control:
rept 128 {
        dw      0                   ; tile number
        dw      0                   ; y position
        dw      0                   ; x position
        dw      0                   ; palette # 0-3
        dw      0                   ; flags: hflip, vflip, rotate, etc....
        dw      0                   ; user data
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
page:           dw      1
page_bytes:     dw      SCREEN_WIDTH * SCREEN_HEIGHT
joy1:           dw      0
joy2:           dw      0
sound:          dw      256 dup(0)

align 8
title           string          "nybbles.io arcade kernel"

align 8
status          string          "UART configured for serial bootloader"

align 8
sys_font        font            8, 8, sys_font_ptr

align 8
sys_font_ptr:   include         'font8x8.s'

align 8
timber_fg:      file            'assets/timfg.bin'

align 8
timber_bg:      file            'assets/timbg.bin'

; -------------------------------------------------------------------------
;
; multi-core start up
;
; -------------------------------------------------------------------------
align 16
multi_core_start:
        mrs     x0, MPIDR_EL1
        mov     x1, #$ff000000
        bic     x0, x0, x1
        cbz     x0, core_zero
        sub     x1, x0, #1
        cbz     x1, core_one
        sub     x1, x0, #2
        cbz     x1, core_two
        sub     x1, x0, #3
        cbz     x1, core_three        

hang:
        b       hang

core_zero:
        mov     sp, #$8000
        b       engine

core_one:
        mov     sp, #$6000
        b       hang

core_two:
        mov     sp, #$4000
        b       hang

core_three:
        mov     sp, #$2000
        b       hang

; ------------------------------
;
; support functions
;
; ------------------------------
init_frame_buffer:
        mov     x1, MAIL_BASE
        orr     x1, x1, PERIPHERAL_BASE

.wait1: ldr     x2, [x1, MAIL_STATUS]
        tst     x2, MAIL_FULL
        b.ne    init_frame_buffer.wait1

        mov     w0, frame_buffer_commands + MAIL_TAGS
        str     w0, [x1, MAIL_WRITE]

.wait2: ldr     x2, [x1, MAIL_STATUS]
        tst     x2, MAIL_EMPTY
        b.ne    init_frame_buffer.wait2
        ldr     x2, [x1, MAIL_READ]

        ldr     w0, [frame_buffer.data1]
        b2p     w0
        adr     x1, frame_buffer.data1
        str     w0, [x1]
        ret

init_dma:
        mov     x0, PERIPHERAL_BASE
        orr     x0, x0, DMA_ENABLE
        mov     w1, DMA_EN0
        str     w1, [x0]
        ret

init_uart:
        ;     unsigned int ra;

        ;     PUT32(AUX_ENABLES,1);
        ;     PUT32(AUX_MU_IER_REG,0);
        ;     PUT32(AUX_MU_CNTL_REG,0);
        ;     PUT32(AUX_MU_LCR_REG,3);
        ;     PUT32(AUX_MU_MCR_REG,0);
        ;     PUT32(AUX_MU_IER_REG,0);
        ;     PUT32(AUX_MU_IIR_REG,0xC6);
        ;     PUT32(AUX_MU_BAUD_REG,270);
        ;     ra=GET32(GPFSEL1);
        ;     ra&=~(7<<12); //gpio14
        ;     ra|=2<<12;    //alt5
        ;     ra&=~(7<<15); //gpio15
        ;     ra|=2<<15;    //alt5
        ;     PUT32(GPFSEL1,ra);
        ;     PUT32(GPPUD,0);
        ;     for(ra=0;ra<150;ra++) dummy(ra);
        ;     PUT32(GPPUDCLK0,(1<<14)|(1<<15));
        ;     for(ra=0;ra<150;ra++) dummy(ra);
        ;     PUT32(GPPUDCLK0,0);
        ;     PUT32(AUX_MU_CNTL_REG,3);
        ret


; ------------------------------
;
; write_mailbox
;
; stack frame:
;       empty
;
; registers:
;       w0 address of commands
;       w2 result     
; ------------------------------
write_mailbox:        
        mov     x1, MAIL_BASE
        orr     x1, x1, PERIPHERAL_BASE        
.waitw: ldr     x2, [x1, MAIL_STATUS]
        tst     x2, MAIL_FULL
        b.ne    write_mailbox.waitw
        str     w0, [x1, MAIL_WRITE]        
.waitr: ldr     x2, [x1, MAIL_STATUS]
        tst     x2, MAIL_FULL
        b.ne    write_mailbox.waitr        
        ret

; ------------------------------
;
; page_swap
;
; stack frame:
;       empty
;
; registers:
;       none
;             
; ------------------------------
page_swap:
        adr     x3, virtual_offset.indicator
        mov     x2, 0
        str     x2, [x3]
        adr     x3, virtual_offset.data2
        adr     x1, page
        ldr     w2, [x1]
        cbz     w2, page_swap.page_1
        mov     w2, 0
        str     w2, [x1]
        mov     w2, 480
        str     w2, [x3]
        b       page_swap.set_offset
.page_1:
        mov     w2, 1
        str     w2, [x1]
        mov     w2, 0
        str     w2, [x3]
.set_offset:
.wait1: ldr     x2, [x1, MAIL_STATUS]
        tst     x2, MAIL_FULL
        b.ne    page_swap.wait1

        mov     w0, set_virtual_offset_commands + MAIL_TAGS
        str     w0, [x1, MAIL_WRITE]

.wait2: ldr     x2, [x1, MAIL_STATUS]
        tst     x2, MAIL_EMPTY
        b.ne    page_swap.wait2
        ldr     x2, [x1, MAIL_READ]
        ret

; ------------------------------
;
; draw_filled_rect
;
; stack frame:
;       empty
;
; registers:
;       w2 is the palette index to fill
;       w3 is y
;       w4 is x
;       w5 is width
;       w6 is height
;             
; ------------------------------
draw_filled_rect:
        lbb     
        mov     w6, SCREEN_WIDTH
        mul     w0, w6, w3
        add     w0, w0, w4
.row:        
        mov     w7, w5
.pixel:
        strb    x2, [x0], 1
        subs    w7, w7, 1
        b.ne    draw_filled_rect.pixel
        add     w0, w0, SCREEN_WIDTH
        sub     w0, w0, w5
        subs    w6, w6, 1
        b.ne    draw_filled_rect.row
        ret

; ------------------------------
;
; draw_hline
;
; stack frame:
;       empty
;
; registers:
;       w2 is the palette index to fill
;       w3 is y
;       w4 is x
;       w5 is width
;             
; ------------------------------
draw_hline:
        lbb
        mov     w6, SCREEN_WIDTH
        mul     w0, w6, w3
        add     w0, w0, w4        
.pixel:
        strb    x2, [x0], 1
        subs    w5, w5, 1
        b.ne    draw_hline.pixel
        ret

; ------------------------------
;
; draw_vline
;
; stack frame:
;       empty
;
; registers:
;       w2 is the palette index to fill
;       w3 is y
;       w4 is x
;       w5 is height
;             
; ------------------------------
draw_vline:
        lbb
        mov     w6, SCREEN_WIDTH
        mul     w0, w6, w3
        add     w0, w0, w4        
.pixel:
        strb    x2, [x0], 1
        add     w0, w0, SCREEN_WIDTH - 1
        subs    w5, w5, 1
        b.ne    draw_vline.pixel
        ret

; ------------------------------
;
; clear_screen
;
; stack frame:
;       empty
;
; registers:
;       w2 is the palette 
;          index to fill
; ------------------------------
clear_screen:
        lbb
        mov     w3, SCREEN_WIDTH
        mov     w4, SCREEN_HEIGHT
        mul     w3, w3, w4
        lsr     w3, w3, 3
.pixel:
        str     x2, [x0], 8
        subs    w3, w3, 1
        b.ne    clear_screen.pixel
        ret

; ------------------------------
;
; draw_string
;
; stack frame: 16 bytes
;       y coordinate
;       x coordinate
;       string address
;       string size
; ------------------------------
draw_string:
        lbb
        ldp     x2, x3, [sp]
        mov     w1, SCREEN_WIDTH
        mul     w1, w1, w2
        add     w1, w1, w3
        add     w0, w0, w1

        adr     x1, sys_font.ptr + 8
        ldp     x2, x3, [sp, #16]
        ldr     w10, [sys_font.w_stride]
        ldr     w11, [sys_font.h_stride]
        ldp     x13, x14, [sp, #32]
.raster:     
        ldr     w4, [sys_font.height]
        ldrb    x5, [x2], 1
        add     x5, x1, x5, lsl 6
.row:
        ldr     w12, [sys_font.width]
.pixel:
        ldrb    x6, [x5], 1
        cbz     x6, draw_string.skip
        strb    w13, [x0], 1
        b       draw_string.done
.skip:  add     x0, x0, 1
.done:  subs    w12, w12, 1
        b.ne    draw_string.pixel        
        add     x0, x0, x10
        subs    w4, w4, 1
        b.ne    draw_string.row
        sub     x0, x0, x11
        subs    w3, w3, 1
        b.ne    draw_string.raster
        ret

; ------------------------------
;
; draw background tile
;
; stack:
;       ypos
;       xpos
;       tile
;       palette
;
; ------------------------------
draw_tile:        
        lbb

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

; ------------------------------
;
; draw sprite stamp
;
; stack:
;       ypos
;       xpos
;       tile
;       palette
;
; ------------------------------
draw_stamp:        
        lbb
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

; Set fake_vsync_isr=1 in config.txt and I will trigger the SMI interrupt (48) from my vsync callback.
; In your ISR, you should write 0 to SMICS (0x7E600000/0x20600000) to clear it.
; ------------------------------
;
; engine state machine
;
; ------------------------------
engine:
        bl      init_dma
        bl      init_uart
        bl      init_frame_buffer

        sprite  0, 32, 32, 1, 0, 0  
        sprite  1, 64, 32, 2, 0, 0

; main loop code for game engine
;       
.loop:
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
        b.ne    engine.bg_tile
        mov     w13, 0
        add     w12, w12, TILE_HEIGHT
        subs    w11, w11, 1
        b.ne    engine.bg_row

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
        b.ne    engine.sprite_tile

        bl      page_swap
        b       engine.loop

irq_isr:
        eret

firq_isr:
        eret