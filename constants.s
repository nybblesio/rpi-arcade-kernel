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

TRUE                    = 1
FALSE                   = 0

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

ESC_CHAR        = $1b
BACKSPACE_CHAR  = $08
RETURN_CHAR     = $0d
LINEFEED_CHAR   = $0a
LEFT_BRACKET    = $5b
CHAR_A          = $41
CHAR_B          = $42
CHAR_C          = $43
CHAR_D          = $44
CHAR_SPACE      = $20

TERM_CHARS_PER_LINE = 76
PARSE_BUFFER_LENGTH = 32

TERM_CLS        equ ESC_CHAR, "[2J"
TERM_CURPOS11   equ ESC_CHAR, "[1;1H"
TERM_REVERSE    equ ESC_CHAR, "[7m"
TERM_NOATTR     equ ESC_CHAR, "[m"
TERM_UNDERLINE  equ ESC_CHAR, "[4m"
TERM_BLINK      equ ESC_CHAR, "[5m"
TERM_BOLD       equ ESC_CHAR, "[1m"
TERM_DELCHAR    equ ESC_CHAR, "[1P"
TERM_NEWLINE    equ $0d, $0a
TERM_NEWLINE2   equ $0d, $0a, $0d, $0a
TERM_BLACK      equ ESC_CHAR, "[30m"
TERM_RED        equ ESC_CHAR, "[31m"
TERM_GREEN      equ ESC_CHAR, "[32m"
TERM_YELLOW     equ ESC_CHAR, "[33m"
TERM_BLUE       equ ESC_CHAR, "[34m"
TERM_MAGENTA    equ ESC_CHAR, "[35m"
TERM_CYAN       equ ESC_CHAR, "[36m"
TERM_WHITE      equ ESC_CHAR, "[37m"
TERM_BG_BLACK   equ ESC_CHAR, "[40m"
TERM_BG_RED     equ ESC_CHAR, "[41m"
TERM_BG_GREEN   equ ESC_CHAR, "[42m"
TERM_BG_YELLOW  equ ESC_CHAR, "[43m"
TERM_BG_BLUE    equ ESC_CHAR, "[44m"
TERM_BG_MAGENTA equ ESC_CHAR, "[45m"
TERM_BG_CYAN    equ ESC_CHAR, "[46m"
TERM_BG_WHITE   equ ESC_CHAR, "[47m"

; =========================================================
;
; Raspberry Pi 2 & 3 Constants
;
; =========================================================

; Bus Address
PERIPHERAL_BASE                = $3F000000 ; Peripheral Base Address
BUS_ADDRESSES_l2CACHE_ENABLED  = $40000000 ; Bus Addresses: disable_l2cache=0
BUS_ADDRESSES_l2CACHE_DISABLED = $C0000000 ; Bus Addresses: disable_l2cache=1

; Mailbox
MAIL_BASE   = $B880 ; Mailbox Base Address
MAIL_READ   =    $0 ; Mailbox Read Register
MAIL_CONFIG =   $1C ; Mailbox Config Register
MAIL_STATUS =   $18 ; Mailbox Status Register
MAIL_WRITE  =   $20 ; Mailbox Write Register

MAIL_EMPTY = $40000000 ; Mailbox Status Register: Mailbox Empty (There is nothing to read from the Mailbox)
MAIL_FULL  = $80000000 ; Mailbox Status Register: Mailbox Full  (There is no space to write into the Mailbox)

MAIL_POWER   = $0 ; Mailbox Channel 0: Power Management Interface
MAIL_FB      = $1 ; Mailbox Channel 1: Frame Buffer
MAIL_VUART   = $2 ; Mailbox Channel 2: Virtual UART 
MAIL_VCHIQ   = $3 ; Mailbox Channel 3: VCHIQ Interface
MAIL_LEDS    = $4 ; Mailbox Channel 4: LEDs Interface
MAIL_BUTTONS = $5 ; Mailbox Channel 5: Buttons Interface
MAIL_TOUCH   = $6 ; Mailbox Channel 6: Touchscreen Interface
MAIL_COUNT   = $7 ; Mailbox Channel 7: Counter
MAIL_TAGS    = $8 ; Mailbox Channel 8: Tags (ARM to VC)

; Tags (ARM to VC)
Get_Firmware_Revision = $00000001 ; VideoCore: Get Firmware Revision (Response: Firmware Revision)
Get_Board_Model       = $00010001 ; Hardware: Get Board Model (Response: Board Model)
Get_Board_Revision    = $00010002 ; Hardware: Get Board Revision (Response: Board Revision)
Get_Board_MAC_Address = $00010003 ; Hardware: Get Board MAC Address (Response: MAC Address In Network Byte Order)
Get_Board_Serial      = $00010004 ; Hardware: Get Board Serial (Response: Board Serial)
Get_ARM_Memory        = $00010005 ; Hardware: Get ARM Memory (Response: Base Address In Bytes, Size In Bytes)
Get_VC_Memory         = $00010006 ; Hardware: Get VC Memory (Response: Base Address In Bytes, Size In Bytes)
Get_Clocks            = $00010007 ; Hardware: Get Clocks (Response: Parent Clock ID (0 For A Root Clock), Clock ID)
Get_Power_State       = $00020001 ; Power: Get Power State (Response: Device ID, State)
Get_Timing            = $00020002 ; Power: Get Timing (Response: Device ID, Enable Wait Time In Microseconds)
Set_Power_State       = $00028001 ; Power: Set Power State (Response: Device ID, State)
Get_Clock_State       = $00030001 ; Clocks: Get Clock State (Response: Clock ID, State)
Get_Clock_Rate        = $00030002 ; Clocks: Get Clock Rate (Response: Clock ID, Rate In Hz)
Get_Voltage           = $00030003 ; Voltage: Get Voltage (Response: Voltage ID, Value Offset From 1.2V In Units Of 0.025V)
Get_Max_Clock_Rate    = $00030004 ; Clocks: Get Max Clock Rate (Response: Clock ID, Rate In Hz)
Get_Max_Voltage       = $00030005 ; Voltage: Get Max Voltage (Response: Voltage ID, Value Offset From 1.2V In Units Of 0.025V)
Get_Temperature       = $00030006 ; Voltage: Get Temperature (Response: Temperature ID, Value In Degrees C)
Get_Min_Clock_Rate    = $00030007 ; Clocks: Get Min Clock Rate (Response: Clock ID, Rate In Hz)
Get_Min_Voltage       = $00030008 ; Voltage: Get Min Voltage (Response: Voltage ID, Value Offset From 1.2V In Units Of 0.025V)
Get_Turbo             = $00030009 ; Clocks: Get Turbo (Response: ID, Level)
Get_Max_Temperature   = $0003000A ; Voltage: Get Max Temperature (Response: Temperature ID, Value In Degrees C)
Allocate_Memory       = $0003000C ; Memory: Allocates Contiguous Memory On The GPU (Response: Handle)
Lock_Memory           = $0003000D ; Memory: Lock Buffer In Place, And Return A Bus Address (Response: Bus Address)
Unlock_Memory         = $0003000E ; Memory: Unlock Buffer (Response: Status)
Release_Memory        = $0003000F ; Memory: Free The Memory Buffer (Response: Status)
Execute_Code          = $00030010 ; Memory: Calls The Function At Given (Bus) Address And With Arguments Given
Execute_QPU           = $00030011 ; QPU: Calls The QPU Function At Given (Bus) Address And With Arguments Given (Response: Number Of QPUs, Control, No Flush, Timeout In ms)
Enable_QPU            = $00030012 ; QPU: Enables The QPU (Response: Enable State)
Get_EDID_Block        = $00030020 ; HDMI: Read Specificed EDID Block From Attached HDMI/DVI Device (Response: Block Number, Status, EDID Block (128 Bytes))
Set_Clock_State       = $00038001 ; Clocks: Set Clock State (Response: Clock ID, State)
Set_Clock_Rate        = $00038002 ; Clocks: Set Clock Rate (Response: Clock ID, Rate In Hz)
Set_Voltage           = $00038003 ; Voltage: Set Voltage (Response: Voltage ID, Value Offset From 1.2V In Units Of 0.025V)
Set_Turbo             = $00038009 ; Clocks: Set Turbo (Response: ID, Level)
Allocate_Buffer       = $00040001 ; Frame Buffer: Allocate Buffer (Response: Frame Buffer Base Address In Bytes, Frame Buffer Size In Bytes)
Blank_Screen          = $00040002 ; Frame Buffer: Blank Screen (Response: State)
Get_Physical_Display  = $00040003 ; Frame Buffer: Get Physical (Display) Width/Height (Response: Width In Pixels, Height In Pixels)
Get_Virtual_Buffer    = $00040004 ; Frame Buffer: Get Virtual (Buffer) Width/Height (Response: Width In Pixels, Height In Pixels)
Get_Depth             = $00040005 ; Frame Buffer: Get Depth (Response: Bits Per Pixel)
Get_Pixel_Order       = $00040006 ; Frame Buffer: Get Pixel Order (Response: State)
Get_Alpha_Mode        = $00040007 ; Frame Buffer: Get Alpha Mode (Response: State)
Get_Pitch             = $00040008 ; Frame Buffer: Get Pitch (Response: Bytes Per Line)
Get_Virtual_Offset    = $00040009 ; Frame Buffer: Get Virtual Offset (Response: X In Pixels, Y In Pixels)
Get_Overscan          = $0004000A ; Frame Buffer: Get Overscan (Response: Top In Pixels, Bottom In Pixels, Left In Pixels, Right In Pixels)
Get_Palette           = $0004000B ; Frame Buffer: Get Palette (Response: RGBA Palette Values (Index 0 To 255))
Test_Physical_Display = $00044003 ; Frame Buffer: Test Physical (Display) Width/Height (Response: Width In Pixels, Height In Pixels)
Test_Virtual_Buffer   = $00044004 ; Frame Buffer: Test Virtual (Buffer) Width/Height (Response: Width In Pixels, Height In Pixels)
Test_Depth            = $00044005 ; Frame Buffer: Test Depth (Response: Bits Per Pixel)
Test_Pixel_Order      = $00044006 ; Frame Buffer: Test Pixel Order (Response: State)
Test_Alpha_Mode       = $00044007 ; Frame Buffer: Test Alpha Mode (Response: State)
Test_Virtual_Offset   = $00044009 ; Frame Buffer: Test Virtual Offset (Response: X In Pixels, Y In Pixels)
Test_Overscan         = $0004400A ; Frame Buffer: Test Overscan (Response: Top In Pixels, Bottom In Pixels, Left In Pixels, Right In Pixels)
Test_Palette          = $0004400B ; Frame Buffer: Test Palette (Response: RGBA Palette Values (Index 0 To 255))
Release_Buffer        = $00048001 ; Frame Buffer: Release Buffer (Response: Releases And Disables The Frame Buffer)
Set_Physical_Display  = $00048003 ; Frame Buffer: Set Physical (Display) Width/Height (Response: Width In Pixels, Height In Pixels)
Set_Virtual_Buffer    = $00048004 ; Frame Buffer: Set Virtual (Buffer) Width/Height (Response: Width In Pixels, Height In Pixels)
Set_Depth             = $00048005 ; Frame Buffer: Set Depth (Response: Bits Per Pixel)
Set_Pixel_Order       = $00048006 ; Frame Buffer: Set Pixel Order (Response: State)
Set_Alpha_Mode        = $00048007 ; Frame Buffer: Set Alpha Mode (Response: State)
Set_Virtual_Offset    = $00048009 ; Frame Buffer: Set Virtual Offset (Response: X In Pixels, Y In Pixels)
Set_Overscan          = $0004800A ; Frame Buffer: Set Overscan (Response: Top In Pixels, Bottom In Pixels, Left In Pixels, Right In Pixels)
Set_Palette           = $0004800B ; Frame Buffer: Set Palette (Response: RGBA Palette Values (Index 0 To 255))
Get_Command_Line      = $00050001 ; Config: Get Command Line (Response: ASCII Command Line String)
Get_DMA_Channels      = $00060001 ; Shared Resource Management: Get DMA Channels (Response: Bits 0-15: DMA channels 0-15)

