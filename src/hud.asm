; ---------------------------------------------------------
; Showing and Controlling the hud
; ---------------------------------------------------------

;; ================ EXPORTS ===============================

;; --------------- FUNCTIONS --------------------
;; InitHud
;; Initialises hud variables in ram
;; registers used: A

;; ShowHud
;; Draws the hud at the bottom of the screen
;; registers used: A, X, Y

;; ---------------- TABLES ----------------------
;; SelectableItemTable: contains all HUD items that are selectable by the cursor (related: SELECTABLE_ITEM_AMOUNT)

;; ========================================================

.include "constants.asm"

.export ShowHud, InitHud
.export SelectableItemTable

;; ========================================================
;;  LOCAL HUD CONSTANTS
;; ========================================================

HUD_BACKGROUND_PALETTE = %10101010  ;; tiles in quad are palette 2

;; first index of hud in nametable as a 1D position
HUD_OFFSET = (HUD_POS_Y * HUD_WIDTH) + HUD_POS_X

HUD_POS_NAMETABLE = NAMETABLE_0 + HUD_OFFSET
HUD_POS_ATTRTABLE = $23C0 | (HUD_OFFSET & $0C00) | ((HUD_OFFSET >> 4) & $38) | ((HUD_OFFSET >> 2) & $07)

HUD_ATTRIBUTE_WIDTH = HUD_WIDTH / ATTR_DIM
HUD_ATTRIBUTE_HEIGHT = (HUD_HEIGHT / ATTR_DIM) + 2

;; ========================================================
;;  MACROS
;; ========================================================

;; fills the variables segments_size and segments_copy that are used when displaying a number in segments
;; @param size: amount of bytes to display
;; @param location: location of the bytes
.macro SetupSegmentsDisplay size, location
    .assert size > 0, error, "Size must be greater than 0"

    ;; setup segments_copy and segments_size variables
    LDA #size           ; load amount of money segemtents bytes in A
    STA segments_size   ; store amount of bytes in segments_size

    ;; fill segments copy in reverse order
    TAX ; transfer amount of bytes in A to X (use as index)
    DEX ; decrement because value is final index + 1

@loop:
    LDA location, X         ; load byte at index X in money variable
    STA segments_copy, X    ; store byte at index X in segments copy

    DEX         ; decrement index
    BPL @loop   ; while X >= 0, keep looping
.endmacro

;; ========================================================
;;  CODE/DATA
;; ========================================================

.segment "BSS"
    ;; todo remove money, villagers, food as these are placeholder variables for testing
    MONEY_SIZE = 5
    money:      .res MONEY_SIZE     ; reseve 5 bytes to be able to display up to 9 billion in display mode

    VILLAGERS_SIZE = 1
    villagers:  .res VILLAGERS_SIZE ; reserve 1 byte for the amount of villagers

    FOOD_SIZE = 1
    food:       .res FOOD_SIZE      ; reserve 1 byte for the amount of food

HUD_VARIABLES_SIZE = HudVariablesEnd - HudVariables
HudVariables:
    MAX_SEGMENTS_SIZE = 5                   ; max amount of segments bytes
    segments_copy: .res MAX_SEGMENTS_SIZE   ; copy of segments to display
    segments_size: .res 1                   ; amount of segments to display
HudVariablesEnd:
.segment "CODE"

.proc InitHud
    .assert HUD_VARIABLES_SIZE <= $FF, error, "Total amount of hud variables exceeds a value that can be indexed using X"

    LDA #$00    ; load initialise value in A
    TAX         ; set index of varibale byte to initialise to 0
@loop:
    STA HudVariables, X ; store init value in variable byte
    
    INX                     ; increment index of byte to initialise
    CPX #HUD_VARIABLES_SIZE  ; check if index is still less than total amount of bytes to initialise
    BNE @loop               ; keep looping while index is not same as total amount of bytes to initialise

    ;; Add dummy data into money, food and villagers
    LDA #$42
    STA money
    LDA #$94
    STA money + 1
    LDA #$96
    STA money + 2
    LDA #$72
    STA money + 3
    LDA #$96
    STA money + 4

    LDA #$69
    STA food

    LDA #$67
    STA villagers

    RTS

.endproc

.proc ShowHud

    JSR FillNametable
    JSR DrawHudItems
    JSR FillAttributeMap

end:
    RTS

.endproc

;; fills the nametable for the hud
.proc FillNametable
    ;; setup ppu nametable writing
    LDA #>HUD_POS_NAMETABLE ; load high byte of hud position into A
    STA PPU_ADDR             ; store high byte of hud position into ppuaddr
    LDA #<HUD_POS_NAMETABLE ; load low byte of hud position into A
    STA PPU_ADDR             ; store low byte of hud position into ppuaddr

drawTopLine:
    ;; draw top left corner of the hud screen
    LDA #TOP_LEFT_CORNER ; load index of top left corner tile
    STA PPU_DATA         ; store top left corner tile in nametable

    ;; draw horizontal lines of top row
    LDA #HORIZONTAL_EDGE ; load index of horizontal edge tile
    LDX #HUD_WIDTH - 2   ; load amount of times this tile needs to be drawn
    JSR DrawLine        ; draw the horizontal edge x times

    ;; draw top right corner of the hud screen
    LDA #TOP_RIGHT_CORNER    ; load index of top right corner tile
    STA PPU_DATA             ; store top right corner tile in nametable

