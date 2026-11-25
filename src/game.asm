; Tom's Favourite NES Game
.include "constants.asm"

.import InitConveyor, ConveyorTick, ConveyorUpload 
.import PlaceConveyor                 ; write one conveyor tile (PPU address in A / X)      ONLY USE IN NMI
.import RotateConveyor                ; turn the direction that PlaceConveyor uses
.import RemoveConveyor                ; remove one conveyor tile (PPU address in A / X)     ONLY USE IN NMI
.importzp conveyor_dir                ; zp variable for conveyor direction

.import InitFactory, UpdateFactory                   
.import PlaceFactory                   ; write one factory tile (PPU address in A / X)      ONLY USE IN NMI
.import RotateFactory                  ; turn the direction that PlaceFactory uses
.import DestroyFactory                 ; remove one factory tile (PPU address in A / X)     ONLY USE IN NMI

.import InitRefinery
.import PlaceRefinery
.import RotateRefinery

.import PaletteData ; import the pallete data from chr.asm
.import InitOamData, TransferOamData, oam_copy ; importing the OAMDMA logic
.import InitMoney, InitNumbers
.import ShowHud, InitHud, SelectableItemTable

.setcpu "6502"

; Macros
JOYPAD1 =  $4016; 
START_ADDRESS_CURSOR_OAM = $00;

.segment "HEADER" ; Header is meestal 16 bytes        
    .byte "NES", $1A           ; Herkenningsbytes voor een NES-ROM
    .byte 2                    ; 2 PRG-ROM banken van 16 KB = 32 KB
    .byte 1                    ; 1 CHR-ROM bank van 8 KB = 8 KB
    .byte $00                  ; Mapper 0, horizontale mirroring
    .byte $00                  ; Overige headerinstellingen 
    .byte $00, $00, $00, $00   ; Ongebruikte headerbytes
    .byte $00, $00, $00, $00   ; Extra ongebruikte headerbytes


.segment "ZEROPAGE"   
    temp:             .res 10        ; to store temperary shit for various functions
    sfx_channel:      .res 1         ; sound effect channel to use  ;; Code from the book
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
    nmi_flag:    .res 1        ; set by the NMI, cleared by the main loop 

    selected_building_mode: .res 1   ; Keeps track of the selected HUD element (factory, depo, area, belt,....) 
        DEPOSIT_STATE     = $00      ; Deposit
        CONVEYOR_STATE    = $01      ; Conveyor
        AREA_SELECT_STATE = $02      ; Area Select
        FACTORY_STATE     = $03      ; Factory     
        REFINERY_STATE    = $04      ; Refinery      
        COLLECTION_STATE  = $05      ; Collection     
        PEOPLE_STATE      = $06      ; People 
        DESTROY_STATE     = $07      ; Destroy
        DEBUG_COIN_STATE  = $08      ; Debug (Add coins)

    flags: .res 1
        PAUSED_FLAG      = %00000001  ; bit 0 = paused
        BUILD_MENU_FLAG  = %00000010  ; bit 1 = build mode
        IS_BUILDING_FLAG = %00000100  ; bit 2 = is building flag
        BUILD_FLAG       = %00001000  ; bit 3 = build selcted item
        ROTATE_FLAG      = %00010000  ; bit 4 = rotate selected item
        SELECTING_FLAG   = %00100000  ; bit 5 = selecting area
    


