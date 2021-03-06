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
; Macros Section
;
; =========================================================
macro term_upload address {
   sub          sp, sp, #16
   mov          w25, address
   mov          w26, 0
   stp          x25, x26, [sp]
   bl           term_ihex
   ldp          x25, x26, [sp]
   add          sp, sp, #16
}

; =========================================================
;
; Data Section
;
; =========================================================
strdef  no_attr, TERM_NOATTR

strdef  bold_attr, TERM_BOLD

strdef  underline_attr, TERM_UNDERLINE

strdef  delete_char, TERM_DELCHAR

strdef  clr_screen, TERM_CLS, TERM_CURPOS11

strdef  new_line, TERM_NEWLINE

strdef  kernel_title, TERM_REVERSE, \
    "                Arcade Kernel Kit, v0.1              ", \ 
    TERM_NOATTR, \
    TERM_NEWLINE

strdef  kernel_copyright, \
    "Copyright (C) 2018 Jeff Panici.  All rights reserved.", \
    TERM_NEWLINE

strdef  kernel_license1, \
    "This software is licensed under the MIT license.", \
    TERM_NEWLINE

strdef  kernel_license2, \
    "See the LICENSE file for details.", \
    TERM_NEWLINE2

strdef  kernel_help, "Use the ", TERM_BOLD, TERM_UNDERLINE, "help", TERM_NOATTR, \
   " command to learn more about how the", TERM_NEWLINE, \
   "serial console works.", TERM_NEWLINE

strdef  parse_error, TERM_BLINK, TERM_REVERSE, TERM_BOLD, " ERROR: ", TERM_NOATTR, \
   " Unable to parse command: "

strdef  ihex_parse_error, TERM_BLINK, TERM_REVERSE, TERM_BOLD, " ERROR: ", TERM_NOATTR, \
   " Intel HEX format expected ':'. "

strdef  ihex_checksum_error, TERM_BLINK, TERM_REVERSE, TERM_BOLD, " ERROR: ", TERM_NOATTR, \
   " Intel HEX format checksum error parsing data line. "

ihex_line_buffer:
   db   256 dup(CHAR_SPACE)

align 4        

; =========================================================
;
; term_welcome
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
term_welcome:
   sub          sp, sp, #16
   stp          x0, x30, [sp]   
   uart_str     clr_screen
   uart_str     kernel_title
   uart_str     kernel_copyright
   uart_str     kernel_license1
   uart_str     kernel_license2
   uart_str     kernel_help
   ldp          x0, x30, [sp]
   add          sp, sp, #16
   ret

; =========================================================
;
; term_prompt
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
term_prompt:
   sub          sp, sp, #16
   stp          x0, x30, [sp]
   adr          x0, command_buffer
   mem_fill8    w0, TERM_CHARS_PER_LINE, CHAR_SPACE
   adr          x0, token_offsets
   mem_fill8    w0, TOKEN_OFFSET_COUNT, 0
   mov          w1, 0 
   pstore       x0, w1, command_buffer_offset
   uart_chr     '>'
   uart_spc
   ldp          x0, x30, [sp]
   add          sp, sp, #16
   ret

