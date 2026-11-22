; PUBLIC FUNCTIONS:
;   FactoryInit - call once on reset to initialize factory variables
;   FactoryUpdate - call from main loop
;   PlaceFactory - IN: A = low byte of tile address, X = high byte
;   DestroyFactory - IN: A = low byte of tile address, X = high byte
;   RotateFactory - erm is still bugged but yk.
;
; 
; TODO: rotation in a separate thing see: robbe's code



.include "constants.asm"

.import TransferOamData, oam_copy ; importing OAM
.export FactoryDraw, PlaceFactory, DestroyFactory, RotateFactory, FactoryInit, FactoryUpdate, TakeFactoryInput
MAX_FACTORIES = 16              ;Set a limit for the number of factories in the game

;factory inventory
ITEM_WOOD = $00                 ;Wood item ID
ITEM_STONE = $01                ;Stone item ID
ITEM_WHEAT = $02                ;Wheat item ID
ITEM_POTION = $03               ;Potion item ID
ITEM_PLANK = $04                ;Plank item ID 
ITEM_SAND = $05                 ;Sand item ID 
ITEM_FOOD = $06                 ;Food item ID

;factory tile for drawing factory on background
FACTORY_TILE_COUNT = 6          ;Total number of factory tiles to draw

.segment "ZEROPAGE"          ; Zero page variables

factory_index: .res 1                        ; Reserve 1 byte for factory index
factory_input_item: .res 1                   ; Reserve 1 byte for input item ID (what item is being input into the factory)
factory_draw_hi: .res 1
factory_draw_lo: .res 1
factory_rows_left: .res 1

factory_tile_x: .res 1                       ; Reserve 1 byte for factory tile X position
factory_tile_y: .res 1                       ; Reserve 1 byte for factory tile Y position

.segment "BSS"

factory_wheat: .res MAX_FACTORIES
factory_plank: .res MAX_FACTORIES
factory_sand: .res MAX_FACTORIES
factory_output: .res MAX_FACTORIES
factory_crafting_timer: .res MAX_FACTORIES
factory_output_connected: .res MAX_FACTORIES
factory_x: .res MAX_FACTORIES
factory_y: .res MAX_FACTORIES
;used for draw, is changed depending on the rotation
factory_width: .res MAX_FACTORIES            ; Number of tiles per row
factory_height: .res MAX_FACTORIES           ; Number of rows

factory_state: .res MAX_FACTORIES ; Reserve 1 byte for factory state (placed, paused, crafting, rotation)
    IS_PLACED = %10000000 ;factory placed bit 0
    CRAFTING = %00100000  ;factory is crafting a potion (cooldown) bit 2
    ROTATION_MASK = %00000011 ;lowest 2 bits contain the rotation
        ROT_0 = %00000000              ; 0 degrees
        ROT_90 = %00000001             ; 90 degrees
        ROT_180 = %00000010            ; 180 degrees
        ROT_270 = %00000011            ; 270 degrees


.segment "CODE"              ; Code segment (hence the name)

.proc FactoryInit           ; Initialize factory
    LDX #$00                     ; Start at index zero
    LDA #$00                     ; Set everything to zero with this value

    STA factory_input_item, X            ; Reset input item ID
    STA factory_index, X                 ; Reset factory index
    STA factory_draw_hi, X                ; Reset factory draw high byte
    STA factory_draw_lo, X                ; Reset factory draw low byte
    STA factory_tile_x, X                ; Reset factory tile X position
    STA factory_tile_y, X                ; Reset factory tile Y position

    factoryInitLoop:                        ; Loop through all factory slots
    STA factory_wheat, X                ; Reset wheat inventory
    STA factory_plank, X                ; Reset plank inventory
    STA factory_sand, X                 ; Reset sand inventory
    STA factory_crafting_timer, X       ; Reset crafting timer
    STA factory_output_connected, X     ; Reset output connection
    STA factory_output, X               ; Reset output potion
    STA factory_x, X                    ; Reset X position
    STA factory_y, X                    ; Reset Y position
    STA factory_state, X                ; Reset factory state
    STA factory_width, X                ; Reset factory width
    STA factory_height, X               ; Reset factory height



    INX                          ; Move to next factory
    CPX #MAX_FACTORIES           ; Check if all factories were initialized
    BNE factoryInitLoop          ; Repeat if more factories remain

    ; LDX #$00                    ; Select factory 0
    ; LDA #$0A                    ; X position = 10
    ; STA factory_x, X            ; Save X position
    ; LDA #$08                    ; Y position = 8
    ; STA factory_y, X            ; Save Y position
    RTS                          ; Return from subroutine
