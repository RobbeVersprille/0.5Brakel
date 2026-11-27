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

GHOST_COLOR2      = $13
GHOST_COLOR3      = $20
GHOST_COLOR4      = $0D


.segment "CODE"                       ; palette lives in PRG-ROM

; ====================================================
; BACKGROUND + SPRITE PALETTES (32 bytes)
; ====================================================
; Background palette 1 is reserved for conveyors. ConveyorUpload swaps its
; colours 1 and 2 (bytes 5 and 6 below) to animate every conveyor at once,
; so nothing else may use palette 1.

PaletteData:
    ;Backdrop pallets
    .byte COL_BACKDROP, COL_BACKDROP, COL_BACKDROP, COL_BACKDROP
    .byte COL_BACKDROP, CONVEYOR_DARK, CONVEYOR_LIGHT, CONVEYOR_BLACK ; Conveyor pallet (has colour swapping for animation)
    .byte COL_BACKDROP, CONVEYOR_DARK, CONVEYOR_LIGHT, CONVEYOR_BLACK
    .byte COL_BACKDROP, CONVEYOR_DARK, CONVEYOR_LIGHT, CONVEYOR_BLACK
    ;Sprite pallets
    .byte COL_BACKDROP, CURSOR_COLOR2, CURSOR_COLOR3, CURSOR_COLOR4 ; cursor pallet
    .byte COL_BACKDROP, GHOST_COLOR2,  GHOST_COLOR3, GHOST_COLOR4 ; ghost pallet
    .byte COL_BACKDROP, CURSOR_COLOR2, CURSOR_COLOR3, CURSOR_COLOR4
    .byte COL_BACKDROP, CURSOR_COLOR2, CURSOR_COLOR3, CURSOR_COLOR4
    

; ====================================================
; CHR-ROM: 8 KB = two pattern tables of 4 KB
;
;   CHR0 = pattern table 0 ($0000) = animation frame A
;   CHR1 = pattern table 1 ($1000) = animation frame B
;
; Every animation step the NMI flips PPUCTRL bit 4 (background pattern
; table), so the same nametable entry shows frame A or frame B.
; The nametable is never rewritten.
;
; RULES
;   - an animated tile has the SAME index in CHR0 and CHR1
;   - a tile that never animates must be in BOTH tables, same index
;     (put it in the StaticTiles macro below)
;   - conveyor tile index = CONVEYOR_FIRST_TILE + direction
;     (0 = right, 1 = down, 2 = left, 3 = up)
;   - sprite tiles live in CHR0 (keep PPUCTRL bit 3 = 0)
;
; Frame B is frame A moved 1 px in the belt direction. Swapping palette
; colours 1 and 2 moves the pattern another 2 px (the stripes are 2 px wide),
; so the 4 steps are: A, B, A swapped, B swapped = 0, 1, 2, 3 px.
; ====================================================

.macro StaticTiles                    ; tiles that never animate 
    ; add every non-animated tile here (grass, font, UI, buildings)
    .byte $E7,$81,$81,$00,$00,$81,$81,$E7,$00,$00,$00,$00,$00,$00,$00,$00 ; Cursor sprite
    .byte $1C,$2A,$65,$93,$C7,$AE,$5C,$38,$1C,$36,$5B,$EF,$BF,$DE,$7C,$38 ; Bread
    .byte $08,$1C,$1A,$3E,$56,$E3,$85,$20,$00,$00,$04,$00,$28,$1C,$7A,$DF ; Coin
    .byte $00,$3C,$66,$66,$66,$66,$3C,$00,$3C,$42,$99,$99,$99,$99,$42,$3C ; Sand
    .byte $04,$0A,$06,$0C,$20,$30,$C0,$00,$00,$04,$09,$12,$3C,$70,$20,$40 ; Wheat
    .byte $0C,$12,$27,$4E,$DC,$F8,$70,$20,$0C,$1E,$3D,$7A,$F4,$A8,$50,$20 ; Planks
    .byte $1C,$3A,$79,$F5,$CB,$96,$FE,$7C,$1C,$26,$47,$8F,$BF,$FE,$FE,$7C ; Logs
    .byte $0C,$5E,$3B,$5F,$A6,$84,$48,$30,$0C,$52,$35,$79,$FE,$FC,$78,$30 ; Stone
    .byte $FF,$7E,$42,$81,$81,$66,$18,$7E,$81,$42,$7E,$FF,$FF,$7E,$18,$7E ; DUVEL
    
    .byte $18,$18,$4E,$39,$08,$14,$14,$12,$00,$00,$77,$77,$00,$00,$00,$36   ; worker tile

    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$3f,$3f,$38,$30,$30,$30   ; top-left corner HUD
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$fc,$fc,$1c,$0c,$0c,$0c   ; top-right corner HUD
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$30,$30,$30,$38,$3f,$3f,$00,$00   ; bottom-left corner HUD
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$0c,$0c,$0c,$1c,$fc,$fc,$00,$00   ; bottom-right corner HUD
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00,$ff,$ff,$00,$00,$00   ; horizontal edge HUD
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$18,$18,$18,$18,$18,$18,$18,$18   ; vertical edge HUD
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00   ; empty tile HUD
    .byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$1C,$22,$22,$04,$08,$08,$00,$08   ; placeholder tile HUD

    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding

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
    .byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$60,$60,$00,$00,$60,$60,$00   ; :

    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding    
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding
    .res 16, $00    ; padding

    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$10,$28,$28,$38,$44,$44,$44   ; A
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$38,$44,$44,$58,$44,$44,$78   ; B
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$3c,$40,$40,$40,$40,$40,$3c   ; C
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$70,$48,$44,$44,$44,$44,$78   ; D
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$3c,$40,$40,$78,$40,$40,$7c   ; E
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$3c,$40,$40,$70,$40,$40,$40   ; F
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$38,$44,$40,$5c,$44,$44,$38   ; G
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$44,$44,$44,$7c,$44,$44,$44   ; H
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$7c,$10,$10,$10,$10,$10,$7c   ; I
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$04,$04,$04,$04,$44,$44,$38   ; J
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$44,$58,$60,$60,$50,$48,$44   ; K
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$40,$40,$40,$40,$40,$40,$7c   ; L
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$28,$38,$38,$54,$44,$44,$44   ; M
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$64,$64,$54,$54,$54,$4c,$4c   ; N
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$38,$44,$44,$44,$44,$44,$38   ; O
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$38,$44,$44,$78,$40,$40,$40   ; P
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$38,$44,$44,$44,$54,$48,$34   ; Q
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$38,$44,$44,$78,$50,$48,$44   ; R
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$3c,$40,$40,$38,$04,$04,$78   ; S
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$7c,$10,$10,$10,$10,$10,$10   ; T
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$44,$44,$44,$44,$44,$44,$38   ; U
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$44,$44,$44,$28,$28,$10,$10   ; V
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$44,$44,$44,$54,$38,$38,$28   ; W
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$44,$44,$28,$10,$28,$44,$44   ; X
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$44,$44,$28,$28,$10,$10,$10   ; Y
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$7c,$04,$08,$10,$20,$40,$7c   ; Z
.endmacro                             ; expanded once in CHR0 and once in CHR1

.segment "CHR0"                       ; pattern table 0 = frame A

.res 16, $00                          ; tile $00: empty tile (16 bytes)

.byte $FF,$CC,$66,$33,$33,$66,$CC,$FF,$FF,$33,$99,$CC,$CC,$99,$33,$FF ; tile $01 right A >
.byte $C3,$E7,$BD,$99,$C3,$E7,$BD,$99,$BD,$99,$C3,$E7,$BD,$99,$C3,$E7 ; tile $02 down  A v
.byte $FF,$33,$66,$CC,$CC,$66,$33,$FF,$FF,$CC,$99,$33,$33,$99,$CC,$FF ; tile $03 left  A <
.byte $99,$BD,$E7,$C3,$99,$BD,$E7,$C3,$E7,$C3,$99,$BD,$E7,$C3,$99,$BD ; tile $04 up    A ^

StaticTiles                           ; Expand StaticTiles macro here for CHR0

.segment "CHR1"                       ; pattern table 1 = frame B

.res 16, $00                          ; tile $00: empty tile (16 bytes), same as CHR0

.byte $FF,$66,$33,$99,$99,$33,$66,$FF,$FF,$99,$CC,$66,$66,$CC,$99,$FF ; tile $01 right B >
.byte $99,$C3,$E7,$BD,$99,$C3,$E7,$BD,$E7,$BD,$99,$C3,$E7,$BD,$99,$C3 ; tile $02 down  B v
.byte $FF,$66,$CC,$99,$99,$CC,$66,$FF,$FF,$99,$33,$66,$66,$33,$99,$FF ; tile $03 left  B <
.byte $BD,$E7,$C3,$99,$BD,$E7,$C3,$99,$C3,$99,$BD,$E7,$C3,$99,$BD,$E7 ; tile $04 up    B ^

StaticTiles                           ; Expand StaticTiles macro here for CHR1