.segment "CODE"
;;code from the book
; FamiStudio config.
    FAMISTUDIO_CFG_EXTERNAL = 1
    FAMISTUDIO_CFG_DPCM_SUPPORT = 1
    FAMISTUDIO_CFG_SFX_SUPPORT = 1
    FAMISTUDIO_CFG_SFX_STREAMS = 2
    FAMISTUDIO_CFG_EQUALIZER = 1
    FAMISTUDIO_USE_VOLUME_TRACK = 1
    FAMISTUDIO_USE_PITCH_TRACK = 1
    FAMISTUDIO_USE_SLIDE_NOTES = 1
    FAMISTUDIO_USE_VIBRATO = 1
    FAMISTUDIO_USE_ARPEGGIO = 1
    FAMISTUDIO_CFG_SMOOTH_VIBRATO = 1
    FAMISTUDIO_USE_RELEASE_NOTES = 1
    FAMISTUDIO_DPCM_OFF = $e000

    ; CA65-specifc config.
    .define FAMISTUDIO_CA65_ZP_SEGMENT ZEROPAGE
    .define FAMISTUDIO_CA65_RAM_SEGMENT BSS
    .define FAMISTUDIO_CA65_CODE_SEGMENT CODE
    
    .include "famistudio_ca65.s"
    .include "Songs/BtnPressed_SFX.s"
    .include "Songs/Thibe_Track.s"
;;

reset:                             ; Reset label
    SEI             ; Disable CPU interrupts
    CLD             ; Disable decimal mode

    LDX #$40        ; Value to disable the APU-frame-IRQ (audio)
    STX $4017       ; Disable APU frame IRQ

    LDX #$FF        ; X = #$FF
    TXS             ; Initialize stack pointer

    INX             ; X = 0 (FF + 1 = 0 )
    STX PPU_CTRL    ; Disable NMI
    STX PPU_MASK    ; Disable rendering
    STX $4010       ; Disable DMC IRQ
    STX $4015       ; Disable APU channels

    LDA #$FF                    ; Y = $FF hides a sprite
    LDX #$00                    ; X = byte index in the OAM shadow page
clearOam:
    STA $0200,X                 ; hide this byte of the shadow OAM
    INX                         ; next byte
    BNE clearOam                ; until all 256 bytes are done

    ; Initialize variables state
    LDA #$00        
    STA buttons
    STA old_buttons
    STA selected_building_mode
    STA flags     
    STA sfx_channel

    JSR InitOamData
    JSR InitCursor
    JSR InitConveyor            ; conveyor animation and items start from step 0
    JSR InitHud
    JSR InitFactory
    JSR InitRefinery
    JSR InitMoney
    JSR InitNumbers

    ;; code from the book
    LDA #1
    LDX #.lobyte(music_data_untitled)
    LDY #.hibyte(music_data_untitled)
    JSR famistudio_init
    LDX #.lobyte(sounds)
    LDY #.hibyte(sounds)
    JSR famistudio_sfx_init
    ;;

wait_vblank:                       ; Wait for the PPU to start
    BIT PPU_STATUS        ; Reads the PPU-status; bit 7 = VBlank on/off
    BPL wait_vblank ; Loop util bit 7 = nul (negative bit)

    

vblank2:                           ; second vblank wait so the PPU is fully warmed up
    BIT PPU_STATUS
    BPL vblank2
    STA nmi_flag                ; no NMI has happened yet

    ; Rendering is still off, so the PPU may be written at any time
    JSR LoadPalette     ; Loading the pallet data into memory
    JSR ClearNametable  ; empty tiles + attribute table

    JSR ShowHud

enable_rendering:
	LDA #%10000000	; Enable NMI
	STA PPU_CTRL
	LDA #%00011110	; Enable Sprites
	STA PPU_MASK

reset_scroll:
    LDA #$00
    STA PPU_SCROLL   ; set x-scroll to 0
    STA PPU_SCROLL   ; set y-scroll to 0

    ;; code from book
    LDA #0           ; Select song 1
    JSR play_music
    ;;

    ; FOREVER LOOP
    forever:
        JSR Main ; Main loop | START YOUR ADVENTURE HERE !!!!!!!!! |
        JMP forever


