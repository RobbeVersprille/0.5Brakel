; ---------------------------------------------------------
; Showing and Controlling the hud
; ---------------------------------------------------------

;; ================ EXPORTS ===============================

;; --------------- SUBROUTINES ----------------------------
;; InitHud
;;  Initialises hud variables in ram
;;  registers used: A

;; ShowHud
;;  Draws the hud at the bottom of the screen
;;  registers used: A, X, Y

;; UpdateItemAmount
;;  updates the value of a HUD item displayed on the HUD
;;  @param A: hud item type
;;  registers used: A, X, Y

;; ShowCost
;;  shows the cost of the currently selected item
;;  @param cost: the cost that needs to be displayed
;;  registers used: A, X, Y

;; HideCost
;;  hides the cost amount
;;  registers used: A, X

;; ---------------- TABLES --------------------------------
;; SelectableItemTable: contains all HUD items that are selectable by the cursor (related: SELECTABLE_ITEM_AMOUNT)

;; ========================================================

.include "constants.asm"
.include "macros.asm"

.export ShowHud, InitHud, UpdateItemAmount, ShowCost, HideCost
.export SelectableItemTable

.importzp string_ptr
.import money, cost, number, number_size, string_size
.import ConvertNumberToDecimal, DrawText

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
;;  CODE/DATA
;; ========================================================

.segment "BSS"
    WORKERS_SIZE = 1
    workers:  .res WORKERS_SIZE     ; reserve 1 byte for the amount of workers

    FOOD_SIZE = 1
    food:       .res FOOD_SIZE      ; reserve 1 byte for the amount of food

    temp:   .res 1
.segment "CODE"

.proc InitHud

    LDA #67
    STA food

    LDA #69
    STA workers

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

    JSR DrawWorkerAmount

    JMP endItemChecks   ; jump to the end and pop item index from stack

checkFoodType:
    CMP #$01            ; compare item type to food type
    BNE checkMoneyType  ; go to next item check if its not equal

    JSR DrawFoodAmount

    JMP endItemChecks   ; jump to end and pop item index from stack

checkMoneyType:
    CMP #$02            ; compare item type to money type
    BNE endItemChecks   ; got to the end of the checks if its not equal

    JSR DrawMoneyAmount

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
;; @param numbers: copy data of segments bytes
;; @param numgers_size: amount of segments bytes
;; registers used: A, X, Y
.proc DrawSegments
    LDX number_size ; byte index in reverse to get highest byte first
    
    TXA         ; transfer amount of bytes to draw to A
    ASL         ; *2 since you need the amount in nibbles
    STA temp    ; store this in temporary variable as the amount of blank tiles to draw at the end of the subroutine
    
    ;; check when the drawing needs to start (first nonzero segment)
findFirstSegment:
    DEX                     ; decrement current byte index
    BPL checkByteSegments   ; if byte index is still >= 0, check byte segment

    ;; since entire value is 0, only draw 1 tile with zero
    LDA #NUMBER_TILE_0  ; load first number tile into A
    STA PPU_DATA        ; store first number tile in nametable
    DEC temp            ; decrement the temp variable containing amount of blank tiles to load at the end

    JMP fillWithBlanks  ; go to the end since the byte index is not valid anymore

checkByteSegments:
    LDA number, X   ; load first 2 segments into A
    TAY             ; save segments byte in Y since the AND operations will modify A

    AND #$F0        ; check if first segment is 0
    BNE drawLoop    ; if segment is non zero, start drawing

    TYA                     ; reload original byte into A again
    AND #$0F                ; check if seconds segment is 0
    BEQ findFirstSegment    ; if second segment is also zero, check next byte

    ;; this gets hit when only the second segment in the byte is non zero unaligning the rest of the writes
drawUnalignedSegment:
    TYA ; reload original byte int A

    CLC                 ; clear carry so it doesnt interfere
    ADC #NUMBER_TILE_0  ; add the first number tile index to the segment
    STA PPU_DATA        ; store number tile into nametable
    DEC temp            ; decrement the amount of blank tiles to load at the end of subroutine

    DEX                 ; decrement byte index
    BMI fillWithBlanks  ; if byte index < 0, go to end of subroutine

    ;; start drawing at current byte index