drawMiddleLines:
    LDY #HUD_HEIGHT - 2  ; amount of rows to draw

drawMiddleLine:
    ;; draw first left border tile
    LDA #VERTICAL_EDGE   ; load index of vertical edge tile
    STA PPU_DATA         ; store vertical edge tile in nametable

    ;; draw empty tiles over span of the hud
    LDA #EMPTY_HUD_TILE      ; load index of empty tile
    LDX #HUD_WIDTH - 2   ; load amount of times this tile needs to be drawn
    JSR DrawLine        ; draw empty tile x times

    ;; draw final left border tile
    LDA #VERTICAL_EDGE
    STA PPU_DATA

    DEY                 ; decrement amount of rows to draw
    BNE drawMiddleLine  ; keep drawing lines, while amount of rows to draw is not 0

drawBottomLine:
    ;; draw bottom left corner tile
    LDA #BOTTOM_LEFT_CORNER  ; load index of bottom left corner tile
    STA PPU_DATA             ; store bottom left corner tile into nametable

    ;; draw horizontal lines
    LDA #HORIZONTAL_EDGE ; load index of horizontal tile
    LDX #HUD_WIDTH - 2   ; load amount of columns to draw
    JSR DrawLine        ; draw horizontal line tile x times

    ;; draw bottom right corner tile
    LDA #BOTTOM_RIGHT_CORNER ; load index of bottom right corner tile
    STA PPU_DATA             ; store bottom right corner tile into nametable

end:
    RTS
.endproc

;; Draws a specified tile x times to the ppudata
;; @param A: which tile index to draw
;; @param X: amount of times to draw
.proc DrawLine
    STA PPU_DATA     ; store specified tile in nametable
    DEX             ; decrement amount to draw
    BNE DrawLine    ; keep drawing while amount is not 0

    RTS
.endproc 

;; Fills the attribute map for the hud
.proc FillAttributeMap
    ;; set ppuaddr to hud pos in attribute table
    LDA #>HUD_POS_ATTRTABLE ; high byte of hud position in attribute table
    STA PPU_ADDR             ; store high byte in ppuaddr
    LDA #<HUD_POS_ATTRTABLE ; low byte of hud position in attribute table
    STA PPU_ADDR             ; store low byte in ppuaddr

    LDX #HUD_ATTRIBUTE_WIDTH    ; load width into x (column counter)
    LDY #HUD_ATTRIBUTE_HEIGHT   ; load height into y (row counter)
    LDA #HUD_BACKGROUND_PALETTE ; load menu background color into a

@loop:
    STA PPU_DATA ; store background palette in ppudata
    DEX         ; decrement column counter
    BNE @loop   ; if counter did not reach 0, continue looping

    LDX #HUD_ATTRIBUTE_WIDTH    ; load width back into x (column counter)
    DEY                         ; decrement row counter
    BNE @loop                   ; if row counter did not reach 0, keep looping

end:
    RTS
.endproc

.proc DrawHudItems
    LDX #$00    ; current index in item table

loop:
    TXA ; transfer current index value to a
    PHA ; push index value to save for later

    CLC ; clear carry for arithmetic later

    LDA ItemTable, X        ; load byte of item into a
    ADC #<HUD_POS_NAMETABLE ; add low byte of nametable pos with nametable offset
    TAX                     ; transfer low byte to X to store
    LDA #>HUD_POS_NAMETABLE ; load high byte of nametable pos
    ADC #$00                   ; add carry of previous addition

storeItemNametablePos:
    STA PPU_ADDR ; store high byte into ppuaddr
    TXA         ; transfer low byte stored in X to A
    STA PPU_ADDR ; store low byte into ppuaddr
    
    PLA ; get index back from stack  
    TAX ; load index back into X
    INX ; increment index to get next byte of item
    
storeItemTile:
    LDA ItemTable, X    ; get next byte (tileindex) of item at index X
    STA PPU_DATA         ; load tileindex into nametable

    INX ; increment index to get type of the item

handleItemType:
    ;; push item index onto the stack
    TXA
    PHA

    LDA ItemTable, X    ; load item type into A
    CMP #$FF            ; compare item type to invalid type
    BEQ endItemChecks   ; skip item type if its equal to invalid type

checkVillagerType:
    CMP #$00            ; compare item type to villager type
    BNE checkFoodType   ; go to next item type if its not equal

    SetupSegmentsDisplay VILLAGERS_SIZE, villagers  ; fills variables segments_size and segments_copy with values in arguments
    JSR DrawSegments                                ; draw villagers segments

    JMP endItemChecks   ; jump to the end and pop item index from stack

checkFoodType:
    CMP #$01            ; compare item type to food type
    BNE checkMoneyType  ; go to next item check if its not equal

    SetupSegmentsDisplay FOOD_SIZE, food    ; fill variables segments_size and segments_copy with values in arguments
    JSR DrawSegments                        ; draw food segments

    JMP endItemChecks   ; jump to end and pop item index from stack

