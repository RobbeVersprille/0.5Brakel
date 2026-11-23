; ---------------------------------------------------------------------
; Conveyor logic
;
; Public subroutines (callable from any file that does .import):
;   PlaceConveyor  - IN: A = low byte of tile address, X = high byte
;   RotateConveyor - IN: none; turns conveyor_dir 90 degrees
;   RemoveConveyor - IN: A = low byte of tile address, X = high byte
;                    (Place/Remove write straight to the PPU: call them only
;                    while rendering is off or during VBlank)
;   InitConveyor   - IN: none; call once in reset, before NMI is enabled
;   ConveyorTick   - IN: none; call once per frame from the main loop
;   ConveyorUpload - IN: none; call from NMI, while VBlank is running
;                    OUT: A = value for PPUCTRL bit 4 (OR it into $2000)
;
; All of them may change A, X and Y.
;
; HOW THE ANIMATION WORKS (see chr.asm for the tiles)
;   step 0 = pattern table 0, normal colours   (belt at 0 px)
;   step 1 = pattern table 1, normal colours   (belt at 1 px)
;   step 2 = pattern table 0, colours 1+2 swapped (belt at 2 px)
;   step 3 = pattern table 1, colours 1+2 swapped (belt at 3 px)
;   bit 0 of the step = background pattern table (PPUCTRL bit 4)
;   bit 1 of the step = palette colour order     ($3F05 / $3F06)
; Every conveyor on screen shares the same 4 tiles and palette 1, so the
; cost is 2 palette bytes + 1 register bit, whatever the number of belts.
; Items are sprites that move 1 px per step, exactly like the belt texture.
; ---------------------------------------------------------------------

; ---------------------------------------------------------------------
; TO BE IMPLEMENTED:
; The push policy hand-off at the end of a cell (the TODO in ConveyorMoveItems), which needs the cell and building map.
; Spawning items and turning sprites on.
; Writing conveyors at run time. PlaceConveyor writes straight to the PPU, so during gameplay it should be fed from a buffer that the NMI flushes.
; Per-cell attribute bytes once other background content exists.
; Sprite limits: the hardware allows 64 sprites and 8 per scanline, so a long row of items will start to drop sprites.
; ----------------------------------------------------------------------

.include "constants.asm"

.setcpu "6502"                        ; target CPU of this file

.import PaletteData                   ; palette bytes from chr.asm
.import oam_copy                      ; sprite buffer from oam.asm (sent to the PPU by TransferOamData)

.export PlaceConveyor                 ; make visible to other files
.export RotateConveyor                ; make visible to other files
.export RemoveConveyor                ; make visible to other files
.export InitConveyor                  ; make visible to other files
.export ConveyorTick                  ; make visible to other files
.export ConveyorUpload                ; make visible to other files
.exportzp conveyor_dir                ; make zp var visible to other files


; Conveyor directions (value of 'conveyor_dir')
CONVEYOR_DIR_MASK = %00000011         ; 4 directions: 0..3
CONVEYOR_FIRST_TILE = CONVEYER_RIGHT  ; tile index of the right conveyor, + conveyor_dir for the others

; Animation
CONVEYOR_STEP_FRAMES = 9              ; video frames per animation step (belt speed = 1 px per step)
CONVEYOR_STEP_MASK = %00000011        ; 4 animation steps: 0..3
CONVEYOR_PALETTE_HIGH = $3F           ; high byte of $3F05 (background palette 1, colour 1)
CONVEYOR_PALETTE_LOW = $05            ; low byte of $3F05; colour 2 is the next byte, $3F06

; Items (sprites that ride on the conveyors)
MAX_ITEMS = 16                        ; item slots (hardware: 64 sprites, 8 per scanline)
ITEM_HIDDEN_Y = $F0                   ; OAM y value that hides a sprite

.segment "ZEROPAGE"                   ; variables private to this file
    conveyor_ptr: .res 2              ; address of the tile being edited (low, high)
    conveyor_dir: .res 1              ; direction of the conveyor to place (0..3)
    conveyor_step: .res 1             ; animation step that must be on screen (0..3), written by ConveyorTick
    conveyor_shown: .res 1            ; animation step that the PPU shows now, written by ConveyorUpload
    conveyor_timer: .res 1            ; video frames left until the next animation step
    item_x: .res MAX_ITEMS            ; item x position in pixels (= OAM x)
    item_y: .res MAX_ITEMS            ; item y position in pixels (= OAM y, the sprite is drawn 1 line lower)
    item_dx: .res MAX_ITEMS           ; item x speed per step: $00, $01 or $FF (-1)
    item_dy: .res MAX_ITEMS           ; item y speed per step: $00, $01 or $FF (-1)

.segment "CODE"                       ; code goes into PRG-ROM

.proc PlaceConveyor
    STA conveyor_ptr                  ; store low byte of the address
    STX conveyor_ptr + 1              ; store high byte of the address

    BIT PPU_STATUS                    ; reset the PPU address latch
    LDA conveyor_ptr + 1              ; high byte of the tile address
    STA PPU_ADDR                      ; first address write
    LDA conveyor_ptr                  ; low byte of the tile address
    STA PPU_ADDR                      ; second address write
    LDA conveyor_dir                  ; direction 0..3
    CLC                               ; clear carry before adding
    ADC #CONVEYOR_FIRST_TILE          ; tile index = first conveyor tile + direction
    STA PPU_DATA                      ; write the tile (the animation never rewrites it)

    RTS                               ; return to caller
.endproc

.proc RotateConveyor
    LDA conveyor_dir                  ; load current direction
    CLC                               ; clear carry before adding
    ADC #$01                          ; next direction
    AND #CONVEYOR_DIR_MASK            ; wrap 3 -> 0
    STA conveyor_dir                  ; save new direction

    RTS                               ; return to caller
.endproc

.proc RemoveConveyor
    STA conveyor_ptr                  ; store low byte of the address
    STX conveyor_ptr + 1              ; store high byte of the address

    BIT PPU_STATUS                    ; reset the PPU address latch
    LDA conveyor_ptr + 1              ; high byte of the tile address
    STA PPU_ADDR                      ; first address write
    LDA conveyor_ptr                  ; low byte of the tile address
    STA PPU_ADDR                      ; second address write
    LDA #$00                          ; tile 0 = empty tile
    STA PPU_DATA                      ; write the tile

    RTS                               ; return to caller
.endproc

; ---------------------------------------------------------------------
; InitConveyor - reset the animation and park all items
; ---------------------------------------------------------------------
.proc InitConveyor
    LDA #CONVEYOR_STEP_FRAMES         ; frames per animation step
    STA conveyor_timer                ; start the countdown of the first step
    LDA #$00                          ; step 0 = frame A, normal colours
    STA conveyor_step                 ; the step that must be on screen
    STA conveyor_dir                  ; the first conveyor to place points right (direction 0)
    LDA #$FF                          ; a value that is not a step
    STA conveyor_shown                ; forces the first ConveyorUpload to write the palette

    LDX #$00                          ; X = item index
    LDY #$00                          ; Y = offset of that item's sprite inside the item block of OAM
initLoop:
    LDA #$00                          ; zero for x and speeds
    STA item_x,X                      ; x = 0
    STA item_dx,X                     ; not moving horizontally
    STA item_dy,X                     ; not moving vertically
    LDA #ITEM_HIDDEN_Y                ; park the item below the visible screen
    STA item_y,X                      ; y = hidden
    STA oam_copy + OAM_ITEMS_START,Y  ; hide its sprite too (items own OAM_ITEMS_START.., never the cursor)
    INY                               ; next sprite is 4 bytes further
    INY                               ; ...
    INY                               ; ...
    INY                               ; ...
    INX                               ; next item
    CPX #MAX_ITEMS                    ; all items done?
    BNE initLoop                      ; no: continue

    RTS                               ; return to caller
.endproc

