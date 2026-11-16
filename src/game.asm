; Controlls:
;   A-Button      =
;   B-Button      = 
;   UP Arrow      = 
;   DOWN Arrow    = 
;   LEFT Arrow    = 
;   RIGHT Arrow   = 
;   SELECT-Button =
;   START-Button  =

; Macros
JOYPAD1 =  $4016; 
SCREEN_WIDTH  = $20 ; TODO merge with viktor
SCREEN_HEIGHT = $1E ; TODO merge with viktor
HUD_HEIGHT    = $05 ; TODO merge with viktor

.segment "HEADER"
    .byte "NES", $1A                 ; Identification bytes for an NES ROM
    .byte 2                          ; 2 PRG-ROM banks of 16 KB = 32 KB
    .byte 1                          ; 1 CHR-ROM bank of 8 KB = 8 KB
    .byte $00                        ; Mapper 0, horizontal mirroring
    .byte $00                        ; Other header settings
    .byte $00, $00, $00, $00         ; Unused header bytes
    .byte $00, $00, $00, $00         ; Additional reserved header bytes
 
 
.segment "ZEROPAGE"   
    cursor_x:         .res 1         ; x position of the cursor
    cursor_y:         .res 1         ; y position of the cursor
    buttons:          .res 1         ; New button input from current frame (A, B, Select, Start, Up, Down, Left, Right)
    old_buttons:      .res 1         ; Old button input from previous frame (A, B, Select, Start, Up, Down, Left, Right)
        A_BUTTON      = %10000000    ; bit 0 = A
        B_BUTTON      = %01000000    ; bit 1 = B
        SELECT_BUTTON = %00100000    ; bit 2 = Select
        START_BUTTON  = %00010000    ; bit 3 = Start     
        UP_BUTTON     = %00001000    ; bit 4 = Up    
        DOWN_BUTTON   = %00000100    ; bit 5 = Down 
        LEFT_BUTTON   = %00000010    ; bit 6 = Left
        RIGHT_BUTTON  = %00000001    ; bit 7 = Right    
 
    selected_building_mode: .res 1   ; Keeps track of the selected "building" (factory, depo, area, belt,....) 
        DEPOSIT_STATE     = $00      ; bit 0 = Deposit
        CONVEYER_STATE    = $01      ; bit 1 = Conveyer
        AREA_SELECT_STATE = $02      ; bit 2 = Area Select
        FACTORY_STATE     = $03      ; bit 3 = Factory     
        REFINERY_STATE    = $04      ; bit 4 = Refinery      
        COLLECTION_STATE  = $05      ; bit 5 = Collection     
        PEOPLE_STATE      = $06      ; bit 6 = People 
        DESTROY_STATE     = $07      ; bit 7 = Destroy

    flags: .res 1
        PAUSED_FLAG     = %00000001  ; bit 0 = paused
        BUILD_MENU_FLAG = %00000010  ; bit 1 = build mode
        BUILD_FLAG      = %00000100  ; bit 2 = is building flag
        SELECTING_FLAG  = %00001000  ; bit 3 = selecting area
    
    

.segment "CODE"

reset:                             ; Reset label
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

    ; Initialize variables state
    LDA #$00        
    STA buttons
    STA old_buttons
    STA selected_building_mode
    STA flags     

wait_vblank:                       ; Wait for the PPU to start
    BIT $2002       ; Reads the PPU-status; bit 7 = VBlank on/off
    BPL wait_vblank ; Loop util bit 7 = nul (negative bit)

vblank2:                           ; second vblank wait so the PPU is fully warmed up
    BIT $2002
    BPL vblank2

    LDA #%10000000
    STA $2000               ; enable NMI
    LDA #%00001110
    STA $2001               ; enable background rendering


    ; FOREVER LOOP
    forever:
        JSR Main ; Main loop | START YOUR ADVENTURE HERE !!!!!!!!! |
        JMP forever