; Power: Unique Device ID's
PWR_SD_Card_ID = $0 ; SD Card
PWR_UART0_ID   = $1 ; UART0
PWR_UART1_ID   = $2 ; UART1
PWR_USB_HCD_ID = $3 ; USB HCD
PWR_I2C0_ID    = $4 ; I2C0
PWR_I2C1_ID    = $5 ; I2C1
PWR_I2C2_ID    = $6 ; I2C2
PWR_SPI_ID     = $7 ; SPI
PWR_CCP2TX_ID  = $8 ; CCP2TX

; Clocks: Unique Clock ID's
CLK_EMMC_ID  = $1 ; EMMC
CLK_UART_ID  = $2 ; UART
CLK_ARM_ID   = $3 ; ARM
CLK_CORE_ID  = $4 ; CORE
CLK_V3D_ID   = $5 ; V3D
CLK_H264_ID  = $6 ; H264
CLK_ISP_ID   = $7 ; ISP
CLK_SDRAM_ID = $8 ; SDRAM
CLK_PIXEL_ID = $9 ; PIXEL
CLK_PWM_ID   = $A ; PWM

; Voltage: Unique Voltage ID's
VLT_Core_ID    = $1 ; Core
VLT_SDRAM_C_ID = $2 ; SDRAM_C
VLT_SDRAM_P_ID = $3 ; SDRAM_P
VLT_SDRAM_I_ID = $4 ; SDRAM_I

; CM / Clock Manager
CM_BASE   = $101000 ; Clock Manager Base Address
CM_GNRICCTL =  $000 ; Clock Manager Generic Clock Control
CM_GNRICDIV =  $004 ; Clock Manager Generic Clock Divisor
CM_VPUCTL   =  $008 ; Clock Manager VPU Clock Control
CM_VPUDIV   =  $00C ; Clock Manager VPU Clock Divisor
CM_SYSCTL   =  $010 ; Clock Manager System Clock Control
CM_SYSDIV   =  $014 ; Clock Manager System Clock Divisor
CM_PERIACTL =  $018 ; Clock Manager PERIA Clock Control
CM_PERIADIV =  $01C ; Clock Manager PERIA Clock Divisor
CM_PERIICTL =  $020 ; Clock Manager PERII Clock Control
CM_PERIIDIV =  $024 ; Clock Manager PERII Clock Divisor
CM_H264CTL  =  $028 ; Clock Manager H264 Clock Control
CM_H264DIV  =  $02C ; Clock Manager H264 Clock Divisor
CM_ISPCTL   =  $030 ; Clock Manager ISP Clock Control
CM_ISPDIV   =  $034 ; Clock Manager ISP Clock Divisor
CM_V3DCTL   =  $038 ; Clock Manager V3D Clock Control
CM_V3DDIV   =  $03C ; Clock Manager V3D Clock Divisor
CM_CAM0CTL  =  $040 ; Clock Manager Camera 0 Clock Control
CM_CAM0DIV  =  $044 ; Clock Manager Camera 0 Clock Divisor
CM_CAM1CTL  =  $048 ; Clock Manager Camera 1 Clock Control
CM_CAM1DIV  =  $04C ; Clock Manager Camera 1 Clock Divisor
CM_CCP2CTL  =  $050 ; Clock Manager CCP2 Clock Control
CM_CCP2DIV  =  $054 ; Clock Manager CCP2 Clock Divisor
CM_DSI0ECTL =  $058 ; Clock Manager DSI0E Clock Control
CM_DSI0EDIV =  $05C ; Clock Manager DSI0E Clock Divisor
CM_DSI0PCTL =  $060 ; Clock Manager DSI0P Clock Control
CM_DSI0PDIV =  $064 ; Clock Manager DSI0P Clock Divisor
CM_DPICTL   =  $068 ; Clock Manager DPI Clock Control
CM_DPIDIV   =  $06C ; Clock Manager DPI Clock Divisor
CM_GP0CTL   =  $070 ; Clock Manager General Purpose 0 Clock Control
CM_GP0DIV   =  $074 ; Clock Manager General Purpose 0 Clock Divisor
CM_GP1CTL   =  $078 ; Clock Manager General Purpose 1 Clock Control
CM_GP1DIV   =  $07C ; Clock Manager General Purpose 1 Clock Divisor
CM_GP2CTL   =  $080 ; Clock Manager General Purpose 2 Clock Control
CM_GP2DIV   =  $084 ; Clock Manager General Purpose 2 Clock Divisor
CM_HSMCTL   =  $088 ; Clock Manager HSM Clock Control
CM_HSMDIV   =  $08C ; Clock Manager HSM Clock Divisor
CM_OTPCTL   =  $090 ; Clock Manager OTP Clock Control
CM_OTPDIV   =  $094 ; Clock Manager OTP Clock Divisor
CM_PCMCTL   =  $098 ; Clock Manager PCM / I2S Clock Control
CM_PCMDIV   =  $09C ; Clock Manager PCM / I2S Clock Divisor
CM_PWMCTL   =  $0A0 ; Clock Manager PWM Clock Control
CM_PWMDIV   =  $0A4 ; Clock Manager PWM Clock Divisor
CM_SLIMCTL  =  $0A8 ; Clock Manager SLIM Clock Control
CM_SLIMDIV  =  $0AC ; Clock Manager SLIM Clock Divisor
CM_SMICTL   =  $0B0 ; Clock Manager SMI Clock Control
CM_SMIDIV   =  $0B4 ; Clock Manager SMI Clock Divisor
CM_TCNTCTL  =  $0C0 ; Clock Manager TCNT Clock Control
CM_TCNTDIV  =  $0C4 ; Clock Manager TCNT Clock Divisor
CM_TECCTL   =  $0C8 ; Clock Manager TEC Clock Control
CM_TECDIV   =  $0CC ; Clock Manager TEC Clock Divisor
CM_TD0CTL   =  $0D0 ; Clock Manager TD0 Clock Control
CM_TD0DIV   =  $0D4 ; Clock Manager TD0 Clock Divisor
CM_TD1CTL   =  $0D8 ; Clock Manager TD1 Clock Control
CM_TD1DIV   =  $0DC ; Clock Manager TD1 Clock Divisor
CM_TSENSCTL =  $0E0 ; Clock Manager TSENS Clock Control
CM_TSENSDIV =  $0E4 ; Clock Manager TSENS Clock Divisor
CM_TIMERCTL =  $0E8 ; Clock Manager Timer Clock Control
CM_TIMERDIV =  $0EC ; Clock Manager Timer Clock Divisor
CM_UARTCTL  =  $0F0 ; Clock Manager UART Clock Control
CM_UARTDIV  =  $0F4 ; Clock Manager UART Clock Divisor
CM_VECCTL   =  $0F8 ; Clock Manager VEC Clock Control
CM_VECDIV   =  $0FC ; Clock Manager VEC Clock Divisor
CM_OSCCOUNT =  $100 ; Clock Manager Oscillator Count
CM_PLLA     =  $104 ; Clock Manager PLLA
CM_PLLC     =  $108 ; Clock Manager PLLC
CM_PLLD     =  $10C ; Clock Manager PLLD
CM_PLLH     =  $110 ; Clock Manager PLLH
CM_LOCK     =  $114 ; Clock Manager Lock
CM_EVENT    =  $118 ; Clock Manager Event
CM_INTEN    =  $118 ; Clock Manager INTEN
CM_DSI0HSCK =  $120 ; Clock Manager DSI0HSCK
CM_CKSM     =  $124 ; Clock Manager CKSM
CM_OSCFREQI =  $128 ; Clock Manager Oscillator Frequency Integer
CM_OSCFREQF =  $12C ; Clock Manager Oscillator Frequency Fraction
CM_PLLTCTL  =  $130 ; Clock Manager PLLT Control
CM_PLLTCNT0 =  $134 ; Clock Manager PLLT0
CM_PLLTCNT1 =  $138 ; Clock Manager PLLT1
CM_PLLTCNT2 =  $13C ; Clock Manager PLLT2
CM_PLLTCNT3 =  $140 ; Clock Manager PLLT3
CM_TDCLKEN  =  $144 ; Clock Manager TD Clock Enable
CM_BURSTCTL =  $148 ; Clock Manager Burst Control
CM_BURSTCNT =  $14C ; Clock Manager Burst
CM_DSI1ECTL =  $158 ; Clock Manager DSI1E Clock Control
CM_DSI1EDIV =  $15C ; Clock Manager DSI1E Clock Divisor
CM_DSI1PCTL =  $160 ; Clock Manager DSI1P Clock Control
CM_DSI1PDIV =  $164 ; Clock Manager DSI1P Clock Divisor
CM_DFTCTL   =  $168 ; Clock Manager DFT Clock Control
CM_DFTDIV   =  $16C ; Clock Manager DFT Clock Divisor
CM_PLLB     =  $170 ; Clock Manager PLLB
CM_PULSECTL =  $190 ; Clock Manager Pulse Clock Control
CM_PULSEDIV =  $194 ; Clock Manager Pulse Clock Divisor
CM_SDCCTL   =  $1A8 ; Clock Manager SDC Clock Control
CM_SDCDIV   =  $1AC ; Clock Manager SDC Clock Divisor
CM_ARMCTL   =  $1B0 ; Clock Manager ARM Clock Control
CM_ARMDIV   =  $1B4 ; Clock Manager ARM Clock Divisor
CM_AVEOCTL  =  $1B8 ; Clock Manager AVEO Clock Control
CM_AVEODIV  =  $1BC ; Clock Manager AVEO Clock Divisor
CM_EMMCCTL  =  $1C0 ; Clock Manager EMMC Clock Control
CM_EMMCDIV  =  $1C4 ; Clock Manager EMMC Clock Divisor