; ---------------------------------------------------------------------
; ConveyorTick - main loop, once per frame (NOT in NMI)
; Counts frames; on every CONVEYOR_STEP_FRAMES-th frame it moves all items
; 1 px and then publishes the next step for the NMI.
; ---------------------------------------------------------------------
.proc ConveyorTick
    DEC conveyor_timer                ; one more video frame has passed
    BNE done                          ; not time for a new step yet

    LDA #CONVEYOR_STEP_FRAMES         ; reload the frame countdown
    STA conveyor_timer                ; for the next step

    ; JSR ConveyorMoveItems             ; items move 1 px, like the belt texture does

    LDA conveyor_step                 ; current step
    CLC                               ; clear carry before adding
    ADC #$01                          ; next step
    AND #CONVEYOR_STEP_MASK           ; wrap 3 -> 0
    STA conveyor_step                 ; publish LAST: the NMI never sees half an update
done:
    RTS                               ; return to caller
.endproc

; ---------------------------------------------------------------------
; ConveyorMoveItems - add each item's speed to its position and copy the
; position to its sprite in oam_copy. A parked or blocked item has speed 0.
; ---------------------------------------------------------------------
.proc ConveyorMoveItems
    LDX #$00                          ; X = item index
    LDY #$00                          ; Y = offset of that item's sprite inside the item block of OAM
itemLoop:
    LDA item_x,X                      ; current x
    CLC                               ; clear carry before adding
    ADC item_dx,X                     ; add 0, +1 or -1
    STA item_x,X                      ; save new x
    STA oam_copy + OAM_ITEMS_START + 3,Y ; sprite x byte
    LDA item_y,X                      ; current y
    CLC                               ; clear carry before adding
    ADC item_dy,X                     ; add 0, +1 or -1
    STA item_y,X                      ; save new y
    STA oam_copy + OAM_ITEMS_START,Y  ; sprite y byte

    ; TODO (push policy): count the pixels moved inside the cell; at the end
    ;      of the cell the conveyor PUSHES the item into the next cell:
    ;      accepted -> copy that cell's direction into item_dx / item_dy,
    ;      refused  -> set item_dx / item_dy to 0 and retry on the next step

    INY                               ; next sprite is 4 bytes further
    INY                               ; ...
    INY                               ; ...
    INY                               ; ...
    INX                               ; next item
    CPX #MAX_ITEMS                    ; all items done?
    BNE itemLoop                      ; no: continue

    RTS                               ; return to caller
.endproc

; ---------------------------------------------------------------------
; ConveyorUpload - call from NMI, VBlank only
; Writes the two palette bytes when the step changed (about 80 cycles) and
; always returns the PPUCTRL background pattern table bit in A.
; The caller must write PPUCTRL ($2000) and the scroll AFTER this call.
; ---------------------------------------------------------------------
.proc ConveyorUpload
    LDA conveyor_step                 ; step that must be on screen
    CMP conveyor_shown                ; is it already on screen?
    BEQ ready                         ; yes: no palette write needed
    STA conveyor_shown                ; remember what is on screen from now on

    LSR A                             ; A = 0 for steps 0 and 1, 1 for steps 2 and 3
    TAX                               ; X = colour order: 0 normal, 1 swapped
    EOR #$01                          ; A = the opposite order
    TAY                               ; Y = the opposite order

    BIT PPU_STATUS                    ; reset the PPU address latch
    LDA #CONVEYOR_PALETTE_HIGH        ; high byte of $3F05
    STA PPU_ADDR                      ; first address write
    LDA #CONVEYOR_PALETTE_LOW         ; low byte of $3F05
    STA PPU_ADDR                      ; second address write
    LDA PaletteData + 5,X             ; colour 1: dark when normal, light when swapped
    STA PPU_DATA                      ; write $3F05 (address auto-increments)
    LDA PaletteData + 5,Y             ; colour 2: light when normal, dark when swapped
    STA PPU_DATA                      ; write $3F06
ready:
    LDA conveyor_shown                ; step that is on screen
    AND #%00000001                    ; 0 = frame A (pattern table 0), 1 = frame B (pattern table 1)
    ASL A                             ; move bit 0 up to bit 4
    ASL A                             ; ...
    ASL A                             ; ...
    ASL A                             ; ... = PPUCTRL background pattern table select

    RTS                               ; return to caller
.endproc
