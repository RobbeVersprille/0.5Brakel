; -----------------------------------------------
; Showing and Controlling the hud
; -----------------------------------------------

.include "constants.asm"

HUD_POS_X   = 0
HUD_POS_Y   = 26
HUD_WIDTH   = 32
HUD_HEIGHT  = 4

;; first index of hud in nametable as a 1D position
HUD_NAMETABLE_OFFSET = (HUD_POS_Y * HUD_WIDTH) + HUD_POS_X
HUD_POS_NAMETABLE = VRAM_NAMETABLE_0 + HUD_NAMETABLE_OFFSET

.setcpu "6502"

.export ShowHud

.proc ShowHud

    JSR FillTileMap

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
    LDA #$01         ; load index of tile to load int A

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