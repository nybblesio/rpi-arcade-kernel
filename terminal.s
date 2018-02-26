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
; Data Section
;
; =========================================================
strdef  no_attr, TERM_NOATTR

strdef  bold_attr, TERM_BOLD

strdef  underline_attr, TERM_UNDERLINE

strdef  delete_char, TERM_DELCHAR

strdef  clr_screen, TERM_CLS, TERM_CURPOS11

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
   "serial console works.", TERM_NEWLINE2

strdef  parse_error, TERM_BLINK, TERM_REVERSE, TERM_BOLD, " ERROR: ", TERM_NOATTR, \
   " Unable to parse command: "

align 16        

; =========================================================
;
; send_welcome
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
send_welcome:
   sub      sp, sp, #16
   stp      x0, x30, [sp]   
   uart_str clr_screen
   uart_str kernel_title
   uart_str kernel_copyright
   uart_str kernel_license1
   uart_str kernel_license2
   uart_str kernel_help
   ldp      x0, x30, [sp]
   add      sp, sp, #16
   ret

; =========================================================
;
; new_prompt
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
new_prompt:
   sub      sp, sp, #16
   stp      x0, x30, [sp]
   mov      w1, CHAR_SPACE
   mov      w2, TERM_CHARS_PER_LINE
   adr      x3, command_buffer
   bl       fill_buffer
   mov      w1, 0 
   pstore   x0, w1, command_buffer_offset
   uart_chr '>'
   uart_spc
   ldp      x0, x30, [sp]
   add      sp, sp, #16
   ret

; =========================================================
;
; terminal_update
;
; stack:
;   (none)
;
; registers:
;   (none)
;
; =========================================================
terminal_update:
   sub      sp, sp, #16
   stp      x0, x30, [sp]

   bl       uart_recv
   cbz      w1, .exit

   cmp      w1, ESC_CHAR
   b.eq     .esc
   cmp      w1, RETURN_CHAR
   b.eq     .echo
   cmp      w1, LINEFEED_CHAR
   b.eq     .return
   cmp      w1, BACKSPACE_CHAR
   b.eq     .back

   pload    x3, w3, command_buffer_offset
   cmp      w3, TERM_CHARS_PER_LINE
   b.eq     .exit
   adr      x2, command_buffer
   add      x2, x2, x3
   strb     w1, [x2]
   add      w3, w3, 1
   pstore   x2, w3, command_buffer_offset
.echo:  
   bl       uart_send
   b        .exit

.return:
   adr      x2, command_buffer
   adr      x3, parse_buffer       
   mov      w4, 0
   pload    x5, w5, command_buffer_offset

.char:  
   cmp      w4, w5
   b.eq     .done
   ldrb     w1, [x2], 1
   cmp      w1, CHAR_SPACE
   b.eq     .done
   strb     w1, [x3], 1
   cmp      w4, PARSE_BUFFER_LENGTH
   b.eq     .err
   add      w4, w4, 1
   b        .char

.done:  
   uart_chr LINEFEED_CHAR
   b        .reset

.err:   
   uart_chr LINEFEED_CHAR
   bl       send_parse_error

.reset: 
   mov      w1, CHAR_SPACE
   mov      w2, PARSE_BUFFER_LENGTH
   adr      x3, parse_buffer
   bl       fill_buffer
   bl       new_prompt
   b        .exit

.back:  
   pload    x3, w3, command_buffer_offset
   cbz      w3, .exit
   sub      w3, w3, 1
   pstore   x2, w3, command_buffer_offset
   uart_chr BACKSPACE_CHAR
   uart_str delete_char
   b        .exit

.esc:   
   bl       uart_recv_block
   cmp      w1, LEFT_BRACKET
   b.ne     .exit
   bl       uart_recv_block
   cmp      w1, CHAR_A
   b.eq     .up
   cmp      w1, CHAR_B
   b.eq     .down
   cmp      w1, CHAR_C
   b.eq     .right
   cmp      w1, CHAR_D
   b.eq     .left
   b        .exit

.up:    
.down:  
.left:  
.right: 
.exit:  
   ldp      x0, x30, [sp]
   add      sp, sp, #16
   ret