CM_SRC_OSCILLATOR =       $01 ; Clock Control: Clock Source = Oscillator
CM_SRC_TESTDEBUG0 =       $02 ; Clock Control: Clock Source = Test Debug 0
CM_SRC_TESTDEBUG1 =       $03 ; Clock Control: Clock Source = Test Debug 1
CM_SRC_PLLAPER    =       $04 ; Clock Control: Clock Source = PLLA Per
CM_SRC_PLLCPER    =       $05 ; Clock Control: Clock Source = PLLC Per
CM_SRC_PLLDPER    =       $06 ; Clock Control: Clock Source = PLLD Per
CM_SRC_HDMIAUX    =       $07 ; Clock Control: Clock Source = HDMI Auxiliary
CM_SRC_GND        =       $08 ; Clock Control: Clock Source = GND
CM_ENAB           =       $10 ; Clock Control: Enable The Clock Generator
CM_KILL           =       $20 ; Clock Control: Kill The Clock Generator
CM_BUSY           =       $80 ; Clock Control: Clock Generator Is Running
CM_FLIP           =      $100 ; Clock Control: Invert The Clock Generator Output
CM_MASH_1         =      $200 ; Clock Control: MASH Control = 1-Stage MASH (Equivalent To Non-MASH Dividers)
CM_MASH_2         =      $400 ; Clock Control: MASH Control = 2-Stage MASH
CM_MASH_3         =      $600 ; Clock Control: MASH Control = 3-Stage MASH
CM_PASSWORD       = $5A000000 ; Clock Control: Password "5A"

; DMA Controller
DMA0_BASE  = $7000 ; DMA Channel 0 Register Set
DMA1_BASE  = $7100 ; DMA Channel 1 Register Set
DMA2_BASE  = $7200 ; DMA Channel 2 Register Set
DMA3_BASE  = $7300 ; DMA Channel 3 Register Set
DMA4_BASE  = $7400 ; DMA Channel 4 Register Set
DMA5_BASE  = $7500 ; DMA Channel 5 Register Set
DMA6_BASE  = $7600 ; DMA Channel 6 Register Set
DMA7_BASE  = $7700 ; DMA Channel 7 Register Set
DMA8_BASE  = $7800 ; DMA Channel 8 Register Set
DMA9_BASE  = $7900 ; DMA Channel 9 Register Set
DMA10_BASE = $7A00 ; DMA Channel 10 Register Set
DMA11_BASE = $7B00 ; DMA Channel 11 Register Set
DMA12_BASE = $7C00 ; DMA Channel 12 Register Set
DMA13_BASE = $7D00 ; DMA Channel 13 Register Set
DMA14_BASE = $7E00 ; DMA Channel 14 Register Set

DMA_INT_STATUS = $7FE0 ; Interrupt Status of each DMA Channel
DMA_ENABLE     = $7FF0 ; Global Enable bits for each DMA Channel

DMA15_BASE = $E05000 ; DMA Channel 15 Register Set

DMA_CS        =  $0 ; DMA Channel 0..14 Control & Status
DMA_CONBLK_AD =  $4 ; DMA Channel 0..14 Control Block Address
DMA_TI        =  $8 ; DMA Channel 0..14 CB Word 0 (Transfer Information)
DMA_SOURCE_AD =  $C ; DMA Channel 0..14 CB Word 1 (Source Address)
DMA_DEST_AD   = $10 ; DMA Channel 0..14 CB Word 2 (Destination Address)
DMA_TXFR_LEN  = $14 ; DMA Channel 0..14 CB Word 3 (Transfer Length)
DMA_STRIDE    = $18 ; DMA Channel 0..14 CB Word 4 (2D Stride)
DMA_NEXTCONBK = $1C ; DMA Channel 0..14 CB Word 5 (Next CB Address)
DMA_DEBUG     = $20 ; DMA Channel 0..14 Debug

DMA_ACTIVE                         =        $1 ; DMA Control & Status: Activate the DMA
DMA_END                            =        $2 ; DMA Control & Status: DMA End Flag
DMA_INT                            =        $4 ; DMA Control & Status: Interrupt Status
DMA_DREQ                           =        $8 ; DMA Control & Status: DREQ State
DMA_PAUSED                         =       $10 ; DMA Control & Status: DMA Paused State
DMA_DREQ_STOPS_DMA                 =       $20 ; DMA Control & Status: DMA Paused by DREQ State
DMA_WAITING_FOR_OUTSTANDING_WRITES =       $40 ; DMA Control & Status: DMA is Waiting for the Last Write to be Received
DMA_ERROR                          =      $100 ; DMA Control & Status: DMA Error
DMA_PRIORITY_0                     =        $0 ; DMA Control & Status: AXI Priority Level 0
DMA_PRIORITY_1                     =    $10000 ; DMA Control & Status: AXI Priority Level 1
DMA_PRIORITY_2                     =    $20000 ; DMA Control & Status: AXI Priority Level 2
DMA_PRIORITY_3                     =    $30000 ; DMA Control & Status: AXI Priority Level 3
DMA_PRIORITY_4                     =    $40000 ; DMA Control & Status: AXI Priority Level 4
DMA_PRIORITY_5                     =    $50000 ; DMA Control & Status: AXI Priority Level 5
DMA_PRIORITY_6                     =    $60000 ; DMA Control & Status: AXI Priority Level 6
DMA_PRIORITY_7                     =    $70000 ; DMA Control & Status: AXI Priority Level 7
DMA_PRIORITY_8                     =    $80000 ; DMA Control & Status: AXI Priority Level 8
DMA_PRIORITY_9                     =    $90000 ; DMA Control & Status: AXI Priority Level 9
DMA_PRIORITY_10                    =    $A0000 ; DMA Control & Status: AXI Priority Level 10
DMA_PRIORITY_11                    =    $B0000 ; DMA Control & Status: AXI Priority Level 11
DMA_PRIORITY_12                    =    $C0000 ; DMA Control & Status: AXI Priority Level 12
DMA_PRIORITY_13                    =    $D0000 ; DMA Control & Status: AXI Priority Level 13
DMA_PRIORITY_14                    =    $E0000 ; DMA Control & Status: AXI Priority Level 14
DMA_PRIORITY_15                    =    $F0000 ; DMA Control & Status: AXI Priority Level 15
DMA_PRIORITY                       =    $F0000 ; DMA Control & Status: AXI Priority Level
DMA_PANIC_PRIORITY_0               =        $0 ; DMA Control & Status: AXI Panic Priority Level 0
DMA_PANIC_PRIORITY_1               =   $100000 ; DMA Control & Status: AXI Panic Priority Level 1
DMA_PANIC_PRIORITY_2               =   $200000 ; DMA Control & Status: AXI Panic Priority Level 2
DMA_PANIC_PRIORITY_3               =   $300000 ; DMA Control & Status: AXI Panic Priority Level 3
DMA_PANIC_PRIORITY_4               =   $400000 ; DMA Control & Status: AXI Panic Priority Level 4
DMA_PANIC_PRIORITY_5               =   $500000 ; DMA Control & Status: AXI Panic Priority Level 5
DMA_PANIC_PRIORITY_6               =   $600000 ; DMA Control & Status: AXI Panic Priority Level 6
DMA_PANIC_PRIORITY_7               =   $700000 ; DMA Control & Status: AXI Panic Priority Level 7
DMA_PANIC_PRIORITY_8               =   $800000 ; DMA Control & Status: AXI Panic Priority Level 8
DMA_PANIC_PRIORITY_9               =   $900000 ; DMA Control & Status: AXI Panic Priority Level 9
DMA_PANIC_PRIORITY_10              =   $A00000 ; DMA Control & Status: AXI Panic Priority Level 10
DMA_PANIC_PRIORITY_11              =   $B00000 ; DMA Control & Status: AXI Panic Priority Level 11
DMA_PANIC_PRIORITY_12              =   $C00000 ; DMA Control & Status: AXI Panic Priority Level 12
DMA_PANIC_PRIORITY_13              =   $D00000 ; DMA Control & Status: AXI Panic Priority Level 13
DMA_PANIC_PRIORITY_14              =   $E00000 ; DMA Control & Status: AXI Panic Priority Level 14
DMA_PANIC_PRIORITY_15              =   $F00000 ; DMA Control & Status: AXI Panic Priority Level 14
DMA_PANIC_PRIORITY                 =   $F00000 ; DMA Control & Status: AXI Panic Priority Level
DMA_WAIT_FOR_OUTSTANDING_WRITES    = $10000000 ; DMA Control & Status: Wait for Outstanding Writes
DMA_DISDEBUG                       = $20000000 ; DMA Control & Status: Disable Debug Pause Signal
DMA_ABORT                          = $40000000 ; DMA Control & Status: Abort DMA
DMA_RESET                          = $80000000 ; DMA Control & Status: DMA Channel Reset

