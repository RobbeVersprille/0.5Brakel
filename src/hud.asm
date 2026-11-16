; -----------------------------------------------
; Showing and Controlling the hud
; -----------------------------------------------

;; @param: nothing
;; @return: nothing
;; ShowHud: Draws the hud at the bottom of the screen
;; registers used: A, X, Y

.include "constants.asm"

.export ShowHud

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


.proc ShowHud

    JSR FillTileMap
    JSR FillAttributeMap

.endproc

.proc FillTileMap
    ;; setup ppu so it loads tiles into nametable at correct position
    LDA #>HUD_POS_NAMETABLE ; high byte of hud position in nametable
    STA PPUADDR            ; store high byte of hud position in ppuaddr
    LDA #<HUD_POS_NAMETABLE ; low byte of hud position in nametable
    STA PPUADDR            ; store low byte of hud position in nametable

    ;; load nametable with hud background tile
    LDX #HUD_WIDTH   ; load width into X to use as counter
    LDY #HUD_HEIGHT  ; load height into Y to use as counter
    LDA #$0A         ; load index of tile to load int A

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