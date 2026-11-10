; ---------------------------------------------------------------------
; Palette data and CHR-ROM tiles
; ---------------------------------------------------------------------
.setcpu "6502"                        ; target CPU of this file

.export PaletteData                   ; make visible to other files

; Colours and the animated sub-palette
COL_BACKDROP = $1A                    ; shared backdrop colour

CONVEYOR_DARK     = $00                    ; dark grey
CONVEYOR_LIGHT    = $10                    ; light grey
CONVEYOR_BLACK    = $0F                    ; black

.segment "CODE"                       ; palette lives in PRG-ROM

; ====================================================
; BACKGROUND + SPRITE PALETTES (32 bytes)
; ====================================================

PaletteData:
        .byte COL_BACKDROP, COL_BACKDROP, COL_BACKDROP, COL_BACKDROP ; default
        .byte COL_BACKDROP, CONVEYOR_DARK, CONVEYOR_LIGHT, CONVEYOR_BLACK ; conveyors
        .byte COL_BACKDROP, $11, $21, $01 ; blueprint

; ====================================================
; CHR-ROM: 8 KB total
; ====================================================

.segment "CHR"

; Tile 0: empty tile (16 bytes)
.res 16, $00

.byte $FF,$CC,$66,$33,$33,$66,$CC,$FF,$FF,$33,$99,$CC,$CC,$99,$33,$FF ; right   horizontal conveyor A >
.byte $FF,$66,$33,$99,$99,$33,$66,$FF,$FF,$99,$CC,$66,$66,$CC,$99,$FF ; right   horizontal conveyor B >
.byte $C3,$E7,$BD,$99,$C3,$E7,$BD,$99,$BD,$99,$C3,$E7,$BD,$99,$C3,$E7 ; down    vertical conveyor A v
.byte $99,$C3,$E7,$BD,$99,$C3,$E7,$BD,$E7,$BD,$99,$C3,$E7,$BD,$99,$C3 ; down    vertical conveyor B v

; Mirrored copies for the opposite directions.
.byte $FF,$33,$66,$CC,$CC,$66,$33,$FF,$FF,$CC,$99,$33,$33,$99,$CC,$FF ; left  A = horizontal A mirrored <
.byte $FF,$66,$CC,$99,$99,$CC,$66,$FF,$FF,$99,$33,$66,$66,$33,$99,$FF ; left  B = horizontal B mirrored <
.byte $99,$BD,$E7,$C3,$99,$BD,$E7,$C3,$E7,$C3,$99,$BD,$E7,$C3,$99,$BD ; up    A = vertical A flipped ^
.byte $BD,$E7,$C3,$99,$BD,$E7,$C3,$99,$C3,$99,$BD,$E7,$C3,$99,$BD,$E7 ; up    B = vertical B flipped ^