DMA_INTEN           =       $1 ; DMA Transfer Information: Interrupt Enable
DMA_TDMODE          =       $2 ; DMA Transfer Information: 2D Mode
DMA_WAIT_RESP       =       $8 ; DMA Transfer Information: Wait for a Write Response
DMA_DEST_INC        =      $10 ; DMA Transfer Information: Destination Address Increment
DMA_DEST_WIDTH      =      $20 ; DMA Transfer Information: Destination Transfer Width
DMA_DEST_DREQ       =      $40 ; DMA Transfer Information: Control Destination Writes with DREQ
DMA_DEST_IGNORE     =      $80 ; DMA Transfer Information: Ignore Writes
DMA_SRC_INC         =     $100 ; DMA Transfer Information: Source Address Increment
DMA_SRC_WIDTH       =     $200 ; DMA Transfer Information: Source Transfer Width
DMA_SRC_DREQ        =     $400 ; DMA Transfer Information: Control Source Reads with DREQ
DMA_SRC_IGNORE      =     $800 ; DMA Transfer Information: Ignore Reads
DMA_BURST_LENGTH_1  =       $0 ; DMA Transfer Information: Burst Transfer Length 1 Word
DMA_BURST_LENGTH_2  =    $1000 ; DMA Transfer Information: Burst Transfer Length 2 Words
DMA_BURST_LENGTH_3  =    $2000 ; DMA Transfer Information: Burst Transfer Length 3 Words
DMA_BURST_LENGTH_4  =    $3000 ; DMA Transfer Information: Burst Transfer Length 4 Words
DMA_BURST_LENGTH_5  =    $4000 ; DMA Transfer Information: Burst Transfer Length 5 Words
DMA_BURST_LENGTH_6  =    $5000 ; DMA Transfer Information: Burst Transfer Length 6 Words
DMA_BURST_LENGTH_7  =    $6000 ; DMA Transfer Information: Burst Transfer Length 7 Words
DMA_BURST_LENGTH_8  =    $7000 ; DMA Transfer Information: Burst Transfer Length 8 Words
DMA_BURST_LENGTH_9  =    $8000 ; DMA Transfer Information: Burst Transfer Length 9 Words
DMA_BURST_LENGTH_10 =    $9000 ; DMA Transfer Information: Burst Transfer Length 10 Words
DMA_BURST_LENGTH_11 =    $A000 ; DMA Transfer Information: Burst Transfer Length 11 Words
DMA_BURST_LENGTH_12 =    $B000 ; DMA Transfer Information: Burst Transfer Length 12 Words
DMA_BURST_LENGTH_13 =    $C000 ; DMA Transfer Information: Burst Transfer Length 13 Words
DMA_BURST_LENGTH_14 =    $D000 ; DMA Transfer Information: Burst Transfer Length 14 Words
DMA_BURST_LENGTH_15 =    $E000 ; DMA Transfer Information: Burst Transfer Length 15 Words
DMA_BURST_LENGTH_16 =    $F000 ; DMA Transfer Information: Burst Transfer Length 16 Words
DMA_BURST_LENGTH    =    $F000 ; DMA Transfer Information: Burst Transfer Length
DMA_PERMAP_0        =       $0 ; DMA Transfer Information: Peripheral Mapping Continuous Un-paced Transfer
DMA_PERMAP_1        =   $10000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 1
DMA_PERMAP_2        =   $20000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 2
DMA_PERMAP_3        =   $30000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 3
DMA_PERMAP_4        =   $40000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 4
DMA_PERMAP_5        =   $50000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 5
DMA_PERMAP_6        =   $60000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 6
DMA_PERMAP_7        =   $70000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 7
DMA_PERMAP_8        =   $80000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 8
DMA_PERMAP_9        =   $90000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 9
DMA_PERMAP_10       =   $A0000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 10
DMA_PERMAP_11       =   $B0000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 11
DMA_PERMAP_12       =   $C0000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 12
DMA_PERMAP_13       =   $D0000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 13
DMA_PERMAP_14       =   $E0000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 14
DMA_PERMAP_15       =   $F0000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 15
DMA_PERMAP_16       =  $100000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 16
DMA_PERMAP_17       =  $110000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 17
DMA_PERMAP_18       =  $120000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 18
DMA_PERMAP_19       =  $130000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 19
DMA_PERMAP_20       =  $140000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 20
DMA_PERMAP_21       =  $150000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 21
DMA_PERMAP_22       =  $160000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 22
DMA_PERMAP_23       =  $170000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 23
DMA_PERMAP_24       =  $180000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 24
DMA_PERMAP_25       =  $190000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 25
DMA_PERMAP_26       =  $1A0000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 26
DMA_PERMAP_27       =  $1B0000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 27
DMA_PERMAP_28       =  $1C0000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 28
DMA_PERMAP_29       =  $1D0000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 29
DMA_PERMAP_30       =  $1E0000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 30
DMA_PERMAP_31       =  $1F0000 ; DMA Transfer Information: Peripheral Mapping Peripheral Number 31
DMA_PERMAP          =  $1F0000 ; DMA Transfer Information: Peripheral Mapping
DMA_WAITS_0         =       $0 ; DMA Transfer Information: Add No Wait Cycles
DMA_WAITS_1         =  $200000 ; DMA Transfer Information: Add 1 Wait Cycle
DMA_WAITS_2         =  $400000 ; DMA Transfer Information: Add 2 Wait Cycles
DMA_WAITS_3         =  $600000 ; DMA Transfer Information: Add 3 Wait Cycles
DMA_WAITS_4         =  $800000 ; DMA Transfer Information: Add 4 Wait Cycles
DMA_WAITS_5         =  $A00000 ; DMA Transfer Information: Add 5 Wait Cycles
DMA_WAITS_6         =  $C00000 ; DMA Transfer Information: Add 6 Wait Cycles
DMA_WAITS_7         =  $E00000 ; DMA Transfer Information: Add 7 Wait Cycles
DMA_WAITS_8         = $1000000 ; DMA Transfer Information: Add 8 Wait Cycles
DMA_WAITS_9         = $1200000 ; DMA Transfer Information: Add 9 Wait Cycles
DMA_WAITS_10        = $1400000 ; DMA Transfer Information: Add 10 Wait Cycles
DMA_WAITS_11        = $1600000 ; DMA Transfer Information: Add 11 Wait Cycles
DMA_WAITS_12        = $1800000 ; DMA Transfer Information: Add 12 Wait Cycles
DMA_WAITS_13        = $1A00000 ; DMA Transfer Information: Add 13 Wait Cycles
DMA_WAITS_14        = $1C00000 ; DMA Transfer Information: Add 14 Wait Cycles
DMA_WAITS_15        = $1E00000 ; DMA Transfer Information: Add 15 Wait Cycles
DMA_WAITS_16        = $2000000 ; DMA Transfer Information: Add 16 Wait Cycles
DMA_WAITS_17        = $2200000 ; DMA Transfer Information: Add 17 Wait Cycles
DMA_WAITS_18        = $2400000 ; DMA Transfer Information: Add 18 Wait Cycles
DMA_WAITS_19        = $2600000 ; DMA Transfer Information: Add 19 Wait Cycles
DMA_WAITS_20        = $2800000 ; DMA Transfer Information: Add 20 Wait Cycles
DMA_WAITS_21        = $2A00000 ; DMA Transfer Information: Add 21 Wait Cycles
DMA_WAITS_22        = $2C00000 ; DMA Transfer Information: Add 22 Wait Cycles
DMA_WAITS_23        = $2E00000 ; DMA Transfer Information: Add 23 Wait Cycles
DMA_WAITS_24        = $3000000 ; DMA Transfer Information: Add 24 Wait Cycles
DMA_WAITS_25        = $3200000 ; DMA Transfer Information: Add 25 Wait Cycles
DMA_WAITS_26        = $3400000 ; DMA Transfer Information: Add 26 Wait Cycles
DMA_WAITS_27        = $3600000 ; DMA Transfer Information: Add 27 Wait Cycles
DMA_WAITS_28        = $3800000 ; DMA Transfer Information: Add 28 Wait Cycles
DMA_WAITS_29        = $3A00000 ; DMA Transfer Information: Add 29 Wait Cycles
DMA_WAITS_30        = $3C00000 ; DMA Transfer Information: Add 30 Wait Cycles
DMA_WAITS_31        = $3E00000 ; DMA Transfer Information: Add 31 Wait Cycles
DMA_WAITS           = $3E00000 ; DMA Transfer Information: Add Wait Cycles
DMA_NO_WIDE_BURSTS  = $4000000 ; DMA Transfer Information: Don't Do Wide Writes as a 2 Beat Burst

DMA_XLENGTH =     $FFFF ; DMA Transfer Length: Transfer Length in Bytes
DMA_YLENGTH = $3FFF0000 ; DMA Transfer Length: When in 2D Mode, This is the Y Transfer Length

DMA_S_STRIDE =     $FFFF ; DMA 2D Stride: Source Stride (2D Mode)
DMA_D_STRIDE = $FFFF0000 ; DMA 2D Stride: Destination Stride (2D Mode)