.proc Main                         ; MAIN LOOP OF THE GAME
    waitNmi:
        LDA nmi_flag                ; did the NMI run since the last frame?
        BEQ waitNmi                 ; no: wait
        LDA #$00                    ; yes: clear the flag
        STA nmi_flag                ; for the next frame
    JSR ConveyorTick            ; once per frame

    JSR ReadController             ; Read controller input
    JSR HandlePaused               ; Handles/Updates the paused state of the game



    LDA flags
    AND #PAUSED_FLAG               ; check bit 0 of the flags is set
    BNE end                        ; Game paused skip al other btn handling (TODO CHECK: for now)

    JSR UpdateFactory

    JSR HandleButtonInput          ; Handles the button input and sets or calls the according flags/subroutines

    LDA flags                      ; LOAD the flags
    AND #BUILD_MENU_FLAG           ; check bit for BUILD_MENU_FLAG of the flags is set
    BEQ skipHUDMode                ; Game not in HUD mode -> Skip
    JSR HudMode                    ; Game in HUD mode jump to logic

skipHUDMode:                       ; Skip the HUD Mode logic
    LDA flags
    AND #ROTATE_FLAG               ; Check if Rotate flag is set
    BEQ skipRotate                 ; Not Rotating
    JSR Rotate

skipRotate:
    LDA flags
    AND #SELECTING_FLAG ; check bit 1 of the flags is set
    BEQ skipAreaSelect ; Game not in area select mode
    JSR AreaSelectMode ; Game in area select mode
skipAreaSelect:                    ; Skip Area select Mode logic
end:                               ; END of MAIN
    RTS
.endproc

.proc LoadPalette               ; Loading pallet data into memory
    BIT PPU_STATUS              ; reset the PPU address latch
    LDA #$3F                    ; high byte of the palette address
    STA PPU_ADDR                ; first address write
    LDA #$00                    ; low byte of the palette address
    STA PPU_ADDR                ; second address write
    LDX #$00                    ; X = palette byte index
@loop:
    LDA PaletteData, X
    STA PPU_DATA
    INX
    CPX #32                 ; 4 bg palettes + 4 sprite palettes
    BNE @loop

    LDA #$00                ; writing $2006 disturbs the scroll, so reset it
    STA PPU_SCROLL
    STA PPU_SCROLL
    RTS
.endproc

; ClearNametable: tile 0 everywhere, then every attribute byte = palette 1.
; Tile 0 only uses colour 0 (the backdrop), so the palette does not matter for it.
.proc ClearNametable
    BIT PPU_STATUS              ; reset the PPU address latch
    LDA #>NAMETABLE_0           ; high byte of the nametable
    STA PPU_ADDR                ; first address write
    LDA #<NAMETABLE_0           ; low byte of the nametable
    STA PPU_ADDR                ; second address write
    LDA #EMPTY_TILE             ; tile 0 = empty tile
    LDX #$04                    ; 4 pages of 256 bytes = 1024 bytes (tiles and attributes)
    LDY #$00                    ; Y = byte counter inside a page
clearLoop:
    STA PPU_DATA                ; write one tile
    INY                         ; next byte
    BNE clearLoop               ; until the page is done
    DEX                         ; next page
    BNE clearLoop               ; until all pages are done

    LDA #>ATTRIBUTE_0           ; high byte of the attribute table
    STA PPU_ADDR                ; first address write
    LDA #<ATTRIBUTE_0           ; low byte of the attribute table
    STA PPU_ADDR                ; second address write
    LDA #PALETTE_1_ALL          ; every 16x16 block uses palette 1 (the conveyor palette)
    LDX #$40                    ; 64 attribute bytes
attributeLoop:
    STA PPU_DATA                ; write one attribute byte
    DEX                         ; next byte
    BNE attributeLoop           ; until all are done
    RTS                         ; return to caller
.endproc


.proc InitCursor                   ; Init the cursor attribute and pallet in the OAM_copy and sets its location to the center of the screen
    ; start in the center of the tile grid
    JSR ResetCursorPos

    LDX #START_ADDRESS_CURSOR_OAM
    INX
    LDA #CURSOR_TILE
    STA oam_copy, X              ; byte 1: tile index
    INX
    LDA #CURSOR_PALETTE
    STA oam_copy, X              ; byte 2: attributes

    JSR UpdateCursor             ; fills in Y (byte 0) and X (byte 3)
    RTS