drawLoop:
    LDA number, X  ; load segments of current byte into A
    TAY             ; save segments byte into y
    
    ;; shift high nibble to low nibble
    LSR
    LSR
    LSR
    LSR

    CLC                 ; clear carry
    ADC #NUMBER_TILE_0  ; add index of first number tile
    STA PPU_DATA        ; store number tile into nametable
    DEC temp            ; decrement amount of blank tiles to load at the end of subroutine

    TYA         ; reload segment byte into A
    AND #$0F    ; only keep the low byte

    CLC                 ; clear carry
    ADC #NUMBER_TILE_0  ; add index of number tile into nametable
    STA PPU_DATA        ; store number tile into nametable
    DEC temp            ; decrement amount of blank tile to load at the end of the subroutine

    DEX                 ; decrement current byte index
    BPL drawLoop        ; keep drawing bytes while byte index >= 0

fillWithBlanks:
    LDX temp            ; fill amount of tile to fill with blank in X
    BEQ end             ; if the temp variable was 0, jump to the end
    LDA #EMPTY_HUD_TILE ; load blank tile in A

@loop:
    STA PPU_DATA    ; load blank tile in nametable
    DEX             ; decrement amount of tile to blank out
    BNE @loop       ; while amount of tiles to blank hasnt reached 0, keep blanking out tiles

end:
    RTS

.endproc

;; updates the value of a HUD item displayed on the HUD
;; @param A: hud item type
;; registers used: A, X, Y
.proc UpdateItemAmount
    TAY ; keep type in y

setPPUAddr:
    STA temp    ; store type in temp (needs to be variable to be able to do arithmetic with A)

    ;; multiply type by 3 to get ItemTable index
    ASL         ; shift left => A *= 2
    CLC         ; clear carry for addition
    ADC temp    ; add the type value to the doubled value => (index * 2) + index = index * 3 
    
    TAX         ; transfer byte index to X

    ;; set address
    LDA ItemTable, X        ; load byte of item into a
    ADC #<HUD_POS_NAMETABLE ; add low byte of nametable pos with nametable offset
    TAX                     ; transfer low byte to X to store
    LDA #>HUD_POS_NAMETABLE ; load high byte of nametable pos
    ADC #$00                ; add carry of previous addition

    STA PPU_ADDR    ; store high byte into ppuaddr
    INX             ; increment lower byte since first byte would be pos of the icon
    TXA             ; transfer low byte stored in X to A
    STA PPU_ADDR    ; store low byte into ppuaddr

checkWorker:
    CPY #WORKER_AMOUNT_ITEM
    BNE checkMoney
    JMP DrawWorkerAmount
checkMoney:
    CPY #MONEY_AMOUNT_ITEM
    BNE checkFood
    JMP DrawMoneyAmount
checkFood:
    CPY #FOOD_AMOUNT_ITEM
    BNE end
    JMP DrawFoodAmount
end:
    RTS
.endproc

;; helper function that fills the number variable in numbers.asm
;; for the workers and draws the number to the screen
;; registers used: A, X, Y
.proc DrawWorkerAmount
    ;; setup worker variable in numbers for decimal display
    FillBinaryNumber workers, WORKERS_SIZE  ; macro that fills number and number_size variables with arguments
    JSR ConvertNumberToDecimal              ; call function to convert loaded values into decimal repr

    ;; dont JSR since DrawSegments will RTS so you skip A JSR and a RTS
    JMP DrawSegments
.endproc

;; helper function that fills the number variable in numbers.asm
;; for the food and draws the number to the screen
;; registers used: A, X, Y
.proc DrawFoodAmount
    ;; setup food variable in numbers for decimal display
    FillBinaryNumber food, FOOD_SIZE    ; macro that fills number and number_size variables with arguments
    JSR ConvertNumberToDecimal          ; call function to convert loaded values into decimal repr

    ;; dont JSR since DrawSegments will RTS so you skip A JSR and a RTS
    JMP DrawSegments