DMA_READ_LAST_NOT_SET_ERROR =        $1 ; DMA Debug: Read Last Not Set Error
DMA_FIFO_ERROR              =        $2 ; DMA Debug: Fifo Error
DMA_READ_ERROR              =        $4 ; DMA Debug: Slave Read Response Error
DMA_OUTSTANDING_WRITES      =       $F0 ; DMA Debug: DMA Outstanding Writes Counter
DMA_ID                      =     $FF00 ; DMA Debug: DMA ID
DMA_STATE                   =  $1FF0000 ; DMA Debug: DMA State Machine State
DMA_VERSION                 =  $E000000 ; DMA Debug: DMA Version
DMA_LITE                    = $10000000 ; DMA Debug: DMA Lite

DMA_INT0  =    $1 ; DMA Interrupt Status: Interrupt Status of DMA Engine 0
DMA_INT1  =    $2 ; DMA Interrupt Status: Interrupt Status of DMA Engine 1
DMA_INT2  =    $4 ; DMA Interrupt Status: Interrupt Status of DMA Engine 2
DMA_INT3  =    $8 ; DMA Interrupt Status: Interrupt Status of DMA Engine 3
DMA_INT4  =   $10 ; DMA Interrupt Status: Interrupt Status of DMA Engine 4
DMA_INT5  =   $20 ; DMA Interrupt Status: Interrupt Status of DMA Engine 5
DMA_INT6  =   $40 ; DMA Interrupt Status: Interrupt Status of DMA Engine 6
DMA_INT7  =   $80 ; DMA Interrupt Status: Interrupt Status of DMA Engine 7
DMA_INT8  =  $100 ; DMA Interrupt Status: Interrupt Status of DMA Engine 8
DMA_INT9  =  $200 ; DMA Interrupt Status: Interrupt Status of DMA Engine 9
DMA_INT10 =  $400 ; DMA Interrupt Status: Interrupt Status of DMA Engine 10
DMA_INT11 =  $800 ; DMA Interrupt Status: Interrupt Status of DMA Engine 11
DMA_INT12 = $1000 ; DMA Interrupt Status: Interrupt Status of DMA Engine 12
DMA_INT13 = $2000 ; DMA Interrupt Status: Interrupt Status of DMA Engine 13
DMA_INT14 = $4000 ; DMA Interrupt Status: Interrupt Status of DMA Engine 14
DMA_INT15 = $8000 ; DMA Interrupt Status: Interrupt Status of DMA Engine 15

DMA_EN0  =    $1 ; DMA Enable: Enable DMA Engine 0
DMA_EN1  =    $2 ; DMA Enable: Enable DMA Engine 1
DMA_EN2  =    $4 ; DMA Enable: Enable DMA Engine 2
DMA_EN3  =    $8 ; DMA Enable: Enable DMA Engine 3
DMA_EN4  =   $10 ; DMA Enable: Enable DMA Engine 4
DMA_EN5  =   $20 ; DMA Enable: Enable DMA Engine 5
DMA_EN6  =   $40 ; DMA Enable: Enable DMA Engine 6
DMA_EN7  =   $80 ; DMA Enable: Enable DMA Engine 7
DMA_EN8  =  $100 ; DMA Enable: Enable DMA Engine 8
DMA_EN9  =  $200 ; DMA Enable: Enable DMA Engine 9
DMA_EN10 =  $400 ; DMA Enable: Enable DMA Engine 10
DMA_EN11 =  $800 ; DMA Enable: Enable DMA Engine 11
DMA_EN12 = $1000 ; DMA Enable: Enable DMA Engine 12
DMA_EN13 = $2000 ; DMA Enable: Enable DMA Engine 13
DMA_EN14 = $4000 ; DMA Enable: Enable DMA Engine 14

; GPIO
GPIO_BASE      = $200000 ; GPIO Base Address
GPIO_GPFSEL0   =      $0 ; GPIO Function Select 0
GPIO_GPFSEL1   =      $4 ; GPIO Function Select 1
GPIO_GPFSEL2   =      $8 ; GPIO Function Select 2
GPIO_GPFSEL3   =      $C ; GPIO Function Select 3
GPIO_GPFSEL4   =     $10 ; GPIO Function Select 4
GPIO_GPFSEL5   =     $14 ; GPIO Function Select 5
GPIO_GPSET0    =     $1C ; GPIO Pin Output Set 0
GPIO_GPSET1    =     $20 ; GPIO Pin Output Set 1
GPIO_GPCLR0    =     $28 ; GPIO Pin Output Clear 0
GPIO_GPCLR1    =     $2C ; GPIO Pin Output Clear 1
GPIO_GPLEV0    =     $34 ; GPIO Pin Level 0
GPIO_GPLEV1    =     $38 ; GPIO Pin Level 1
GPIO_GPEDS0    =     $40 ; GPIO Pin Event Detect Status 0
GPIO_GPEDS1    =     $44 ; GPIO Pin Event Detect Status 1
GPIO_GPREN0    =     $4C ; GPIO Pin Rising Edge Detect Enable 0
GPIO_GPREN1    =     $50 ; GPIO Pin Rising Edge Detect Enable 1
GPIO_GPFEN0    =     $58 ; GPIO Pin Falling Edge Detect Enable 0
GPIO_GPFEN1    =     $5C ; GPIO Pin Falling Edge Detect Enable 1
GPIO_GPHEN0    =     $64 ; GPIO Pin High Detect Enable 0
GPIO_GPHEN1    =     $68 ; GPIO Pin High Detect Enable 1
GPIO_GPLEN0    =     $70 ; GPIO Pin Low Detect Enable 0
GPIO_GPLEN1    =     $74 ; GPIO Pin Low Detect Enable 1
GPIO_GPAREN0   =     $7C ; GPIO Pin Async. Rising Edge Detect 0
GPIO_GPAREN1   =     $80 ; GPIO Pin Async. Rising Edge Detect 1
GPIO_GPAFEN0   =     $88 ; GPIO Pin Async. Falling Edge Detect 0
GPIO_GPAFEN1   =     $8C ; GPIO Pin Async. Falling Edge Detect 1
GPIO_GPPUD     =     $94 ; GPIO Pin Pull-up/down Enable
GPIO_GPPUDCLK0 =     $98 ; GPIO Pin Pull-up/down Enable Clock 0
GPIO_GPPUDCLK1 =     $9C ; GPIO Pin Pull-up/down Enable Clock 1
GPIO_TEST      =     $B0 ; GPIO Test

GPIO_FSEL0_IN   = $0 ; GPIO Function Select: GPIO Pin X0 Is An Input
GPIO_FSEL0_OUT  = $1 ; GPIO Function Select: GPIO Pin X0 Is An Output
GPIO_FSEL0_ALT0 = $4 ; GPIO Function Select: GPIO Pin X0 Takes Alternate Function 0
GPIO_FSEL0_ALT1 = $5 ; GPIO Function Select: GPIO Pin X0 Takes Alternate Function 1
GPIO_FSEL0_ALT2 = $6 ; GPIO Function Select: GPIO Pin X0 Takes Alternate Function 2
GPIO_FSEL0_ALT3 = $7 ; GPIO Function Select: GPIO Pin X0 Takes Alternate Function 3
GPIO_FSEL0_ALT4 = $3 ; GPIO Function Select: GPIO Pin X0 Takes Alternate Function 4
GPIO_FSEL0_ALT5 = $2 ; GPIO Function Select: GPIO Pin X0 Takes Alternate Function 5
GPIO_FSEL0_CLR  = $7 ; GPIO Function Select: GPIO Pin X0 Clear Bits

GPIO_FSEL1_IN   =  $0 ; GPIO Function Select: GPIO Pin X1 Is An Input
GPIO_FSEL1_OUT  =  $8 ; GPIO Function Select: GPIO Pin X1 Is An Output
GPIO_FSEL1_ALT0 = $20 ; GPIO Function Select: GPIO Pin X1 Takes Alternate Function 0
GPIO_FSEL1_ALT1 = $28 ; GPIO Function Select: GPIO Pin X1 Takes Alternate Function 1
GPIO_FSEL1_ALT2 = $30 ; GPIO Function Select: GPIO Pin X1 Takes Alternate Function 2
GPIO_FSEL1_ALT3 = $38 ; GPIO Function Select: GPIO Pin X1 Takes Alternate Function 3
GPIO_FSEL1_ALT4 = $18 ; GPIO Function Select: GPIO Pin X1 Takes Alternate Function 4
GPIO_FSEL1_ALT5 = $10 ; GPIO Function Select: GPIO Pin X1 Takes Alternate Function 5
GPIO_FSEL1_CLR  = $38 ; GPIO Function Select: GPIO Pin X1 Clear Bits

GPIO_FSEL2_IN   =   $0 ; GPIO Function Select: GPIO Pin X2 Is An Input
GPIO_FSEL2_OUT  =  $40 ; GPIO Function Select: GPIO Pin X2 Is An Output
GPIO_FSEL2_ALT0 = $100 ; GPIO Function Select: GPIO Pin X2 Takes Alternate Function 0
GPIO_FSEL2_ALT1 = $140 ; GPIO Function Select: GPIO Pin X2 Takes Alternate Function 1
GPIO_FSEL2_ALT2 = $180 ; GPIO Function Select: GPIO Pin X2 Takes Alternate Function 2
GPIO_FSEL2_ALT3 = $1C0 ; GPIO Function Select: GPIO Pin X2 Takes Alternate Function 3
GPIO_FSEL2_ALT4 =  $C0 ; GPIO Function Select: GPIO Pin X2 Takes Alternate Function 4
GPIO_FSEL2_ALT5 =  $80 ; GPIO Function Select: GPIO Pin X2 Takes Alternate Function 5
GPIO_FSEL2_CLR  = $1C0 ; GPIO Function Select: GPIO Pin X2 Clear Bits