.endproc

.proc UpdateCursor                 ; Updates the cursor x an y pos in the oam copy for its position on the grid
    LDX #START_ADDRESS_CURSOR_OAM
    LDA cursor_y ; y index of cursor location
    ASL  ; multiply by 2
    ASL  ; multiply by 4 
    ASL  ; multiply by 8 (sprite size = 8 pixels)
    SEC
    SBC #$01     ; minus 1 because yPos is delayed by 1 scan line
    BCS storeY  ; No carry so not scan line 0;
    LDA #$00     ; y index 0 gets drawn on scan line 1 
    storeY:
        STA oam_copy, X
    INX

    JSR SelectCursorSpriteAndPallet ; setting byte 1 and 2
    INX
    
    LDA cursor_x 
    ASL  ; multiply by 2
    ASL  ; multiply by 4 
    ASL  ; multiply by 8 (sprite size = 8 pixels)
    STA oam_copy, X
    INX
    RTS
.endproc

.proc UpdateCursorInHud            ; Updates the cursor x an y pos in the oam copy for its position on in the HUD
    LDA selected_building_mode     ; Get current seltected index in HUD
    ASL                            ; Multiply by 2
    CLC
    ADC selected_building_mode     ; Add original index value to make it multiply by 3 (this to have the correct ofset for the SelectableItemTable which stores items in increments of 3 bytes)
    TAX                            ; Transfer A to X to be used as an adress ofset
    LDA SelectableItemTable, X     ; Select the data from the HUD SelectableItemTable
    TAY                            ; Store the data in Y register

    LSR
    LSR
    LSR
    LSR
    LSR                             ; Shift out x pos only keeping y pos (3 high bits)     
    
    CLC
    ADC #HUD_POS_Y                   ; Add the Hud Y Pos

    STA cursor_y                    ; Store Y pos in the cursor_y
    TYA                             ; reload the data from the HUD SelectableItemTable stored in Y
    AND #%00011111                  ; AND to keep only the lower 5 bits

    STA cursor_x
    JSR UpdateCursor
    RTS
.endproc

.proc ResetCursorPos                  ; Resets the cursor position
    LDA #$0B
    STA cursor_y      ; Reset cursor_y to center ich of screen
    LDA #$0F
    STA cursor_x      ; Reset cursor_x to center ich of screen
    RTS
.endproc

.proc SelectCursorSpriteAndPallet            ; Select the correct cursor sprite and pallet based on current game flags
    ; if not IS_BUILDING_FLAG set sprite to cursor sprite skip al others
    ; if build mode check which item is selected 
    ; if cursor check cursor direction

    LDA flags
    AND #IS_BUILDING_FLAG
    BNE checkBuildModes    ; is building so check which sprite to use 
    
    LDA #CURSOR_TILE
    STA oam_copy, X
    INX
    LDA #CURSOR_PALETTE
    STA oam_copy, X
    JMP end

    checkBuildModes:
        LDA selected_building_mode
   
        CMP #DEPOSIT_STATE
        BEQ SetSpriteAsDeposit

        CMP #CONVEYOR_STATE       
        BEQ SetSpriteAsConveyor

        CMP #FACTORY_STATE
        BEQ SetSpriteAsFactory

        CMP #REFINERY_STATE
        BEQ SetSpriteAsRefinery

        CMP #COLLECTION_STATE
        BEQ SetSpriteAsCollection

        LDA #PLACEHOLDER_TILE
        STA oam_copy, X
        JMP endBuildModes                ; No valid Mode



        SetSpriteAsDeposit:                   ; Set Sprite as Deposit
            LDA #PLACEHOLDER_TILE
            STA oam_copy, X
            JMP endBuildModes        
        SetSpriteAsConveyor:                  ; Set Sprite as conveyors
            LDA #CONVEYER_RIGHT
            CLC
            ADC conveyor_dir
            STA oam_copy, X
            JMP endBuildModes
        SetSpriteAsFactory:                   ; Set Sprite as factory
            LDA #PLACEHOLDER_TILE
            STA oam_copy, X
            JMP endBuildModes
        SetSpriteAsRefinery:                  ; Set Sprite as refinery
            LDA #REFINERY_TILE
            STA oam_copy, X
            JMP endBuildModes
        SetSpriteAsCollection:                ; Set Sprite as collection
            LDA #PLACEHOLDER_TILE
            STA oam_copy, X
            JMP endBuildModes

    endBuildModes:    
        INX
        LDA #GHOST_PALLETTE
        STA oam_copy, X
        JMP end
    end:
        RTS