.proc Main                         ; MAIN LOOP OF THE GAME
    JSR ReadController             ; Read controller input
    JSR HandlePaused               ; Handles/Updates the paused state of the game

    LDA flags
    AND #PAUSED_FLAG               ; check bit 0 of the flags is set
    BNE end                        ; Game paused skip al other btn handling (TODO CHECK: for now)

    JSR HandleButtonInput          ; Handles the button input and sets or calls the according flags/subroutines

    LDA flags                      ; LOAD the flags
    AND #BUILD_MENU_FLAG           ; check bit for BUILD_MENU_FLAG of the flags is set
    BNE skipBuildMenu              ; Game not in build mode -> Skip
    JSR BuildMode                  ; Game in build mode jump to logic

skipBuildMenu:                     ; Skip the build Mode logic
    LDA flags
    AND #BUILD_MENU_FLAG ; check bit 1 of the flags is set
    BNE skipAreaSelect ; Game not in area select mode
    JSR AreaSelectMode ; Game in area select mode
skipAreaSelect:                    ; Skip Area select Mode logic
end:                               ; END of MAIN
    RTS
.endproc

.proc HandlePaused                 ; Handles/Updates the paused state of the game
    LDA buttons         ; Load button input
    AND #START_BUTTON  ; Isolate bit 4, START-Button
    BEQ end         ; If START not pressed, end

    ; START-BUTTON CODE HOLD PRESS:

    LDA old_buttons     ; Load old button input
    AND #START_BUTTON   ; Isolate bit 4, START-Button
    BNE end         ; If START was pressed, end

    ; START-BUTTON CODE NEW PRESS:

    ; Toggle paused flag
    LDA flags        ; Load flags
    EOR #PAUSED_FLAG ; Flip bit 0 (Paused flag)
    STA flags        ; Save new state
end:                               ; End of the HandlePaused logic
    RTS
.endproc

.proc BuildMode                    ; Logic for handling the Build Mode
    LDA flags
    AND #BUILD_FLAG
    BEQ browseMenu                 ; not building so move the cursor in the HUD
    JSR Build
    RTS

browseMenu:                        ; Start of the logic for cursor movement inside the HUD
    LDA buttons
    AND #LEFT_BUTTON
    BEQ checkRight                 ; not pressed
    LDA old_buttons
    AND #LEFT_BUTTON
    BNE checkRight                 ; held, not a new press so jump
    LDA selected_building_mode
    CMP #DEPOSIT_STATE
    BEQ loopToBack                 ; At the first option loop back
    DEC selected_building_mode
    JMP checkRight                 ; Jump to avoid the loopback code

loopToFront:                       ; Reset the selected building mode to #DESTROY_STATE (7 - back)
    LDA #DESTROY_STATE
    STA selected_building_mode 

checkRight:                        ; The logic for Right cursor movement inside the HUD
    LDA buttons
    AND #RIGHT_BUTTON
    BEQ skipRight               ; not pressed
    LDA old_buttons
    AND #RIGHT_BUTTON
    BNE skipRight               ; held, not a new press so jump
    LDA selected_building_mode
    CMP #DESTROY_STATE
    BEQ loopToBack               ; already at the last option 
    DEC selected_building_mode
    JMP skipRight                ; Jump to avoid the loopback code

loopToBack:                        ; Reset the selected building mode to #DEPOSIT_STATE (0 - front)
    LDA #DEPOSIT_STATE
    STA selected_building_mode 

skipRight:                         ; Skip the logic for Right cursor movement inside the HUD
    RTS
.endproc

.proc Build                        ; Build logic
    RTS
.endproc

.proc AreaSelectMode               ; Show the cursor on the grid and start the resource area selection
    RTS
.endproc

.proc ReadController               ; Read the controller state of joypad1

    LDA #$01              
    STA JOYPAD1              ; Ping controller 1 to latch it's input

    LDA #$00               
    STA JOYPAD1              ; Ping controller 1 to stop latching input so reading can start

    LDX #$08               ; Loop counter

    LDA buttons            
    STA old_buttons        ; Saving "old" input

    LDA #$00               
    STA buttons            ; Clearing old input