GPIO_FSEL3_IN   =   $0 ; GPIO Function Select: GPIO Pin X3 Is An Input
GPIO_FSEL3_OUT  = $200 ; GPIO Function Select: GPIO Pin X3 Is An Output
GPIO_FSEL3_ALT0 = $800 ; GPIO Function Select: GPIO Pin X3 Takes Alternate Function 0
GPIO_FSEL3_ALT1 = $A00 ; GPIO Function Select: GPIO Pin X3 Takes Alternate Function 1
GPIO_FSEL3_ALT2 = $C00 ; GPIO Function Select: GPIO Pin X3 Takes Alternate Function 2
GPIO_FSEL3_ALT3 = $E00 ; GPIO Function Select: GPIO Pin X3 Takes Alternate Function 3
GPIO_FSEL3_ALT4 = $600 ; GPIO Function Select: GPIO Pin X3 Takes Alternate Function 4
GPIO_FSEL3_ALT5 = $400 ; GPIO Function Select: GPIO Pin X3 Takes Alternate Function 5
GPIO_FSEL3_CLR  = $E00 ; GPIO Function Select: GPIO Pin X3 Clear Bits

GPIO_FSEL4_IN   =    $0 ; GPIO Function Select: GPIO Pin X4 Is An Input
GPIO_FSEL4_OUT  = $1000 ; GPIO Function Select: GPIO Pin X4 Is An Output
GPIO_FSEL4_ALT0 = $4000 ; GPIO Function Select: GPIO Pin X4 Takes Alternate Function 0
GPIO_FSEL4_ALT1 = $5000 ; GPIO Function Select: GPIO Pin X4 Takes Alternate Function 1
GPIO_FSEL4_ALT2 = $6000 ; GPIO Function Select: GPIO Pin X4 Takes Alternate Function 2
GPIO_FSEL4_ALT3 = $7000 ; GPIO Function Select: GPIO Pin X4 Takes Alternate Function 3
GPIO_FSEL4_ALT4 = $3000 ; GPIO Function Select: GPIO Pin X4 Takes Alternate Function 4
GPIO_FSEL4_ALT5 = $2000 ; GPIO Function Select: GPIO Pin X4 Takes Alternate Function 5
GPIO_FSEL4_CLR  = $7000 ; GPIO Function Select: GPIO Pin X4 Clear Bits

GPIO_FSEL5_IN   =     $0 ; GPIO Function Select: GPIO Pin X5 Is An Input
GPIO_FSEL5_OUT  =  $8000 ; GPIO Function Select: GPIO Pin X5 Is An Output
GPIO_FSEL5_ALT0 = $20000 ; GPIO Function Select: GPIO Pin X5 Takes Alternate Function 0
GPIO_FSEL5_ALT1 = $28000 ; GPIO Function Select: GPIO Pin X5 Takes Alternate Function 1
GPIO_FSEL5_ALT2 = $30000 ; GPIO Function Select: GPIO Pin X5 Takes Alternate Function 2
GPIO_FSEL5_ALT3 = $38000 ; GPIO Function Select: GPIO Pin X5 Takes Alternate Function 3
GPIO_FSEL5_ALT4 = $18000 ; GPIO Function Select: GPIO Pin X5 Takes Alternate Function 4
GPIO_FSEL5_ALT5 = $10000 ; GPIO Function Select: GPIO Pin X5 Takes Alternate Function 5
GPIO_FSEL5_CLR  = $38000 ; GPIO Function Select: GPIO Pin X5 Clear Bits

GPIO_FSEL6_IN   =      $0 ; GPIO Function Select: GPIO Pin X6 Is An Input
GPIO_FSEL6_OUT  =  $40000 ; GPIO Function Select: GPIO Pin X6 Is An Output
GPIO_FSEL6_ALT0 = $100000 ; GPIO Function Select: GPIO Pin X6 Takes Alternate Function 0
GPIO_FSEL6_ALT1 = $140000 ; GPIO Function Select: GPIO Pin X6 Takes Alternate Function 1
GPIO_FSEL6_ALT2 = $180000 ; GPIO Function Select: GPIO Pin X6 Takes Alternate Function 2
GPIO_FSEL6_ALT3 = $1C0000 ; GPIO Function Select: GPIO Pin X6 Takes Alternate Function 3
GPIO_FSEL6_ALT4 =  $C0000 ; GPIO Function Select: GPIO Pin X6 Takes Alternate Function 4
GPIO_FSEL6_ALT5 =  $80000 ; GPIO Function Select: GPIO Pin X6 Takes Alternate Function 5
GPIO_FSEL6_CLR  = $1C0000 ; GPIO Function Select: GPIO Pin X6 Clear Bits

GPIO_FSEL7_IN   =      $0 ; GPIO Function Select: GPIO Pin X7 Is An Input
GPIO_FSEL7_OUT  = $200000 ; GPIO Function Select: GPIO Pin X7 Is An Output
GPIO_FSEL7_ALT0 = $800000 ; GPIO Function Select: GPIO Pin X7 Takes Alternate Function 0
GPIO_FSEL7_ALT1 = $A00000 ; GPIO Function Select: GPIO Pin X7 Takes Alternate Function 1
GPIO_FSEL7_ALT2 = $C00000 ; GPIO Function Select: GPIO Pin X7 Takes Alternate Function 2
GPIO_FSEL7_ALT3 = $E00000 ; GPIO Function Select: GPIO Pin X7 Takes Alternate Function 3
GPIO_FSEL7_ALT4 = $600000 ; GPIO Function Select: GPIO Pin X7 Takes Alternate Function 4
GPIO_FSEL7_ALT5 = $400000 ; GPIO Function Select: GPIO Pin X7 Takes Alternate Function 5
GPIO_FSEL7_CLR  = $E00000 ; GPIO Function Select: GPIO Pin X7 Clear Bits

GPIO_FSEL8_IN   =       $0 ; GPIO Function Select: GPIO Pin X8 Is An Input
GPIO_FSEL8_OUT  = $1000000 ; GPIO Function Select: GPIO Pin X8 Is An Output
GPIO_FSEL8_ALT0 = $4000000 ; GPIO Function Select: GPIO Pin X8 Takes Alternate Function 0
GPIO_FSEL8_ALT1 = $5000000 ; GPIO Function Select: GPIO Pin X8 Takes Alternate Function 1
GPIO_FSEL8_ALT2 = $6000000 ; GPIO Function Select: GPIO Pin X8 Takes Alternate Function 2
GPIO_FSEL8_ALT3 = $7000000 ; GPIO Function Select: GPIO Pin X8 Takes Alternate Function 3
GPIO_FSEL8_ALT4 = $3000000 ; GPIO Function Select: GPIO Pin X8 Takes Alternate Function 4
GPIO_FSEL8_ALT5 = $2000000 ; GPIO Function Select: GPIO Pin X8 Takes Alternate Function 5
GPIO_FSEL8_CLR  = $7000000 ; GPIO Function Select: GPIO Pin X8 Clear Bits

GPIO_FSEL9_IN   =        $0 ; GPIO Function Select: GPIO Pin X9 Is An Input
GPIO_FSEL9_OUT  =  $8000000 ; GPIO Function Select: GPIO Pin X9 Is An Output
GPIO_FSEL9_ALT0 = $20000000 ; GPIO Function Select: GPIO Pin X9 Takes Alternate Function 0
GPIO_FSEL9_ALT1 = $28000000 ; GPIO Function Select: GPIO Pin X9 Takes Alternate Function 1
GPIO_FSEL9_ALT2 = $30000000 ; GPIO Function Select: GPIO Pin X9 Takes Alternate Function 2
GPIO_FSEL9_ALT3 = $38000000 ; GPIO Function Select: GPIO Pin X9 Takes Alternate Function 3
GPIO_FSEL9_ALT4 = $18000000 ; GPIO Function Select: GPIO Pin X9 Takes Alternate Function 4
GPIO_FSEL9_ALT5 = $10000000 ; GPIO Function Select: GPIO Pin X9 Takes Alternate Function 5
GPIO_FSEL9_CLR  = $38000000 ; GPIO Function Select: GPIO Pin X9 Clear Bits

GPIO_0  =        $1 ; GPIO Pin 0: 0
GPIO_1  =        $2 ; GPIO Pin 0: 1
GPIO_2  =        $4 ; GPIO Pin 0: 2
GPIO_3  =        $8 ; GPIO Pin 0: 3
GPIO_4  =       $10 ; GPIO Pin 0: 4
GPIO_5  =       $20 ; GPIO Pin 0: 5
GPIO_6  =       $40 ; GPIO Pin 0: 6
GPIO_7  =       $80 ; GPIO Pin 0: 7
GPIO_8  =      $100 ; GPIO Pin 0: 8
GPIO_9  =      $200 ; GPIO Pin 0: 9
GPIO_10 =      $400 ; GPIO Pin 0: 10
GPIO_11 =      $800 ; GPIO Pin 0: 11
GPIO_12 =     $1000 ; GPIO Pin 0: 12
GPIO_13 =     $2000 ; GPIO Pin 0: 13
GPIO_14 =     $4000 ; GPIO Pin 0: 14
GPIO_15 =     $8000 ; GPIO Pin 0: 15
GPIO_16 =    $10000 ; GPIO Pin 0: 16
GPIO_17 =    $20000 ; GPIO Pin 0: 17
GPIO_18 =    $40000 ; GPIO Pin 0: 18
GPIO_19 =    $80000 ; GPIO Pin 0: 19
GPIO_20 =   $100000 ; GPIO Pin 0: 20
GPIO_21 =   $200000 ; GPIO Pin 0: 21
GPIO_22 =   $400000 ; GPIO Pin 0: 22
GPIO_23 =   $800000 ; GPIO Pin 0: 23
GPIO_24 =  $1000000 ; GPIO Pin 0: 24
GPIO_25 =  $2000000 ; GPIO Pin 0: 25
GPIO_26 =  $4000000 ; GPIO Pin 0: 26
GPIO_27 =  $8000000 ; GPIO Pin 0: 27
GPIO_28 = $10000000 ; GPIO Pin 0: 28
GPIO_29 = $20000000 ; GPIO Pin 0: 29
GPIO_30 = $40000000 ; GPIO Pin 0: 30
GPIO_31 = $80000000 ; GPIO Pin 0: 31

