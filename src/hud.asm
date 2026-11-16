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

EMPTY_TILE          = $10
FIRST_CORNER_TILE   = $0A
FIRST_EDGE_TILE     = $0E

.proc InitHud
    LDA #$00            ; reset value for ram
    STA corner_index    ; store reset value in ram
.endproc

.proc ShowHud

    JSR FillTileMap
    JSR FillAttributeMap

.endproc

.proc FillTileMap
    ;; setup ppu so it loads tiles into nametable at correct position
    LDA #>HUD_POS_NAMETABLE ; high byte of hud position in nametable
    STA PPUADDR             ; store high byte of hud position in ppuaddr
    LDA #<HUD_POS_NAMETABLE ; low byte of hud position in nametable
    STA PPUADDR             ; store low byte of hud position in nametable

    ;; load nametable with hud background tile
    LDX #HUD_WIDTH   ; load width into X to use as counter
    LDY #HUD_HEIGHT  ; load height into Y to use as counter
    LDA #EMPTY_TILE  ; load index of tile to load int A

@loop:
    STA PPUDATA     ; store tile index into ppudata
    DEX             ; decrement counter
    BNE @loop       ; if width counter is not 0, keep looping

    LDX #HUD_WIDTH  ; restart with couter
    DEY             ; decrement height counter
    BNE @loop       ; if height counter is not 0, keep looping

end:
    RTS
.endproc

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

.proc GetNecessaryTile
;; check if x is an extreme value
extremaX:
    TXA ; transfer column index to a
    PHA ; push column index value for later

    ORA HUD_WIDTH   ; or to get HUD_WIDTH in a (0 -> HUD_WIDTH, HUD_WIDTH -> HUD_WIDTH, if any other value a will not be HUD_VALUE)
    EOR HUD_WIDTH   ; exclusive or to check if value is equal to HUD_WIDTH

    TAX ; transfer value in x (0 if value is extreme, > 0 if value is not extreme)

extremaY:
    TYA ; transfer row index to a
    PHA ; push row index value for later

    ORA HUD_HEIGHT  ; or to get HUD_HEIGTH IN A (see extremaX)
    EOR HUD_HEIGHT  ; exclusive or to check if value is equal to HUD_HEIGHT

    TAY ; transfer value in y (0 if value is extreme, > 0 if value is not extreme)
    
end:
    ;; pop registers back from stack
    PLA
    TAY
    PLA
    TAX

    RTS

.endproc

.proc OLDGetNecessaryTile
checkCorner:

;; check if x is an extreme value
extremaX:
    TXA             ; transfer column index to a
    ORA HUD_WIDTH   ; or to get HUD_WIDTH in a (0 -> HUD_WIDTH, HUD_WIDTH -> HUD_WIDTH, if any other value a will not be HUD_VALUE)
    CMP HUD_WIDTH   ; check if a is HUD_WIDTH
    BNE checkEdgeX  ; if X is not an extreme value, it is never a corner an edge so skip to edge check

;; check if y is an extreme value
extremaY:
    ;; similar to extremaX but with row extrema
    TYA
    ORA HUD_HEIGHT
    CMP HUD_HEIGHT
    BNE checkEdgeY

    ;; the tile is in extrema
    LDA FIRST_CORNER_TILE   ; get first corner tile in tileset
    CLC                     ; clear carry so it doesnt interfere
    ADC corner_index        ; add the tile index to the first corner tile

    RTS

;; check if x is an edge
checkEdgeX:


;; check if y is an edge
checkEdgeY:

.endproc