.endproc                     ; End subroutine

.proc FactoryUpdate         ; Update factory
    LDX #$00                     ; Start at index zero

    factoryUpdateLoop:           ; Loop through all factory slots
    JSR FactoryCheckRecipe       ; Check if the factory has a valid recipe

    INX                          ; Move to next factory
    CPX #MAX_FACTORIES           ; Check if all factories were updated
    BNE factoryUpdateLoop        ; Repeat if more factories remain

    RTS                          ; Return from subroutine (factory update)
.endproc                     ; End subroutine

.proc FactoryCheckRecipe    ; Check factory recipe
    LDA factory_plank, X         ; Check for planks
    BNE checkSand                ; If found check sand
    BEQ invalidRecipe            ; Invalid if it doesn't exists

    checkSand:                   ; Check sand category
    LDA factory_sand, X          ; Check for sand
    BNE checkWheat               ; If found check for wheat
    BEQ invalidRecipe            ; Invalid if neither exists

    checkWheat:                  ; Check wheat category
    LDA factory_wheat, X         ; Check for wheat
    BNE recipeComplete           ; If found, recipe is complete
    BEQ invalidRecipe            ; Invalid if neither exists

    recipeComplete:              ; All three categories satisfied
    ;TODO: MAKE POTIONS
    JSR FactoryCreatePotion      ; Create potion sprite if recipe is valid

    invalidRecipe:               ; If any ingredient is zero, the recipe is invalid
    RTS                          ; Return from subroutine
.endproc                     ; End subroutine

.proc FactoryCreatePotion   ; Create potion sprite
    LDX #$00                     ; Start looking for an empty slot in OAM to place the potion sprite
    findEmptyOAMSlot:            ; Loop to find an empty OAM slot
    LDA oam_copy, X              ; Load the Y position of the sprite at index X
    CMP #$00                     ; Compare it to zero (empty slot)
    BEQ foundEmptySlot           ; If Y position is zero, the slot is empty

    TXA                         ; Transfer X to A to increment the index
    INX                          ; Increment the index
    JMP findEmptyOAMSlot         ; Loop back to check the next slot

    RTS                          ; Return from subroutine (no empty slot found in OAM)

    foundEmptySlot:            ; Found an empty OAM slot
    LDA factory_y, Y          ; Load the Y position of the factory
    STA oam_copy, X           ; make the potion sprite appear at the factory's Y position
                              ; This also prevents the sprite from being deleted
    JSR UseMaterials          ; Call the UseMaterials subroutine to decrement the factory's inventory
    RTS                          ; Return from subroutine
.endproc                     ; End subroutine

.proc FactoryDeleteMaterials   ; Delete the used materials
    LDA #$00                          ; clear the materials
    ; this slot can now be overwritten by another sprite
    STA oam_copy, Y                     ; Hide the sprite by setting its Y position off-screen

    RTS                             ; Return from subroutine
.endproc

.proc UseMaterials
    LDA factory_plank, X         ; Load the plank count for the current factory
    DEC factory_plank, X         ; Decrement the plank count
    LDA factory_sand, X          ; Load the sand count for the current factory
    DEC factory_sand, X          ; Decrement the sand count
    LDA factory_wheat, X         ; Load the wheat count for the current factory
    DEC factory_wheat, X         ; Decrement the wheat count
    RTS                     ; Return from subroutine
.endproc

.proc FactoryDraw           ; Draw factory (background)
    LDA #FACTORY_TILE
    LDA factory_y, X                 
    LSR A                            ; divide by 2
    LSR A                            ; divide by 4
    LSR A                            ; divide by 8
    CLC                              ; clear carry
    ADC #$20                         ; Add the nametable 0 base address ($2000)
    STA factory_draw_hi              ; Save the high byte

    LDA factory_y, X                 
    AND #%00000111                   ; Keep the row inside this block of 8 rows (0-7)
    ASL A                            ; multiply by 2
    ASL A                            ; multiply by 4
    ASL A                            ; multiply by 8
    ASL A                            ; multiply by 16
    ASL A                            ; multiply by 32 
    ORA factory_x, X                 ; Add the column (0-31)
    STA factory_draw_lo              ; Save the low byte


    LDA factory_state, X         ; Get the selected factory's state
    AND #ROTATION_MASK           ; Keep only the rotation bits

    CMP #ROT_0                   ; Is the factory at 0 degrees?
    BEQ drawRotation0            ; Draw normal orientation

    CMP #ROT_90                  ; Is the factory at 90 degrees?
    BEQ drawRotation90           ; Draw rotated orientation

    CMP #ROT_180                 ; Is the factory at 180 degrees?
    BEQ drawRotation180          ; Draw rotated orientation

    JMP drawRotation270          ; Otherwise draw at 270 degrees

    drawRotation0:              ; Draw factory at 0 degrees
    drawRotation180:            ; Draw factory at 180 degrees
    LDA #$02
    STA factory_width, X         ; Set width to 2 tiles
    LDA #$03
    STA factory_height, X        ; Set height to 3 tiles
    JMP drawTiles                 ; Jump to draw the tiles    

    drawRotation90:             ; Draw factory at 90 degrees
    drawRotation270:            ; Draw factory at 270 degrees
    LDA #$03
    STA factory_width, X         ; Set width to 3 tiles
    LDA #$02
    STA factory_height, X        ; Set height to 2 tiles
    JMP drawTiles                 ; Jump to draw the tiles

    drawTiles:                       ; Draw the factory tiles for the current rotation
    LDA factory_height, X
    STA factory_rows_left              ; Load the height of the factory (number of rows)
    
    newRow:                         ; start row 
    BIT PPU_STATUS                        ; Reset the PPU address latch 
    LDA factory_draw_hi
    STA PPU_ADDR                        ; PPU address high byte
    LDA factory_draw_lo
    STA PPU_ADDR                        ; PPU address low byte

    LDA factory_width, X      
    TAY

    print:                          ; draw the tiles in the current row 
    LDA #FACTORY_TILE                   ; Load factory tile ID
    STA PPU_DATA                        ; Write tile to PPU
    DEY                                 ; Decrease column counter
    BNE print                      ; Continue until row is full

    LDA factory_draw_lo                 ; Load current low address
    CLC                                 ; Clear carry
    ADC #$20                            ; Move down one nametable row
    STA factory_draw_lo                 ; Store updated low address
    LDA factory_draw_hi                 ; Load current high address
    ADC #$00                            ; Add carry if necessary
    STA factory_draw_hi                 ; Store updated high address

    DEC factory_rows_left               ; Decrease row counter
    BNE newRow                         ; Continue until all rows are drawn

    LDA #$00                            ; Reset horizontal scroll
    STA $2005                            ; Write horizontal scroll
    STA $2005                            ; Reset vertical scroll
    
    RTS                          ; Return from subroutine


    factory_tiles:                  ; Same tile repeated across all factory positions
    .byte FACTORY_TILE, FACTORY_TILE ; Top row
    .byte FACTORY_TILE, FACTORY_TILE ; Middle row
    .byte FACTORY_TILE, FACTORY_TILE ; Bottom row
    RTS                          ; Return from subroutine
.endproc                     ; End subroutine