GPIO_32 =        $1 ; GPIO Pin 1: 32
GPIO_33 =        $2 ; GPIO Pin 1: 33
GPIO_34 =        $4 ; GPIO Pin 1: 34
GPIO_35 =        $8 ; GPIO Pin 1: 35
GPIO_36 =       $10 ; GPIO Pin 1: 36
GPIO_37 =       $20 ; GPIO Pin 1: 37
GPIO_38 =       $40 ; GPIO Pin 1: 38
GPIO_39 =       $80 ; GPIO Pin 1: 39
GPIO_40 =      $100 ; GPIO Pin 1: 40
GPIO_41 =      $200 ; GPIO Pin 1: 41
GPIO_42 =      $400 ; GPIO Pin 1: 42
GPIO_43 =      $800 ; GPIO Pin 1: 43
GPIO_44 =     $1000 ; GPIO Pin 1: 44
GPIO_45 =     $2000 ; GPIO Pin 1: 45
GPIO_46 =     $4000 ; GPIO Pin 1: 46
GPIO_47 =     $8000 ; GPIO Pin 1: 47
GPIO_48 =    $10000 ; GPIO Pin 1: 48
GPIO_49 =    $20000 ; GPIO Pin 1: 49
GPIO_50 =    $40000 ; GPIO Pin 1: 50
GPIO_51 =    $80000 ; GPIO Pin 1: 51
GPIO_52 =   $100000 ; GPIO Pin 1: 52
GPIO_53 =   $200000 ; GPIO Pin 1: 53

; PCM / I2S Audio Interface
PCM_BASE     = $203000 ; PCM Base Address
PCM_CS_A     =      $0 ; PCM Control & Status
PCM_FIFO_A   =      $4 ; PCM FIFO Data
PCM_MODE_A   =      $8 ; PCM Mode
PCM_RXC_A    =      $C ; PCM Receive Configuration
PCM_TXC_A    =     $10 ; PCM Transmit Configuration
PCM_DREQ_A   =     $14 ; PCM DMA Request Level
PCM_INTEN_A  =     $18 ; PCM Interrupt Enables
PCM_INTSTC_A =     $1C ; PCM Interrupt Status & Clear
PCM_GRAY     =     $20 ; PCM Gray Mode Control

PCM_EN      =       $1 ; PCM Control & Status: Enable the PCM Audio Interface
PCM_RXON    =       $2 ; PCM Control & Status: Enable Reception
PCM_TXON    =       $4 ; PCM Control & Status: Enable Transmission
PCM_TXCLR   =       $8 ; PCM Control & Status: Clear the TX FIFO
PCM_RXCLR   =      $10 ; PCM Control & Status: Clear the RX FIFO
PCM_TXTHR_0 =       $0 ; PCM Control & Status: Sets the TX FIFO Threshold at which point the TXW flag is Set when the TX FIFO is Empty
PCM_TXTHR_1 =      $20 ; PCM Control & Status: Sets the TX FIFO Threshold at which point the TXW flag is Set when the TX FIFO is less than Full
PCM_TXTHR_2 =      $40 ; PCM Control & Status: Sets the TX FIFO Threshold at which point the TXW flag is Set when the TX FIFO is less than Full
PCM_TXTHR_3 =      $60 ; PCM Control & Status: Sets the TX FIFO Threshold at which point the TXW flag is Set when the TX FIFO is Full but for one Sample
PCM_TXTHR   =      $60 ; PCM Control & Status: Sets the TX FIFO Threshold at which point the TXW flag is Set
PCM_RXTHR_0 =       $0 ; PCM Control & Status: Sets the RX FIFO Threshold at which point the RXR flag is Set when we have a single Sample in the RX FIFO
PCM_RXTHR_1 =      $80 ; PCM Control & Status: Sets the RX FIFO Threshold at which point the RXR flag is Set when the RX FIFO is at least Full
PCM_RXTHR_2 =     $100 ; PCM Control & Status: Sets the RX FIFO Threshold at which point the RXR flag is Set when the RX FIFO is at least Full
PCM_RXTHR_3 =     $180 ; PCM Control & Status: Sets the RX FIFO Threshold at which point the RXR flag is Set when the RX FIFO is Full
PCM_RXTHR   =     $180 ; PCM Control & Status: Sets the RX FIFO Threshold at which point the RXR flag is Set
PCM_DMAEN   =     $200 ; PCM Control & Status: DMA DREQ Enable
PCM_TXSYNC  =    $2000 ; PCM Control & Status: TX FIFO Sync
PCM_RXSYNC  =    $4000 ; PCM Control & Status: RX FIFO Sync
PCM_TXERR   =    $8000 ; PCM Control & Status: TX FIFO Error
PCM_RXERR   =   $10000 ; PCM Control & Status: RX FIFO Error
PCM_TXW     =   $20000 ; PCM Control & Status: Indicates that the TX FIFO needs Writing
PCM_RXR     =   $40000 ; PCM Control & Status: Indicates that the RX FIFO needs Reading
PCM_TXD     =   $80000 ; PCM Control & Status: Indicates that the TX FIFO can accept Data
PCM_RXD     =  $100000 ; PCM Control & Status: Indicates that the RX FIFO contains Data
PCM_TXE     =  $200000 ; PCM Control & Status: TX FIFO is Empty
PCM_RXF     =  $400000 ; PCM Control & Status: RX FIFO is Full
PCM_RXSEX   =  $800000 ; PCM Control & Status: RX Sign Extend
PCM_SYNC    = $1000000 ; PCM Control & Status: PCM Clock Sync helper
PCM_STBY    = $2000000 ; PCM Control & Status: RAM Standby

PSM_FSLEN   =      $3FF ; PCM Mode: Frame Sync Length
PSM_FLEN    =    $FFC00 ; PCM Mode: Frame Length
PCM_FSI     =   $100000 ; PCM Mode: Frame Sync Invert this logically inverts the Frame Sync Signal
PCM_FSM     =   $200000 ; PCM Mode: Frame Sync Mode
PCM_CLKI    =   $400000 ; PCM Mode: Clock Invert this logically inverts the PCM_CLK Signal
PCM_CLKM    =   $800000 ; PCM Mode: PCM Clock Mode
PCM_FTXP    =  $1000000 ; PCM Mode: Transmit Frame Packed Mode
PCM_FRXP    =  $2000000 ; PCM Mode: Receive Frame Packed Mode
PCM_PDME    =  $4000000 ; PCM Mode: PDM Input Mode Enable
PCM_PDMN    =  $8000000 ; PCM Mode: PDM Decimation Factor (N)
PCM_CLK_DIS = $10000000 ; PCM Mode: PCM Clock Disable

