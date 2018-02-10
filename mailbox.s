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
         and     w0, w0, $3fffffff
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
.wait1: ldr     x2, [x1, MAIL_STATUS]
        tst     x2, MAIL_FULL
        b.ne    write_mailbox.wait1

        add     w0, w0, MAIL_TAGS
        str     w0, [x1, MAIL_WRITE]

.wait2: ldr     x2, [x1, MAIL_STATUS]
        tst     x2, MAIL_EMPTY
        b.ne    write_mailbox.wait2
        ldr     x2, [x1, MAIL_READ]
        ret