;------------------------------------------------------------------------
; IN: A = low byte, X = high byte of the PPU tile address (nametable 0)
; OUT: carry clear = placed (X = slot), carry set = no free slot
; Writes to the PPU, so call it with rendering off or during VBlank.
;------------------------------------------------------------------------
.proc PlaceFactory         ; Place factory
    ; address -> tile column/row
    PHA                         ; push low byte on the stack
    AND #%00011111
    STA factory_tile_x          ; store column
    PLA                         ; pull low byte from stack
    LSR A                       ; divide by 2
    LSR A                       ; divide by 4
    LSR A                       ; divide by 8
    LSR A                       ; divide by 16
    LSR A                       ; divide by 32
    STA factory_tile_y          ; store the row
    TXA                         ; high byte
    AND #%00000011               
    ASL A                       ; multiply by 2
    ASL A                       ; multiply by 4
    ASL A                       ; multiply by 8 
    ORA factory_tile_y
    STA factory_tile_y          ; storing the row

    ; find a free slot in array of factories (depending on how many factories have been placed)
    LDX #$00                    ; start at index zero
    findFree:
    LDA factory_state, X
    BPL found                   ; bit 7 (IS_PLACED) clear = free
    INX
    CPX #MAX_FACTORIES          ; check if we have reached the maximum number of factories
    BNE findFree                ; slot not free and under max amount, search next slot
    SEC                         ; no free slot
    RTS                         ; return and carry is set to indicate failure

    ; YAYYYY WE FOUND A FREE SLOT YIIPPEEEEEEEE
    ; now we save the position and state so the factory doesn't get overwritten by next place
    found:
    LDA factory_tile_x          
    STA factory_x, X            ; save the factory's X position
    LDA factory_tile_y
    STA factory_y, X            ; save the factory's Y position
    LDA #IS_PLACED
    STA factory_state, X        ; save the factory's state (placed)
    JSR FactoryDraw             ; X = slot; draws using the x/y/state just set
    CLC                         ; clear carry
    RTS                         ; Return from subroutine
.endproc                     ; End subroutine

.proc DestroyFactory        ; Remove factory
    
    
    
    RTS                          ; Return from subroutine
.endproc                     ; End subroutine

.proc RotateFactory        ; Rotate factory 
    LDA factory_state, X         ; Get the selected factory's state
    AND #ROTATION_MASK           ; Keep only the rotation bits
    CLC                          ; Clear the carry flag
    ADC #$01                     ; Increment the rotation
    AND #ROTATION_MASK           ; Keep only the rotation bits (wrap around after 3)
    STA factory_state, X         ; Save the new rotation state
    RTS                          ; Return from subroutine
.endproc                     ; End subroutine

.proc TakeFactoryInput        ; Take input from conveyor belt and add to factory inventory
    STA factory_input_item          ; Save the incoming item ID to the factory input item variable
    LDX factory_index               ; Load the current factory index

    LDA factory_input_item          ; Load the incoming item ID

    ;ADD TO INVENTORY
    CMP #ITEM_PLANK                  ; Check if the item is plank
    BEQ addPlank                     ; If it is, branch to add plank

    CMP #ITEM_SAND                   ; Check if the item is sand
    BEQ addSand                      ; If it is, branch to add sand

    CMP #ITEM_WHEAT                  ; Check if the item is wheat
    BEQ addWheat                     ; If it is, branch to add wheat

    CMP #ITEM_WOOD                   ; Check if the item is wood
    JMP deleteSprite                 ; If it is, delete the sprite (not used in factory)

    CMP #ITEM_STONE                  ; Check if the item is stone
    JMP deleteSprite                 ; If it is, delete the sprite (not used in factory)

    CMP #ITEM_FOOD                   ; Check if the item is food
    JMP deleteSprite                 ; If it is, delete the sprite (not used in factory)

    addPlank:                        ; Add plank to factory inventory
    INC factory_plank, X             ; Increment the plank count for the current factory
    JMP deleteSprite                 ; Delete the sprite
    
    addSand:                         ; Add sand to factory inventory
    INC factory_sand, X              ; Increment the sand count for the current factory
    JMP deleteSprite                 ; Delete the sprite 

    addWheat:                        ; Add wheat to factory inventory
    INC factory_wheat, X             ; Increment the wheat count for the current factory
    JMP deleteSprite                 ; Delete the sprite 

    ; DELETE SPRITE
    deleteSprite:                        ; Delete the sprite coming into the factory
    JSR FactoryDeleteMaterials       ; Call the FactoryDeleteMaterials subroutine to remove the sprite

    RTS                          ; Return from subroutine
.endproc                     ; End subroutine


