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
; Macros
;
; =========================================================
macro b2p reg {
     and        reg, reg, $3fffffff
}

struc mail_command_t tag*, size, data1, data2 {
    .tag dw  tag

    if ~size eq
        .size       dw size
        .indicator  dw  0
    end if

    if ~data1 eq
        .data1 dw data1
    end if

    if ~data2 eq
        .data2 dw data2
    end if
}

; =========================================================
;
; wait_for_mailbox_write
;
; stack:
;   (none)
;
; registers:
;   x1 mail base address
;
;   x2 status is loaded into this register
;
; =========================================================
wait_for_mailbox_write:
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    pload       x1, w1, mail_base
.loop:  
    ldr         w2, [x1, MAIL_STATUS]
    ands        w2, w2, MAIL_FULL
    b.ne        .loop
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; wait_for_mailbox_ready
;
; stack:
;   (none)
;
; registers:
;   x1 mail base address
;
;   x2 status is loaded into this register
;
; =========================================================
wait_for_mailbox_ready:
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    pload       x1, w1, mail_base
.loop:  
    ldr         w2, [x1, MAIL_STATUS]
    ands        w2, w2, MAIL_EMPTY
    b.ne        .loop
    ldr         w2, [x1, MAIL_READ]
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret

; =========================================================
;
; write_mailbox
;
; stack:
;   (none)
;
; registers:
;   w0 address of command array
;
; =========================================================
write_mailbox:
    sub         sp, sp, #16
    stp         x0, x30, [sp]
    bl          wait_for_mailbox_write
    pload       x1, w1, mail_base
    add         w0, w0, MAIL_TAGS
    str         w0, [x1, MAIL_WRITE]
    bl          wait_for_mailbox_ready
    ldp         x0, x30, [sp]
    add         sp, sp, #16
    ret    