readLoop:                          ; Loops 8 times to cover all input bits
    LDA JOYPAD1              ; Read next bit
    LSR A                  ; Put A in carry-flag
    ROL buttons            ; Put carry-flag in buttons

    DEX                    
    BNE readLoop           ; Loop until X = 0

    RTS                    ; Return to main
.endproc

.proc HandleButtonInput            ; Handles the general button input (sets states and updates cursor index) 
    LDA buttons         ; Load button input
    AND #A_BUTTON       ; Isolate bit 7, A-Button
    BEQ checkB          ; If A not pressed, skip A-Button code and check B-Button

    ; A-BUTTON CODE HOLD:

    LDA old_buttons     ; Load old button input
    AND #A_BUTTON      ; Isolate bit 7, A-Button
    BNE checkB          ; If A was pressed, skip new A-Button press code and check B-Button

    ; A-BUTTON CODE NEW PRESS:
    LDA flags
    AND #BUILD_MENU_FLAG
    BEQ checkB                ; build menu closed
    LDA flags
    AND #BUILD_FLAG
    BNE checkB                ; is building is set

    LDA flags
    ORA #BUILD_FLAG           ; set is building 
    STA flags

checkB:                            ; Checks B button
    LDA buttons         ; Load button input
    AND #B_BUTTON      ; Isolate bit 6, B-Button
    BEQ checkSelect     ; If B not pressed, skip B-Button code and check Select-Button

    ; B-BUTTON CODE HOLD:

    LDA old_buttons     ; Load old button input
    AND #B_BUTTON      ; Isolate bit 6, B-Button
    BNE checkSelect     ; If B was pressed, skip new B-Button press code and check Select-Button

    ; B-BUTTON CODE NEW PRESS:


checkSelect:                       ; Checks SELECT button
    LDA buttons         ; Load button input
    AND #SELECT_BUTTON  ; Isolate bit 5, SELECT-Button
    BEQ checkStart      ; If SELECT not pressed, skip SELECT-Button code and check START-Button

    ; SELECT-BUTTON CODE HOLD:

    LDA old_buttons     ; Load old button input
    AND #SELECT_BUTTON  ; Isolate bit 5, SELECT-Button
    BNE checkStart      ; If SELECT was pressed, skip new SELECT-Button press code and check START-Button

    ; SELECT-BUTTON CODE NEW PRESS:

    ; Toggle build flag
    LDA flags        ; Load flags
    EOR #BUILD_MENU_FLAG  ; Flip bit 1 (Build flag)
    AND #(BUILD_FLAG ^ $FF)   ; disable is building flag 
    STA flags        ; Save new state
    LDA #DEPOSIT_STATE ; Set cursor to deposit
    STA selected_building_mode ; Store the new flag 
    
checkStart:                        ; Checks START in Handle Paused so it gets handled before the other buttons for pausing reasons (no check here)
checkUp:                           ; Checks UP button
    LDA buttons         ; Load button input
    AND #UP_BUTTON      ; Isolate bit 3, UP-Button
    BEQ checkDown       ; If UP not pressed, skip UP-Button code and check DOWN-Button

    ; UP-BUTTON CODE HOLD:
    DEC cursor_y        ; Increment the cursor index
    BMI checkOldUp      ; Skip reset if index != 0 

    LDA #(SCREEN_HEIGHT - HUD_HEIGHT) ; Start index of the HUD
    STA cursor_y            ; SET y index to max value

    checkOldUp:             ; Check the old button state of UP   
        LDA old_buttons     ; Load old button input
        AND #UP_BUTTON      ; Isolate bit 3, UP-Button
        BNE checkDown       ; If UP was pressed, skip new UP-Button press code and check DOWN-Button

    ; UP-BUTTON CODE NEW PRESS:

checkDown:                         ; Checks DOWN button
    LDA buttons         ; Load button input
    AND #DOWN_BUTTON    ; Isolate bit 2, DOWN-Button
    BEQ checkLeft       ; If DOWN not pressed, skip DOWN-Button code and check LEFT-Button

    ; DOWN-BUTTON CODE HOLD:

    LDA old_buttons     ; Load old button input
    AND #DOWN_BUTTON    ; Isolate bit 2, DOWN-Button
    BNE checkLeft       ; If DOWN was pressed, skip new DOWN-Button press code and check LEFT-Button

    ; DOWN-BUTTON CODE NEW PRESS:

checkLeft:                         ; Checks LEFT button
    LDA buttons         ; Load button input
    AND #LEFT_BUTTON    ; Isolate bit 1, LEFT-Button
    BEQ checkRight      ; If LEFT not pressed, skip LEFT-Button code and check RIGHT-Button

    ; LEFT-BUTTON CODE HOLD:

    LDA old_buttons     ; Load old button input
    AND #LEFT_BUTTON    ; Isolate bit 1, LEFT-Button
    BNE checkRight      ; If LEFT was pressed, skip new LEFT-Button press code and check RIGHT-Button

    ; LEFT-BUTTON CODE NEW PRESS:

checkRight:                        ; Checks RIGHT button
    LDA buttons         ; Load button input
    AND #RIGHT_BUTTON   ; Isolate bit 0, RIGHT-Button
    BEQ inputDone       ; If RIGHT not pressed, skip RIGHT-Button code

    ; RIGHT-BUTTON CODE HOLD:

    LDA old_buttons     ; Load old button input
    AND #RIGHT_BUTTON   ; Isolate bit 0, RIGHT-Button
    BNE inputDone       ; If RIGHT was pressed, skip new RIGHT-Button press code

    ; RIGHT-BUTTON CODE NEW PRESS:

inputDone:                         ; END of input checks
    RTS ; Return to Main
.endproc

.proc UpdateBackgroundColor        ; TEMPERARY HELPER FUNCTION TO SHOW THE STATES
    LDA $2002               ; reset the $2006 write latch
    LDA #$3F
    STA $2006
    LDA #$00
    STA $2006               ; PPU address = $3F00 (universal background color)

    LDA flags
    AND #PAUSED_FLAG        
    BNE paused ; Jump to pause because game is paused 

    LDA flags
    AND #BUILD_FLAG      
    BNE isBuilding ; Jump to is building because you are in the build menu and you've selected what to build (restricted by input handler)

    LDA flags
    AND #BUILD_MENU_FLAG        
    BNE isBuildMode ; Jump to build menu because you are in the build menu and you've not selected what to build



    ;No flags set (Main game)
    LDA #$2b                ; light green
    JMP write               ; Skip other states

isBuildMode:                       ; GAME IN HUD MODE (SELECTING BUILDING IN HUD)
    LDA #$16                       ; red
    JMP write                      ; Skip other states

isBuilding:                        ; GAME IN BUILD MODE (BUILING SELECTED BUILDING)
    LDA #$01                       ; Blue
    JMP write                      ; Skip other states

paused:                            ; GAME PAUSED
    LDA #$00                       ; grays
    JMP write                      ; Skip other states

write:                             ; WRITE THE COLOR
    STA $2007                      ; light green the color
    RTS
.endproc

.proc DrawCursor                   ; Draw the cursor

    RTS
.endproc

; INTERRUPTROUTINES
nmi:                               ; NMI INTERUPT
    PHA                            ; push A to stack
    JSR DrawCursor                 ; Draw the cursor
    JSR UpdateBackgroundColor      ; TEST FUNCTION TO SEE THE DIFFERENT STATES

    PLA                            ; Pull A from stack
    RTI                            ; Return from NMI-interrupt

irq:                               ; IRA INTERUPT
    RTI                    ; Return from IRQ-interrupt

PALETTE_SIZE = PaletteDataEnd - PaletteData
PaletteData:
    .byte $1a $30 $28 $10
PaletteDataEnd:

.segment "VECTORS" ; INTERRUPTVECTOR
    .word nmi                  ; NMI-vector
    .word reset                ; RESET-vector
    .word irq                  ; IRQ/BRK-vector


.segment "CHR" ; CHARACTER ROM
    .byte $E7,$81,$81,$00,$00,$81,$81,$E7,$00,$00,$00,$00,$00,$00,$00,$00 ; Cursor sprite