; =========================================================
;
; term_ihex
;
; stack:
;   target address
;   pad
;
; registers:
;   (none)
;
; =========================================================
term_ihex:
   sub          sp, sp, #96
   stp          x0, x30, [sp]
   stp          x1, x2, [sp, #16]
   stp          x3, x4, [sp, #32]
   stp          x5, x6, [sp, #48]
   stp          x7, x8, [sp, #64]
   stp          x9, x10, [sp, #80]
   ldp          x0, x1, [sp, #96]
   adr          x2, ihex_line_buffer
.line:   
   mem_fill8    w2, 256, CHAR_SPACE
   mov          w3, w2
.loop:
   ; XXX: check upper bound of the line buffer
   bl           uart_recv_block
   ;uart_chr     w1
   cmp          w1, '!'
   b.eq         .done
   cmp          w1, CHAR_RETURN
   b.eq         .loop
   cmp          w1, CHAR_LINEFEED
   b.eq         .parse
   strb         w1, [x3], 1
   b.ne         .loop
.parse:
   mov          w3, w2
   ldrb         w4, [x3], 1
   cmp          w4, ':'
   b.ne         .error
   str_nbr      w3, 2, 16       
   mov          w5, w20         ; number of data bytes
   add          w3, w3, 2
   str_nbr      w3, 4, 16
   mov          w6, w20
   add          w3, w3, 4
   str_nbr      w3, 2, 16
   cbz          w20, .data
   cmp          w20, 1
   b.eq         .eof
   b            .line
.data:
   mov          w4, 0
   add          w4, w4, w5
   and          w7, w6, $ff
   add          w4, w4, w7
   lsr          w7, w6, 8
   and          w7, w7, $ff
   add          w4, w4, w7
   add          w4, w4, w20
.byte:
   add          w3, w3, 2
   str_nbr      w3, 2, 16
   add          w4, w4, w20
   strb         w20, [x0], 1
   subs         w5, w5, 1
   b.ne         .byte   
   and          w4, w4, $ff
   neg          w4, w4
   and          w4, w4, $ff
   add          w3, w3, 2
   str_nbr      w3, 2, 16
   cmp          w4, w20
   b.ne         .checksum_error  
   b            .line
.eof:
   mov          w8, 0
   b            .done
.error:
   mov          w8, 1
   uart_str     ihex_parse_error
   b            .line
.checksum_error:
   mov          w8, 2 
   uart_str     ihex_checksum_error
   uart_nl
   uart_hex8    w4
   uart_chr     '!'
   uart_chr     '='
   uart_hex8    w20
   uart_nl
   b            .line
.done:
   mov          w2, 0
   stp          x8, x2, [sp, #96]
   ldp          x0, x30, [sp]
   ldp          x1, x2, [sp, #16]
   ldp          x3, x4, [sp, #32]
   ldp          x5, x6, [sp, #48]
   ldp          x7, x8, [sp, #64]
   ldp          x9, x10, [sp, #80]
   add          sp, sp, #96
   ret

; =========================================================
;
; term_read
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
term_read:
   sub          sp, sp, #80
   stp          x0, x30, [sp]
   stp          x1, x2, [sp, #16]
   stp          x3, x4, [sp, #32]
   stp          x5, x6, [sp, #48]
   stp          x7, x8, [sp, #64]
   
   ldp          x1, x2, [sp, #80]
   
   cmp          w1, CHAR_ESC
   b.eq         .esc
   cmp          w1, CHAR_RETURN
   b.eq         .echo
   cmp          w1, CHAR_LINEFEED
   b.eq         .return
   cmp          w1, CHAR_BACKSPACE
   b.eq         .back

   pload        x3, w3, command_buffer_offset
   cmp          w3, TERM_CHARS_PER_LINE
   b.eq         .exit
   adr          x2, command_buffer
   add          x2, x2, x3
   strb         w1, [x2]
   add          w3, w3, 1
   pstore       x2, w3, command_buffer_offset
.echo:  
   uart_chr     w1
   b            .exit

.return:
   uart_chr     CHAR_LINEFEED
   adr          x2, command_buffer
   adr          x3, token_offsets
   mov          w4, 0
   pload        x5, w5, command_buffer_offset
   mov          w6, TOKEN_OFFSET_COUNT

.char:  
   cmp          w4, w5
   b.eq         .bufend
   ldrb         w1, [x2], 1
   cmp          w1, CHAR_SPACE
   b.ne         .next
   strb         w4, [x3], 1
   subs         w6, w6, 1
   b.eq         .done
.next:
   add          w4, w4, 1
   b            .char
.bufend:
   cbz          w4, .reset
   cbz          w6, .done
   strb         w4, [x3], 1

.done:
   bl           command_find
   cbz          w1, .err
   ldr          w2, [x1, CMD_DEF_CALLBACK]
   cbz          w2, .reset
   blr          x2
   b            .reset

.err:   
   ploadb       x1, w1, token_offsets
   bl           command_error

.reset: 
   uart_nl   
   bl           term_prompt
   b            .exit

.back:  
   pload        x3, w3, command_buffer_offset
   cbz          w3, .exit
   sub          w3, w3, 1
   pstore       x2, w3, command_buffer_offset
   uart_chr     CHAR_BACKSPACE
   uart_str     delete_char
   b            .exit

.esc:   
   bl           uart_recv_block
   cmp          w1, CHAR_LBRACKET
   b.ne         .exit
   bl           uart_recv_block
   cmp          w1, CHAR_A
   b.eq         .up
   cmp          w1, CHAR_B
   b.eq         .down
   cmp          w1, CHAR_C
   b.eq         .right
   cmp          w1, CHAR_D
   b.eq         .left
   b            .exit

.up:    
.down:  
.left:  
.right: 
.exit:  
   ldp          x0, x30, [sp]
   ldp          x1, x2, [sp, #16]
   ldp          x3, x4, [sp, #32]
   ldp          x5, x6, [sp, #48]
   ldp          x7, x8, [sp, #64]
   add          sp, sp, #96
   ret

macro term_read reg {
   sub          sp, sp, #16
   mov          w25, reg
   mov          w26, 0
   stp          x25, x26, [sp]
   bl           term_read
}

; =========================================================
;
; term_update
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
term_update:
   sub          sp, sp, #32
   stp          x0, x30, [sp]
   stp          x1, x2, [sp, #16]

.loop:
   bl           uart_recv
   cbz          w1, .exit
   term_read    w1
   b            .loop
   
.exit:  
   ldp          x0, x30, [sp]
   ldp          x1, x2, [sp, #16]
   add          sp, sp, #32
   ret