checkMoneyType:
    CMP #$02            ; compare item type to money type
    BNE endItemChecks   ; got to the end of the checks if its not equal

    SetupSegmentsDisplay MONEY_SIZE, money  ; fill variables segments_size and segments_copy with values in arguments
    JSR DrawSegments                        ; draw money segments

endItemChecks:
    ;; pop item index from stack
    PLA
    TAX

    INX                     ; increment index int item table
    CPX #ITEM_TABLE_SIZE    ; check if item index is at end
    BNE loop                ; if there are still items that need to be processed, continue

end:
    RTS

.endproc

;; Draws a number to PPU_DATA
;; @param segments_copy: copy data of segments bytes
;; @param segments_size: amount of segments bytes
.proc DrawSegments
    LDX #$FF        ; byte index (FF since loop starts by incrementing X)

    ;; check when the drawing needs to start (first nonzero segment)
findFirstSegment:
    INX                     ; increment current byte index (at start of loop, this value becomes 0)
    CPX segments_size       ; check if current byte index is less than total amount of bytes to check
    BNE checkByteSegments   ; if byte index is not the total amount of bytes, check if byte has nonzero segments

    ;; since entire value is 0, only draw 1 tile with zero
    LDA #NUMBER_TILE_0    ; load first number tile into A
    STA PPU_DATA         ; store first number tile in nametable
    RTS ; return since the byte index is not valid anymore

checkByteSegments:
    LDA segments_copy, X    ; load first 2 segments into A
    TAY                     ; save segments byte in Y since the AND operations will modify A

    AND #$F0        ; check if first segment is 0
    BNE drawLoop    ; if segment is non zero, start drawing

    TYA                     ; reload original byte into A again
    AND #$0F                ; check if seconds segment is 0
    BEQ findFirstSegment    ; if second segment is also zero, check next byte

    ;; this gets hit when only the second segment in the byte is non zero unaligning the rest of the writes
drawUnalignedSegment:
    TYA ; reload original byte int A

    CLC             ; clear carry so it doesnt interfere
    ADC #NUMBER_TILE_0 ; add the first number tile index to the segment
    STA PPU_DATA     ; store number tile into nametable
    
    INX                 ; increment current byte index
    CPX segments_size   ; check if current byte index is still less than amount of bytes to check
    BNE drawLoop ; draw segment byte if byte index is still valid

    RTS ; return since byte index isnt valid anymore

    ;; start drawing at current byte index, (this should be correct because the previous loop only increments X at start)
drawLoop:
    LDA segments_copy, X    ; load segments of current byte into A
    TAY ; save segments byte into y
    
    ;; shift high nibble to low nibble
    LSR
    LSR
    LSR
    LSR

    CLC             ; clear carry
    ADC #NUMBER_TILE_0 ; add index of first number tile
    STA PPU_DATA     ; store number tile into nametable

    TYA         ; reload segment byte into A
    AND #$0F    ; only keep the low byte

    CLC             ; clear carry
    ADC #NUMBER_TILE_0 ; add index of number tile into nametable
    STA PPU_DATA     ; store number tile into nametable
    
    INX                 ; increment current byte index
    CPX segments_size   ; check if current byte index is still less than amount of bytes to check
    BNE drawLoop    ; draw segment byte if byte index is still valid

    RTS

.endproc

;; Item table stores positions of hud items
;; Byte 1: position
;;      bit 0-4: X position in hud
;;      bit 5-7: Y position in hud
;; Byte 2:
;;      tile index
;; Byte 3:
;;      type function index
ITEM_TABLE_SIZE = ItemTableEnd - ItemTable
ITEM_TABLE_WIDTH = 3
ItemTable:
    .byte ((1 << 5) | 1), PLACEHOLDER_TILE, $00  ; villager amount
    .byte ((3 << 5) | 1), PLACEHOLDER_TILE, $01  ; food amount
    .byte ((5 << 5) | 1), PLACEHOLDER_TILE, $02  ; coin amount

;; start of all items that can be selected in the menu
SELECTABLE_ITEM_AMOUNT = ItemTableEnd - SelectableItemTable
SelectableItemTable:
    .byte ((3 << 5) | 14), PLACEHOLDER_TILE, $FF
    .byte ((3 << 5) | 16), PLACEHOLDER_TILE, $FF
    .byte ((3 << 5) | 18), PLACEHOLDER_TILE, $FF
    .byte ((3 << 5) | 20), PLACEHOLDER_TILE, $FF
    .byte ((3 << 5) | 22), PLACEHOLDER_TILE, $FF
    .byte ((3 << 5) | 24), PLACEHOLDER_TILE, $FF
    .byte ((3 << 5) | 26), PLACEHOLDER_TILE, $FF
    .byte ((3 << 5) | 28), PLACEHOLDER_TILE, $FF

    .byte ((5 << 5) | 30), PLACEHOLDER_TILE, $FF    ; reserved for money debug item
ItemTableEnd: