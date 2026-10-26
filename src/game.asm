; Controlls:
;   A-Button      =
;   B-Button      = 
;   UP Arrow      = 
;   DOWN Arrow    = 
;   LEFT Arrow    = 
;   RIGHT Arrow   = 
;   SELECT-Button =
;   START-Button  =

.segment "HEADER"
    .byte "NES", $1A           ; Identification bytes for an NES ROM
    .byte 2                    ; 2 PRG-ROM banks of 16 KB = 32 KB
    .byte 1                    ; 1 CHR-ROM bank of 8 KB = 8 KB
    .byte $00                  ; Mapper 0, horizontal mirroring
    .byte $00                  ; Other header settings
    .byte $00, $00, $00, $00   ; Unused header bytes
    .byte $00, $00, $00, $00   ; Additional reserved header bytes


.segment "ZEROPAGE"        
    buttons:          .res 1   ; New button input from current frame (A, B, Select, Start, Up, Down, Left, Right)
    old_buttons:      .res 1   ; Old button input from previous frame (A, B, Select, Start, Up, Down, Left, Right)
    selected_building: .res 1   ; Keeps track of the selected "building" (faactory, depo, area, belt,....)
    
    flags: .res 1
        PAUSED_FLAG    = %00000001  ; bit 0 = paused
        BUILD_FLAG     = %00000010  ; bit 1 = build mode
        SELECTING_FLAG = %00000100  ; bit 2 = selecting area
    

.segment "CODE"



reset:
    SEI             ; Disable CPU interrupts
    CLD             ; Disable decimal mode

    LDX #$40        ; Value to disable the APU-frame-IRQ (audio)
    STX $4017       ; Disable APU frame IRQ

    LDX #$FF        ; X = #$FF
    TXS             ; Initialize stack pointer

    INX             ; X = 0 (FF + 1 = 0 )
    STX $2000       ; Disable NMI
    STX $2001       ; Disable rendering
    STX $4010       ; Disable DMC IRQ


;NOTE: Maybe we need 2 vBlank waits but not sure (Needs to be tested)    
wait_vblank:        ; Wait for the PPU to start
    BIT $2002       ; Reads the PPU-status; bit 7 = VBlank on/off
    BPL wait_vblank ; Loop util bit 7 = nul (negative bit)

    ; Initialize variables state
    LDA #$00        
    STA buttons
    STA old_buttons
    STA selected_building
    STA flags


    ; FOREVER LOOP
    forever:
        JSR Main ;Main loop
        JMP forever

.proc Main 
    JSR ReadController    ; Read controller input
    JSR HandleButtonInput ; Handles the button input and sets or calls the according flags/subroutines
    RTS
.endproc

.proc ReadController

    LDA #$01              
    STA $4016              ; Ping controller 1 to latch it's input

    LDA #$00               
    STA $4016              ; Ping controller 1 to stop latching input so reading can start

    LDX #$08               ; Loop counter

    LDA buttons            
    STA old_buttons        ; Saving "old" input

    LDA #$00               
    STA buttons            ; Clearing old input

readLoop:                  ; Loops 8 times to cover all input bits
    LDA $4016              ; Read next bit
    LSR A                  ; Put A in carry-flag
    ROL buttons            ; Put carry-flag in buttons

    DEX                    
    BNE readLoop           ; Loop until X = 0

    RTS                    ; Return to main
.endproc

.proc HandleButtonInput
    LDA buttons         ; Load button input
    AND #%10000000      ; Isolate bit 7, A-Button
    BEQ checkB          ; If A not pressed, skip A-Button code and check B-Button

    ; A-BUTTON CODE HOLD:

    LDA old_buttons     ; Load old button input
    AND #%10000000      ; Isolate bit 7, A-Button
    BNE checkB          ; If A was pressed, skip new A-Button press code and check B-Button

    ; A-BUTTON CODE NEW PRESS:

checkB:
    LDA buttons         ; Load button input
    AND #%01000000      ; Isolate bit 6, B-Button
    BEQ checkSelect     ; If B not pressed, skip B-Button code and check Select-Button

    ; B-BUTTON CODE HOLD:

    LDA old_buttons     ; Load old button input
    AND #%01000000      ; Isolate bit 6, B-Button
    BNE checkSelect     ; If B was pressed, skip new B-Button press code and check Select-Button

    ; B-BUTTON CODE NEW PRESS:

checkSelect:
    LDA buttons         ; Load button input
    AND #%00100000      ; Isolate bit 5, SELECT-Button
    BEQ checkStart      ; If SELECT not pressed, skip SELECT-Button code and check START-Button

    ; SELECT-BUTTON CODE HOLD:

    LDA old_buttons     ; Load old button input
    AND #%00100000      ; Isolate bit 5, SELECT-Button
    BNE checkStart      ; If SELECT was pressed, skip new SELECT-Button press code and check START-Button

    ; SELECT-BUTTON CODE NEW PRESS:

    ; Toggle build flag
    LDA flags        ; Load flags
    EOR #BUILD_FLAG  ; Flip bit 1 (Build flag)
    STA flags        ; Save new state
    
checkStart:
    LDA buttons         ; Load button input
    AND #%00010000      ; Isolate bit 4, START-Button
    BEQ checkUp         ; If START not pressed, skip START-Button code and check UP-Button

    ; START-BUTTON CODE HOLD:

    LDA old_buttons     ; Load old button input
    AND #%00010000      ; Isolate bit 4, START-Button
    BNE checkUp         ; If START was pressed, skip new START-Button press code and check UP-Button

    ; START-BUTTON CODE NEW PRESS:

    ; Toggle paused flag
    LDA flags        ; Load flags
    EOR #PAUSED_FLAG ; Flip bit 0 (Paused flag)
    STA flags        ; Save new state

checkUp:
    LDA buttons         ; Load button input
    AND #%00001000      ; Isolate bit 3, UP-Button
    BEQ checkDown       ; If UP not pressed, skip UP-Button code and check DOWN-Button

    ; UP-BUTTON CODE HOLD:

    LDA old_buttons     ; Load old button input
    AND #%00001000      ; Isolate bit 3, UP-Button
    BNE checkDown       ; If UP was pressed, skip new UP-Button press code and check DOWN-Button

    ; UP-BUTTON CODE NEW PRESS:

checkDown:
    LDA buttons         ; Load button input
    AND #%00000100      ; Isolate bit 2, DOWN-Button
    BEQ checkLeft       ; If DOWN not pressed, skip DOWN-Button code and check LEFT-Button

    ; DOWN-BUTTON CODE HOLD:

    LDA old_buttons     ; Load old button input
    AND #%00000100      ; Isolate bit 2, DOWN-Button
    BNE checkLeft       ; If DOWN was pressed, skip new DOWN-Button press code and check LEFT-Button

    ; DOWN-BUTTON CODE NEW PRESS:

checkLeft:
    LDA buttons         ; Load button input
    AND #%00000010      ; Isolate bit 1, LEFT-Button
    BEQ checkRight      ; If LEFT not pressed, skip LEFT-Button code and check RIGHT-Button

    ; LEFT-BUTTON CODE HOLD:

    LDA old_buttons     ; Load old button input
    AND #%00000010      ; Isolate bit 1, LEFT-Button
    BNE checkRight      ; If LEFT was pressed, skip new LEFT-Button press code and check RIGHT-Button

    ; LEFT-BUTTON CODE NEW PRESS:

checkRight:
    LDA buttons         ; Load button input
    AND #%00000001      ; Isolate bit 0, RIGHT-Button
    BEQ inputDone       ; If RIGHT not pressed, skip RIGHT-Button code

    ; RIGHT-BUTTON CODE HOLD:

    LDA old_buttons     ; Load old button input
    AND #%00000001      ; Isolate bit 0, RIGHT-Button
    BNE inputDone       ; If RIGHT was pressed, skip new RIGHT-Button press code

    ; RIGHT-BUTTON CODE NEW PRESS:

    RTS ; Return to Main
.endproc

; INTERRUPTROUTINES
nmi:
    RTI                    ; Return from NMI-interrupt

irq:
    RTI                    ; Return from IRQ-interrupt


; INTERRUPTVECTOR
.segment "VECTORS"

.word nmi                  ; NMI-vector
.word reset                ; RESET-vector
.word irq                  ; IRQ/BRK-vector

; CHARACTER ROM
.segment "CHR" 