.endproc

.proc HandlePaused                 ; Handles/Updates the paused state of the game
    LDA buttons         ; Load button input
    AND #START_BUTTON   ; Isolate bit 4, START-Button
    BEQ end             ; If START not pressed, end

    ; START-BUTTON CODE HOLD PRESS:

    LDA old_buttons     ; Load old button input
    AND #START_BUTTON   ; Isolate bit 4, START-Button
    BNE end             ; If START was pressed, end

    ; START-BUTTON CODE NEW PRESS:

    ; Toggle paused flag
    LDA flags        ; Load flags
    EOR #PAUSED_FLAG ; Flip (Paused flag)
    STA flags        ; Save new state
    
    AND #PAUSED_FLAG    ; test the flag we just stored
    BNE now_paused

    LDA #1              ; now unpaused -> SFX 1
    JSR play_sfx
    JMP end

    now_paused:
        LDA #0              ; now paused -> SFX 0
        JSR play_sfx    

    end:                               ; End of the HandlePaused logic
        RTS
.endproc

;*********************************************************
; Play a sound effect
; a = sound effect to play
; sfx_channel = sound effects channel to use
;*********************************************************
.proc play_sfx
    STA temp+9                   ; Saves the sound effect number
    TYA                          ; Saves the current register values
    PHA                         
    TXA
    PHA
    LDA temp+9                    ; Gets the sound effect number
    LDX sfx_channel               ; Chooses the channel to play the sound effect on
    JSR famistudio_sfx_play
    PLA                           ; Restores the register values
    TAX
    PLA
    TAY
    RTS
.endproc

;*********************************************************
; Play a music track
; a = number of the music track to play
;*********************************************************
.proc play_music
    STA temp+9                    ; Saves the song number
    TYA                           ; Saves the current register values
    PHA
    TXA
    PHA
    LDA temp+9                    ; Gets the music number
    JSR famistudio_music_play
    PLA                           ; Restores the register values
    TAX
    PLA
    TAY
    RTS
.endproc

.proc HudMode                      ; Logic for handling the Build Mode
    LDA flags
    AND #IS_BUILDING_FLAG
    BEQ browseMenu                 ; not building so move the cursor in the HUD
    JSR Build
    RTS

    browseMenu:                       ; Start of the logic for cursor movement inside the HUD
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

    loopToBack:                       ; Reset the selected building mode to #DEBUG_COIN_STATE (8 -> back)
        LDA #DEBUG_COIN_STATE
        STA selected_building_mode 

    checkRight:                       ; The logic for Right cursor movement inside the HUD
        LDA buttons
        AND #RIGHT_BUTTON
        BEQ skipRight               ; not pressed
        LDA old_buttons
        AND #RIGHT_BUTTON
        BNE skipRight               ; held, not a new press so jump
        LDA selected_building_mode
        CMP #DEBUG_COIN_STATE
        BEQ loopToFront               ; already at the last option 
        INC selected_building_mode
        JMP skipRight                ; Jump to avoid the loopback code

    loopToFront:                      ; Reset the selected building mode to #DEPOSIT_STATE (0 -> front)
        LDA #DEPOSIT_STATE
        STA selected_building_mode 

    skipRight:                        ; Skip the logic for Right cursor movement inside the HUD
        JSR UpdateCursorInHud          ; Updates the cursor to be on the correct Hud Button
        RTS
.endproc

.proc Rotate                       ; Rotate logic
    LDA selected_building_mode
   
    CMP #DEPOSIT_STATE
    BEQ RotDeposit

    CMP #CONVEYOR_STATE       
    BEQ RotConveyor

    CMP #FACTORY_STATE
    BEQ RotFactory

    CMP #REFINERY_STATE
    BEQ RotRefinery

    CMP #COLLECTION_STATE
    BEQ RotCollection

    JMP EndRotate                ; other modes: nothing to rotate

    RotDeposit:                   ; Rotate logic for Deposit
        JMP EndRotate
    RotConveyor:                  ; Rotate logic for conveyors
        JSR RotateConveyor
        JMP EndRotate
    RotFactory:                   ; Rotate logic for factory
        JMP EndRotate
    RotRefinery:                  ; Rotate logic for refinery
        JSR RotateRefinery
        JMP EndRotate
    RotCollection:                ; Rotate logic for collection
        JMP EndRotate

    EndRotate:
        LDA flags
        AND #(ROTATE_FLAG ^ $FF)
        STA flags                ;Disable Rotate Flag
        RTS
.endproc

.proc Build                        ; Build logic(does nothing rn)
    RTS
.endproc

.proc AreaSelectMode               ; AreaSelectLogic(does nothing rn)
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
    BEQ checkB                ; Not in build menu jet
    
    LDA flags
    AND #IS_BUILDING_FLAG
    BEQ SetIsBuilding         ; set is building

    LDA flags
    AND #BUILD_FLAG
    BNE checkB                ; Build already set

    LDA flags
    ORA #BUILD_FLAG           ; set build
    STA flags
    JMP checkB                ; Skip SetIsBuilding   

    SetIsBuilding:
        LDA flags
        ORA #IS_BUILDING_FLAG        ; set is building 
        STA flags
        JSR ResetCursorPos           ; Reset the cursor to the grid

checkB:                            ; Checks B button
    LDA buttons         ; Load button input
    AND #B_BUTTON      ; Isolate bit 6, B-Button
    BEQ checkSelect     ; If B not pressed, skip B-Button code and check Select-Button

    ; B-BUTTON CODE HOLD:

    LDA old_buttons     ; Load old button input
    AND #B_BUTTON      ; Isolate bit 6, B-Button
    BNE checkSelect     ; If B was pressed, skip new B-Button press code and check Select-Button

    ; B-BUTTON CODE NEW PRESS:

    LDA flags
    AND #IS_BUILDING_FLAG
    BEQ checkSelect         ; Is building not set

    LDA flags
    ORA #ROTATE_FLAG
    STA flags


checkSelect:                       ; Checks SELECT button
    LDA buttons         ; Load button input
    AND #SELECT_BUTTON  ; Isolate bit 5, SELECT-Button
    BEQ checkBuildState      ; If SELECT not pressed, skip SELECT-Button code and check build state

    ; SELECT-BUTTON CODE HOLD:

    LDA old_buttons     ; Load old button input
    AND #SELECT_BUTTON  ; Isolate bit 5, SELECT-Button
    BNE checkBuildState      ; If SELECT was pressed, skip new SELECT-Button press code and check build state

    ; SELECT-BUTTON CODE NEW PRESS:

    ; Toggle build flag
    LDA flags        ; Load flags
    EOR #BUILD_MENU_FLAG  ; Flip bit 1 (Build flag)
    AND #(IS_BUILDING_FLAG ^ $FF)   ; disable is building flag 
    STA flags        ; Save new state
    LDA #DEPOSIT_STATE ; Set cursor to deposit
    STA selected_building_mode ; Store the new flag 
    JSR ResetCursorPos
    
checkBuildState:                        ; Checks the build state before continueing with the D-pad checks if in build mode skip the D-PAD checks here
    LDA flags
    AND #BUILD_MENU_FLAG
    BEQ checkUp             ; menu closed, movement allowed
    LDA flags
    AND #IS_BUILDING_FLAG
    BEQ inputDone           ; in menu but not building, no grid movement

checkUp:                           ; Checks UP button
    LDA buttons         ; Load button input
    AND #UP_BUTTON      ; Isolate bit 3, UP-Button
    BEQ checkDown       ; If UP not pressed, skip UP-Button code and check DOWN-Button

    ; UP-BUTTON CODE HOLD:

    LDA old_buttons     ; Load old button input
    AND #UP_BUTTON      ; Isolate bit 3, UP-Button
    BNE checkDown       ; If UP was pressed, skip new UP-Button press code and check DOWN-Button

    ; UP-BUTTON CODE NEW PRESS:
    DEC cursor_y                          ; Move up one tile
    BPL checkDown                         ; Branch if not 0 - 1 happend(cursor_y still >= 0)
    LDA #(SCREEN_HEIGHT - HUD_HEIGHT - 1)     ; Went below 0, wrap to the last grid row
    STA cursor_y

checkDown:                         ; Checks DOWN button
    LDA buttons         ; Load button input
    AND #DOWN_BUTTON    ; Isolate bit 2, DOWN-Button
    BEQ checkLeft       ; If DOWN not pressed, skip DOWN-Button code and check LEFT-Button

    ; DOWN-BUTTON CODE HOLD:

    LDA old_buttons     ; Load old button input
    AND #DOWN_BUTTON    ; Isolate bit 2, DOWN-Button
    BNE checkLeft       ; If DOWN was pressed, skip new DOWN-Button press code and check LEFT-Button

    ; DOWN-BUTTON CODE NEW PRESS:
    INC cursor_y                          ; Move down one tile
    LDA cursor_y
    CMP #(SCREEN_HEIGHT - HUD_HEIGHT)     ; First HUD row
    BCC checkLeft                         ; Still inside the grid, no wrap needed (carry = clear)
    LDA #$00                              ; Past the last grid row, wrap to the top
    STA cursor_y
checkLeft:                         ; Checks LEFT button
    LDA buttons         ; Load button input
    AND #LEFT_BUTTON    ; Isolate bit 1, LEFT-Button
    BEQ checkRight      ; If LEFT not pressed, skip LEFT-Button code and check RIGHT-Button

    ; LEFT-BUTTON CODE HOLD:

    LDA old_buttons     ; Load old button input
    AND #LEFT_BUTTON    ; Isolate bit 1, LEFT-Button
    BNE checkRight      ; If LEFT was pressed, skip new LEFT-Button press code and check RIGHT-Button

    ; LEFT-BUTTON CODE NEW PRESS:
    DEC cursor_x                        ; Move left one tile
    BPL checkRight                      ; cursor_x >= 0, no wrap needed
    LDA #(SCREEN_WIDTH - 1)             ; Went below 0, wrap to the last column
    STA cursor_x

checkRight:                        ; Checks RIGHT button
    LDA buttons         ; Load button input
    AND #RIGHT_BUTTON   ; Isolate bit 0, RIGHT-Button
    BEQ inputDone       ; If RIGHT not pressed, skip RIGHT-Button code

    ; RIGHT-BUTTON CODE HOLD:

    LDA old_buttons     ; Load old button input
    AND #RIGHT_BUTTON   ; Isolate bit 0, RIGHT-Button
    BNE inputDone       ; If RIGHT was pressed, skip new RIGHT-Button press code

    ; RIGHT-BUTTON CODE NEW PRESS:
    INC cursor_x                        ; Move right one tile
    LDA cursor_x
    CMP #SCREEN_WIDTH                   ; First column outside the screen
    BCC inputDone                       ; Still inside the screen, no wrap needed
    LDA #$00                            ; Past the last column, wrap to the left
    STA cursor_x



inputDone:                         ; END of input checks
    JSR UpdateCursor               ; Update the cursor in the OAM_Copy
    RTS ; Return to Main
.endproc

.proc HandleBuild
    LDA flags
    AND #BUILD_FLAG
    BEQ SkipBuild               ; BUILD NOT SET

    LDA selected_building_mode
   
    CMP #DEPOSIT_STATE
    BEQ BuildDeposit

    CMP #CONVEYOR_STATE       
    BEQ BuildConveyor

    CMP #FACTORY_STATE
    BEQ BuildFactory

    CMP #REFINERY_STATE
    BEQ BuildRefinery

    CMP #COLLECTION_STATE
    BEQ BuildCollection

    JMP EndBuild                ; other modes: nothing to build

BuildDeposit:                   ; Build logic for Deposit
    JMP EndBuild

BuildConveyor:                  ; Build logic for conveyors
    LDA cursor_y
    LSR
    LSR
    LSR                         ; y / 8
    CLC
    ADC #>NAMETABLE_0           ; + $20 (high byte of NAMETABLE_0)
    TAX                         ; X = high byte

    LDA cursor_y
    AND #%00000111              ; y mod 8
    ASL
    ASL
    ASL
    ASL
    ASL                         ; * 32
    ORA cursor_x                ; A = low byte
    JSR PlaceConveyor
    JMP EndBuild

BuildFactory:                   ; Build logic for factory
    JMP EndBuild

BuildRefinery:                  ; Build logic for refinery
LDA cursor_y
    LSR
    LSR
    LSR                         ; y / 8
    CLC
    ADC #>NAMETABLE_0           ; + $20 (high byte of NAMETABLE_0)
    TAX                         ; X = high byte

    LDA cursor_y
    AND #%00000111              ; y mod 8
    ASL
    ASL
    ASL
    ASL
    ASL                         ; * 32
    ORA cursor_x                ; A = low byte
    JSR PlaceRefinery

    JMP EndBuild
BuildCollection:                ; Build logic for collection

    JMP EndBuild

EndBuild:                       ; Clear the build flag
    LDA flags
    AND #(BUILD_FLAG ^ $FF)
    STA flags

SkipBuild:
    RTS
.endproc



; INTERRUPTROUTINES
nmi:                               ; NMI INTERUPT
    PHA                         ; save A
    TXA                         ; save X
    PHA                         ; ...
    TYA                         ; save Y
    PHA                         ; ...

    JSR TransferOamData         ; Transfer the OAM_Copy to the PPU
    JSR HandleBuild             ; Handles the building of selected item
    
    JSR ConveyorUpload          ; palette writes, returns PPUCTRL bit 4 in A
    ORA #%10000000              ; PPUCTRL bit 7: keep NMI enabled (OR in your other PPUCTRL bits)
    STA PPU_CTRL                ; must come after the palette writes
    LDA #$00                    ; scroll 0, 0
    STA PPU_SCROLL              ; x scroll
    STA PPU_SCROLL              ; y scroll
    LDA #$01                    ; tell the main loop that a new frame started
    STA nmi_flag                ; ...
    
    jsr famistudio_update       ; code from the book
    
    PLA                         ; restore Y
    TAY                         ; ...
    PLA                         ; restore X
    TAX                         ; ...
    PLA                         ; restore A
    RTI                            ; Return from NMI-interrupt

irq:                               ; IRA INTERUPT
    RTI                    ; Return from IRQ-interrupt



.segment "VECTORS" ; INTERRUPTVECTOR
    .word nmi                  ; NMI-vector
    .word reset                ; RESET-vector
    .word irq                  ; IRQ/BRK-vector