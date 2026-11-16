; -----------------------------------------------
; Showing and Controlling the hud
; -----------------------------------------------

;; @param: nothing
;; @return: nothing
;; InitHud: Initialises hud variables in ram
;; registers used: A

;; @param: nothing
;; @return: nothing
;; ShowHud: Draws the hud at the bottom of the screen
;; registers used: A, X, Y

.include "constants.asm"

.export InitHud
.export ShowHud

;; ========================================================
;;  HUD RENDER CONSTANTS
;; ========================================================

.segment "BSS"
corner_index: .res 1 ; when rendering the tiles this is the index that is kept for knowing what direction the hud border looks at

.segment "CODE"

HUD_WIDTH   = SCREEN_WIDTH
HUD_HEIGHT  = 5
HUD_POS_X   = 0
HUD_POS_Y   = SCREEN_HEIGHT - HUD_HEIGHT

HUD_BACKGROUND_PALETTE = $00

;; first index of hud in nametable as a 1D position
HUD_OFFSET = (HUD_POS_Y * HUD_WIDTH) + HUD_POS_X

HUD_POS_NAMETABLE = VRAM_NAMETABLE_0 + HUD_OFFSET
HUD_POS_ATTRTABLE = $23C0 | (HUD_OFFSET & $0C00) | ((HUD_OFFSET >> 4) & $38) | ((HUD_OFFSET >> 2) & $07)

HUD_ATTRIBUTE_WIDTH = HUD_WIDTH / ATTRSIZE
HUD_ATTRIBUTE_HEIGHT = (HUD_HEIGHT / ATTRSIZE) + 1  ; +1 because the division needs to be ceiled

;; ========================================================
;;  HUD TILE CONSTANTS
;; ========================================================

TOP_LEFT_CORNER     = $0A
TOP_RIGHT_CORNER    = $0B
BOTTOM_LEFT_CORNER  = $0C
BOTTOM_RIGHT_CORNER = $0D
HORIZONTAL_EDGE     = $0E
VERTICAL_EDGE       = $0F
EMPTY_TILE          = $10

PLACEHOLDER_TILE    = $11

.proc InitHud
    LDA #$00            ; reset value for ram
    STA corner_index    ; store reset value in ram
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
    STA PPUADDR             ; store high byte of hud position into ppuaddr
    LDA #<HUD_POS_NAMETABLE ; load low byte of hud position into A
    STA PPUADDR             ; store low byte of hud position into ppuaddr

drawTopLine:
    ;; draw top left corner of the hud screen
    LDA #TOP_LEFT_CORNER ; load index of top left corner tile
    STA PPUDATA         ; store top left corner tile in nametable

    ;; draw horizontal lines of top row
    LDA #HORIZONTAL_EDGE ; load index of horizontal edge tile
    LDX #HUD_WIDTH - 2   ; load amount of times this tile needs to be drawn
    JSR DrawLine        ; draw the horizontal edge x times

    ;; draw top right corner of the hud screen
    LDA #TOP_RIGHT_CORNER    ; load index of top right corner tile
    STA PPUDATA             ; store top right corner tile in nametable

drawMiddleLines:
    LDY #HUD_HEIGHT - 2  ; amount of rows to draw

drawMiddleLine:
    ;; draw first left border tile
    LDA #VERTICAL_EDGE   ; load index of vertical edge tile
    STA PPUDATA         ; store vertical edge tile in nametable

    ;; draw empty tiles over span of the hud
    LDA #EMPTY_TILE      ; load index of empty tile
    LDX #HUD_WIDTH - 2   ; load amount of times this tile needs to be drawn
    JSR DrawLine        ; draw empty tile x times

    ;; draw final left border tile
    LDA #VERTICAL_EDGE
    STA PPUDATA

    DEY                 ; decrement amount of rows to draw
    BNE drawMiddleLine  ; keep drawing lines, while amount of rows to draw is not 0

drawBottomLine:
    ;; draw bottom left corner tile
    LDA #BOTTOM_LEFT_CORNER  ; load index of bottom left corner tile
    STA PPUDATA             ; store bottom left corner tile into nametable

    ;; draw horizontal lines
    LDA #HORIZONTAL_EDGE ; load index of horizontal tile
    LDX #HUD_WIDTH - 2   ; load amount of columns to draw
    JSR DrawLine        ; draw horizontal line tile x times

    ;; draw bottom right corner tile
    LDA #BOTTOM_RIGHT_CORNER ; load index of bottom right corner tile
    STA PPUDATA             ; store bottom right corner tile into nametable

end:
    RTS
.endproc

;; Draws a specified tile x times to the ppudata
;; @param A: which tile index to draw
;; @param X: amount of times to draw
.proc DrawLine
    STA PPUDATA     ; store specified tile in nametable
    DEX             ; decrement amount to draw
    BNE DrawLine    ; keep drawing while amount is not 0

    RTS
.endproc 

;; Fills the attribute map for the hud
.proc FillAttributeMap
    ;; set ppuaddr to hud pos in attribute table
    LDA #>HUD_POS_ATTRTABLE ; high byte of hud position in attribute table
    STA PPUADDR             ; store high byte in ppuaddr
    LDA #<HUD_POS_ATTRTABLE ; low byte of hud position in attribute table
    STA PPUADDR             ; store low byte in ppuaddr

    LDX #HUD_ATTRIBUTE_WIDTH    ; load width into x (column counter)
    LDY #HUD_ATTRIBUTE_HEIGHT   ; load height into y (row counter)
    LDA #HUD_BACKGROUND_PALETTE ; load menu background color into a

@loop:
    STA PPUDATA ; store background palette in ppudata
    DEX         ; decrement column counter
    BNE @loop   ; if counter did not reach 0, continue looping

    LDX #HUD_ATTRIBUTE_WIDTH    ; load width back into x (column counter)
    DEY                         ; decrement row counter
    BNE @loop                   ; if row counter did not reach 0, keep looping

end:
    RTS
.endproc

.proc DrawHudItems
    LDY #(ITEM_TABLE_SIZE / ITEM_TABLE_WIDTH)   ; amount of items to process
    LDX 0                                       ; index in item table

loop:
    TXA ; transfer current index value to a
    PHA ; push index value to save for later

    CLC ; clear carry for arithmetic later

    LDA ItemTable, X        ; load byte of item into a
    ADC #<HUD_POS_NAMETABLE ; add low byte of nametable pos with nametable offset
    TAX                     ; transfer low byte to X to store
    LDA #>HUD_POS_NAMETABLE ; load high byte of nametable pos
    ADC 0                   ; add carry of previous addition

storePPUADDR:
    STA PPUADDR ; store high byte into ppuaddr
    TXA         ; transfer low byte stored in X to A
    STA PPUADDR ; store low byte into ppuaddr
    
    PLA ; get index back from stack  
    TAX ; load index back into X
    INX ; increment index to get next byte of item
    
    LDA ItemTable, X    ; get next byte (tileindex) of item at index X
    STA PPUDATA         ; load tileindex into nametable

    INX         ; increment index int item table
    DEY         ; decrement amount of items to process
    BNE loop    ; if there are still items that need to be processed, continue

end:
    RTS

.endproc

;; Item table stores positions of hud items
;; Byte 1: position
;;      bit 0-4: X position in hud
;;      bit 5-7: Y position in hud (can only be 3 positions)
;; Byte 2:
;;      tile index
ITEM_TABLE_SIZE = ItemTableEnd - ItemTable
ITEM_TABLE_WIDTH = 2
ItemTable:
    .byte ((1 << 5) | 1), PLACEHOLDER_TILE  ; villager amount
    .byte ((2 << 5) | 1), PLACEHOLDER_TILE  ; food amount
    .byte ((3 << 5) | 1), PLACEHOLDER_TILE  ; coin amount

;; start of all items that can be selected in the menu
SELECTABLE_ITEMS = ItemTableEnd - ItemTable
SelectableItemTable:
    .byte ((2 << 5) | 16), PLACEHOLDER_TILE
    .byte ((2 << 5) | 18), PLACEHOLDER_TILE
    .byte ((2 << 5) | 20), PLACEHOLDER_TILE
    .byte ((2 << 5) | 22), PLACEHOLDER_TILE
    .byte ((2 << 5) | 24), PLACEHOLDER_TILE
ItemTableEnd: