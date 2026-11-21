; ---------------------------------------------------------------------
; Palette data and CHR-ROM tiles
; ---------------------------------------------------------------------
.setcpu "6502"                        ; target CPU of this file

.export PaletteData                   ; make visible to other files

; Colours and the animated sub-palette
COL_BACKDROP = $1A                         ; shared backdrop colour

CONVEYOR_DARK     = $00                    ; dark grey
CONVEYOR_LIGHT    = $10                    ; light grey
CONVEYOR_BLACK    = $0F                    ; black

;TODO RENAME THESE VARIABLES
CURSOR_COLOR2     = $30
CURSOR_COLOR3     = $28
CURSOR_COLOR4     = $10

.segment "CODE"                       ; palette lives in PRG-ROM

; ====================================================
; BACKGROUND + SPRITE PALETTES (32 bytes)
; ====================================================

PaletteData:
    ;Backdrop pallets
    .byte COL_BACKDROP, CONVEYOR_DARK, CONVEYOR_LIGHT, CONVEYOR_BLACK
    .byte COL_BACKDROP, CONVEYOR_DARK, CONVEYOR_LIGHT, CONVEYOR_BLACK
    .byte COL_BACKDROP, CONVEYOR_DARK, CONVEYOR_LIGHT, CONVEYOR_BLACK
    .byte COL_BACKDROP, CONVEYOR_DARK, CONVEYOR_LIGHT, CONVEYOR_BLACK
    ;Sprite pallets
    .byte COL_BACKDROP, CURSOR_COLOR2, CURSOR_COLOR3, CURSOR_COLOR4
    .byte COL_BACKDROP, CURSOR_COLOR2, CURSOR_COLOR3, CURSOR_COLOR4
    .byte COL_BACKDROP, CURSOR_COLOR2, CURSOR_COLOR3, CURSOR_COLOR4
    .byte COL_BACKDROP, CURSOR_COLOR2, CURSOR_COLOR3, CURSOR_COLOR4
    

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

.byte $18,$18,$4E,$39,$08,$14,$14,$12,$00,$00,$77,$77,$00,$00,$00,$36   ; worker tile

.byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$3f,$3f,$38,$30,$30,$30   ; top-left corner
.byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$fc,$fc,$1c,$0c,$0c,$0c   ; top-right corner
.byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$30,$30,$30,$38,$3f,$3f,$00,$00   ; bottom-left corner
.byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$0c,$0c,$0c,$1c,$fc,$fc,$00,$00   ; bottom-right corner
.byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00,$ff,$ff,$00,$00,$00   ; horizontal edge
.byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$18,$18,$18,$18,$18,$18,$18,$18   ; vertical edge
.byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00   ; empty
.byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$1C,$22,$22,$04,$08,$08,$00,$08   ; placeholder tile

.byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$1C,$3E,$63,$63,$63,$63,$3E,$1C   ; 0
.byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$1C,$3C,$2C,$0C,$0C,$0C,$0C   ; 1
.byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$1C,$3E,$66,$66,$0C,$18,$3E,$3E   ; 2
.byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$1C,$3E,$26,$0C,$0C,$26,$3E,$1C   ; 3
.byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$60,$C0,$D8,$FE,$FE,$18,$18,$18   ; 4
.byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3E,$3E,$30,$3C,$06,$06,$3E,$3C   ; 5
.byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3C,$62,$60,$7C,$66,$66,$7C,$38   ; 6
.byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3E,$7E,$46,$0C,$0C,$18,$18,$18   ; 7
.byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$7C,$C6,$C6,$7C,$C6,$C6,$FE,$38   ; 8
.byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$1C,$3E,$66,$66,$3E,$06,$46,$3C   ; 9

.byte $E7,$81,$81,$00,$00,$81,$81,$E7,$00,$00,$00,$00,$00,$00,$00,$00 ; Cursor sprite