PCM_CH2WID_8  =        $0 ; PCM Receive & Transmit Configuration: Channel 2 Width 8 bits Wide
PCM_CH2WID_9  =        $1 ; PCM Receive & Transmit Configuration: Channel 2 Width 9 bits Wide
PCM_CH2WID_10 =        $2 ; PCM Receive & Transmit Configuration: Channel 2 Width 10 bits Wide
PCM_CH2WID_11 =        $3 ; PCM Receive & Transmit Configuration: Channel 2 Width 11 bits Wide
PCM_CH2WID_12 =        $4 ; PCM Receive & Transmit Configuration: Channel 2 Width 12 bits Wide
PCM_CH2WID_13 =        $5 ; PCM Receive & Transmit Configuration: Channel 2 Width 13 bits Wide
PCM_CH2WID_14 =        $6 ; PCM Receive & Transmit Configuration: Channel 2 Width 14 bits Wide
PCM_CH2WID_15 =        $7 ; PCM Receive & Transmit Configuration: Channel 2 Width 15 bits Wide
PCM_CH2WID_16 =        $8 ; PCM Receive & Transmit Configuration: Channel 2 Width 16 bits Wide
PCM_CH2WID_17 =        $9 ; PCM Receive & Transmit Configuration: Channel 2 Width 17 bits Wide
PCM_CH2WID_18 =        $A ; PCM Receive & Transmit Configuration: Channel 2 Width 18 bits Wide
PCM_CH2WID_19 =        $B ; PCM Receive & Transmit Configuration: Channel 2 Width 19 bits Wide
PCM_CH2WID_20 =        $C ; PCM Receive & Transmit Configuration: Channel 2 Width 20 bits Wide
PCM_CH2WID_21 =        $D ; PCM Receive & Transmit Configuration: Channel 2 Width 21 bits Wide
PCM_CH2WID_22 =        $E ; PCM Receive & Transmit Configuration: Channel 2 Width 22 bits Wide
PCM_CH2WID_23 =        $F ; PCM Receive & Transmit Configuration: Channel 2 Width 23 bits Wide
PCM_CH2WID    =        $F ; PCM Receive & Transmit Configuration: Channel 2 Width
PCM_CH2WID_24 =     $8000 ; PCM Receive & Transmit Configuration: Channel 2 Width 24 bits wide
PCM_CH2WID_25 =     $8001 ; PCM Receive & Transmit Configuration: Channel 2 Width 25 bits wide
PCM_CH2WID_26 =     $8002 ; PCM Receive & Transmit Configuration: Channel 2 Width 26 bits wide
PCM_CH2WID_27 =     $8003 ; PCM Receive & Transmit Configuration: Channel 2 Width 27 bits wide
PCM_CH2WID_28 =     $8004 ; PCM Receive & Transmit Configuration: Channel 2 Width 28 bits wide
PCM_CH2WID_29 =     $8005 ; PCM Receive & Transmit Configuration: Channel 2 Width 29 bits wide
PCM_CH2WID_30 =     $8006 ; PCM Receive & Transmit Configuration: Channel 2 Width 30 bits wide
PCM_CH2WID_31 =     $8007 ; PCM Receive & Transmit Configuration: Channel 2 Width 31 bits wide
PCM_CH2WID_32 =     $8008 ; PCM Receive & Transmit Configuration: Channel 2 Width 32 bits wide
PCM_CH2POS    =     $3FF0 ; PCM Receive & Transmit Configuration: Channel 2 Position
PCM_CH2EN     =     $4000 ; PCM Receive & Transmit Configuration: Channel 2 Enable
PCM_CH2WEX    =     $8000 ; PCM Receive & Transmit Configuration: Channel 2 Width Extension Bit
PCM_CH1WID_8  =        $0 ; PCM Receive & Transmit Configuration: Channel 1 Width 8 bits Wide
PCM_CH1WID_9  =    $10000 ; PCM Receive & Transmit Configuration: Channel 1 Width 9 bits Wide
PCM_CH1WID_10 =    $20000 ; PCM Receive & Transmit Configuration: Channel 1 Width 10 bits Wide
PCM_CH1WID_11 =    $30000 ; PCM Receive & Transmit Configuration: Channel 1 Width 11 bits Wide
PCM_CH1WID_12 =    $40000 ; PCM Receive & Transmit Configuration: Channel 1 Width 12 bits Wide
PCM_CH1WID_13 =    $50000 ; PCM Receive & Transmit Configuration: Channel 1 Width 13 bits Wide
PCM_CH1WID_14 =    $60000 ; PCM Receive & Transmit Configuration: Channel 1 Width 14 bits Wide
PCM_CH1WID_15 =    $70000 ; PCM Receive & Transmit Configuration: Channel 1 Width 15 bits Wide
PCM_CH1WID_16 =    $80000 ; PCM Receive & Transmit Configuration: Channel 1 Width 16 bits Wide
PCM_CH1WID_17 =    $90000 ; PCM Receive & Transmit Configuration: Channel 1 Width 17 bits Wide
PCM_CH1WID_18 =    $A0000 ; PCM Receive & Transmit Configuration: Channel 1 Width 18 bits Wide
PCM_CH1WID_19 =    $B0000 ; PCM Receive & Transmit Configuration: Channel 1 Width 19 bits Wide
PCM_CH1WID_20 =    $C0000 ; PCM Receive & Transmit Configuration: Channel 1 Width 20 bits Wide
PCM_CH1WID_21 =    $D0000 ; PCM Receive & Transmit Configuration: Channel 1 Width 21 bits Wide
PCM_CH1WID_22 =    $E0000 ; PCM Receive & Transmit Configuration: Channel 1 Width 22 bits Wide
PCM_CH1WID_23 =    $F0000 ; PCM Receive & Transmit Configuration: Channel 1 Width 23 bits Wide
PCM_CH1WID    =    $F0000 ; PCM Receive & Transmit Configuration: Channel 1 Width
PCM_CH1WID_24 = $80000000 ; PCM Receive & Transmit Configuration: Channel 1 Width 24 bits wide
PCM_CH1WID_25 = $80010000 ; PCM Receive & Transmit Configuration: Channel 1 Width 25 bits wide
PCM_CH1WID_26 = $80020000 ; PCM Receive & Transmit Configuration: Channel 1 Width 26 bits wide
PCM_CH1WID_27 = $80030000 ; PCM Receive & Transmit Configuration: Channel 1 Width 27 bits wide
PCM_CH1WID_28 = $80040000 ; PCM Receive & Transmit Configuration: Channel 1 Width 28 bits wide
PCM_CH1WID_29 = $80050000 ; PCM Receive & Transmit Configuration: Channel 1 Width 29 bits wide
PCM_CH1WID_30 = $80060000 ; PCM Receive & Transmit Configuration: Channel 1 Width 30 bits wide
PCM_CH1WID_31 = $80070000 ; PCM Receive & Transmit Configuration: Channel 1 Width 31 bits wide
PCM_CH1WID_32 = $80080000 ; PCM Receive & Transmit Configuration: Channel 1 Width 32 bits wide
PCM_CH1POS    = $3FF00000 ; PCM Receive & Transmit Configuration: Channel 1 Position
PCM_CH1EN     = $40000000 ; PCM Receive & Transmit Configuration: Channel 1 Enable
PCM_CH1WEX    = $80000000 ; PCM Receive & Transmit Configuration: Channel 1 Width Extension Bit

PCM_RX       =       $7F ; PCM DMA Request Level: RX Request Level
PCM_TX       =     $7F00 ; PCM DMA Request Level: TX Request Level
PCM_RX_PANIC =   $7F0000 ; PCM DMA Request Level: RX Panic Level
PCM_TX_PANIC = $7F000000 ; PCM DMA Request Level: TX Panic Level

PCM_TXW   = $1 ; PCM Interrupt Enables & Interrupt Status & Clear: TX Write Interrupt Enable
PCM_RXR   = $2 ; PCM Interrupt Enables & Interrupt Status & Clear: RX Read Interrupt Enable
PCM_TXERR = $4 ; PCM Interrupt Enables & Interrupt Status & Clear: TX Error Interrupt
PCM_RXERR = $8 ; PCM Interrupt Enables & Interrupt Status & Clear: RX Error Interrupt

PCM_GRAY_EN     =      $1 ; PCM Gray Mode Control: Enable GRAY Mode
PCM_GRAY_CLR    =      $2 ; PCM Gray Mode Control: Clear the GRAY Mode Logic
PCM_GRAY_FLUSH  =      $4 ; PCM Gray Mode Control: Flush the RX Buffer into the RX FIFO
PCM_RXLEVEL     =    $3F0 ; PCM Gray Mode Control: The Current Fill Level of the RX Buffer
PCM_FLUSHED     =   $FC00 ; PCM Gray Mode Control: The Number of Bits that were Flushed into the RX FIFO
PCM_RXFIFOLEVEL = $3F0000 ; PCM Gray Mode Control: The Current Level of the RX FIFO

; PWM / Pulse Width Modulator Interface
PWM_BASE = $20C000 ; PWM Base Address
PWM_CTL  =      $0 ; PWM Control
PWM_STA  =      $4 ; PWM Status
PWM_DMAC =      $8 ; PWM DMA Configuration
PWM_RNG1 =     $10 ; PWM Channel 1 Range
PWM_DAT1 =     $14 ; PWM Channel 1 Data
PWM_FIF1 =     $18 ; PWM FIFO Input
PWM_RNG2 =     $20 ; PWM Channel 2 Range
PWM_DAT2 =     $24 ; PWM Channel 2 Data

PWM_PWEN1 =    $1 ; PWM Control: Channel 1 Enable
PWM_MODE1 =    $2 ; PWM Control: Channel 1 Mode
PWM_RPTL1 =    $4 ; PWM Control: Channel 1 Repeat Last Data
PWM_SBIT1 =    $8 ; PWM Control: Channel 1 Silence Bit
PWM_POLA1 =   $10 ; PWM Control: Channel 1 Polarity
PWM_USEF1 =   $20 ; PWM Control: Channel 1 Use Fifo
PWM_CLRF1 =   $40 ; PWM Control: Clear Fifo
PWM_MSEN1 =   $80 ; PWM Control: Channel 1 M/S Enable
PWM_PWEN2 =  $100 ; PWM Control: Channel 2 Enable
PWM_MODE2 =  $200 ; PWM Control: Channel 2 Mode
PWM_RPTL2 =  $400 ; PWM Control: Channel 2 Repeat Last Data
PWM_SBIT2 =  $800 ; PWM Control: Channel 2 Silence Bit
PWM_POLA2 = $1000 ; PWM Control: Channel 2 Polarity
PWM_USEF2 = $2000 ; PWM Control: Channel 2 Use Fifo
PWM_MSEN2 = $8000 ; PWM Control: Channel 2 M/S Enable

PWM_FULL1 =    $1 ; PWM Status: Fifo Full Flag
PWM_EMPT1 =    $2 ; PWM Status: Fifo Empty Flag
PWM_WERR1 =    $4 ; PWM Status: Fifo Write Error Flag
PWM_RERR1 =    $8 ; PWM Status: Fifo Read Error Flag
PWM_GAPO1 =   $10 ; PWM Status: Channel 1 Gap Occurred Flag
PWM_GAPO2 =   $20 ; PWM Status: Channel 2 Gap Occurred Flag
PWM_GAPO3 =   $40 ; PWM Status: Channel 3 Gap Occurred Flag
PWM_GAPO4 =   $80 ; PWM Status: Channel 4 Gap Occurred Flag
PWM_BERR  =  $100 ; PWM Status: Bus Error Flag
PWM_STA1  =  $200 ; PWM Status: Channel 1 State
PWM_STA2  =  $400 ; PWM Status: Channel 2 State
PWM_STA3  =  $800 ; PWM Status: Channel 3 State
PWM_STA4  = $1000 ; PWM Status: Channel 4 State

PWM_ENAB = $80000000 ; PWM DMA Configuration: DMA Enable

; AUX interface
AUX_BASE        = $215000
AUX_ENABLES     = $4
AUX_MU_IO_REG   = $40
AUX_MU_IER_REG  = $44
AUX_MU_IIR_REG  = $48
AUX_MU_LCR_REG  = $4C
AUX_MU_MCR_REG  = $50
AUX_MU_LSR_REG  = $54
AUX_MU_MSR_REG  = $58
AUX_MU_SCRATCH  = $5C
AUX_MU_CNTL_REG = $60
AUX_MU_STAT_REG = $64
AUX_MU_BAUD_REG = $68

; ARM Timer
ARM_TIMER_CTL = $b408
ARM_TIMER_CNT = $b420

; System Timers
ARM_IO_BASE = $20000000
ARM_SYSTIMER_BASE = ARM_IO_BASE + $3000
ARM_SYSTIMER_CS   = ARM_SYSTIMER_BASE + $00
ARM_SYSTIMER_CLO  = ARM_SYSTIMER_BASE + $04
ARM_SYSTIMER_CHI  = ARM_SYSTIMER_BASE + $08
ARM_SYSTIMER_C0   = ARM_SYSTIMER_BASE + $0C
ARM_SYSTIMER_C1   = ARM_SYSTIMER_BASE + $10
ARM_SYSTIMER_C2   = ARM_SYSTIMER_BASE + $14
ARM_SYSTIMER_C3   = ARM_SYSTIMER_BASE + $18