.endproc

;; helper function that fills the number variable in numbers.asm
;; for the money and draws the number to the screen
;; registers used: A, X, Y
.proc DrawMoneyAmount
    ;; setup money variable in numbers for decimal display
    FillBinaryNumber money, MONEY_BYTES ; macro that fills number and number_size variables with arguments
    JSR ConvertNumberToDecimal          ; call function to convert loaded values into decimal repr
    
    ;; dont JSR since DrawSegments will RTS so you skip A JSR and a RTS
    JMP DrawSegments                    ; draw money segments
.endproc

;; shows the cost of the currently selected item
;; @param cost: the cost that needs to be displayed
;; registers used: A, X, Y
.proc ShowCost
    ;; setup ppu_addr
    LDA #>SHOW_COST_POS
    STA PPU_ADDR
    LDA #<SHOW_COST_POS
    STA PPU_ADDR

    ;; load address of string into string ptr
    LDA #<show_cost_str ; load lower byte of address
    STA string_ptr      ; store lower byte in string ptr to draw
    LDA #>show_cost_str ; load high byte of address
    STA string_ptr + 1  ; store high byte in string ptr to draw

    ;; store string size for drawing
    LDA #SHOW_COST_STR_LENGTH   ; load size of string
    STA string_size             ; store in string_size

drawTotal:
    JSR DrawText    ; draw cost text

    ;; draw cost value
    FillBinaryNumber cost, COST_BYTES   ; fill number variable with cost
    JSR ConvertNumberToDecimal          ; convert number variable to decimal
    JMP DrawSegments                    ; draw cost in number variable

    ; RTS => not necessary as JMP DrawSegments will RTS out of this subroutine

.endproc

;; hides the cost amount
;; registers used: A, X
.proc HideCost
    ;; set ppu_addr
    LDA #>SHOW_COST_POS
    STA PPU_ADDR
    LDA #<SHOW_COST_POS
    STA PPU_ADDR

    LDA #EMPTY_HUD_TILE     ; load tile to overwrite show cost with
    LDX #SHOW_COST_LENGTH   ; load amount of tiles to overwrite

@loop:
    STA PPU_DATA    ; write empty tile to nametable
    DEX             ; decrement amount of tiles to write
    BNE @loop        ; if amount of tiles didnt reach 0, keep looping

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
    .byte ((1 << 5) | 1), WORKER_TILE, $00  ; villager amount
    .byte ((3 << 5) | 1), BREAD_TILE,  $01  ; food amount
    .byte ((5 << 5) | 1), COIN_TILE,   $02  ; coin amount

;; start of all items that can be selected in the menu
SELECTABLE_ITEM_AMOUNT = ItemTableEnd - SelectableItemTable
SelectableItemTable:
    .byte ((3 << 5) | 14), PLACEHOLDER_TILE, $FF
    .byte ((3 << 5) | 16), CONVEYER_RIGHT,   $FF
    .byte ((3 << 5) | 18), PLACEHOLDER_TILE, $FF
    .byte ((3 << 5) | 20), PLACEHOLDER_TILE, $FF
    .byte ((3 << 5) | 22), PLACEHOLDER_TILE, $FF
    .byte ((3 << 5) | 24), PLACEHOLDER_TILE, $FF
    .byte ((3 << 5) | 26), WORKER_TILE,      $FF
    .byte ((3 << 5) | 28), PLACEHOLDER_TILE, $FF

    .byte ((5 << 5) | 30), COIN_TILE, $FF    ; reserved for money debug item
ItemTableEnd:

;; data corresponding to cost displaying on the hud, used in ShowCost, Hidecost
SHOW_COST_POS = $238E                                       ; start position to draw in nametable
SHOW_COST_LENGTH = SHOW_COST_STR_LENGTH + (COST_BYTES * 2)  ; max amount of bytes the total text can take up (string length + max amount of segments in cost)

;; variable containing text for showing the cost
SHOW_COST_STR_LENGTH = show_cost_str_end - show_cost_str
show_cost_str:      .byte "cost:"
show_cost_str_end: