
;; ----------------------------------------------
;; PPU CONSTANTS
;; ----------------------------------------------

; PPU registers
PPU_CTRL = $2000                      ; NMI enable, pattern tables, nametable select
PPU_MASK = $2001                      ; show / hide background and sprites
PPU_STATUS = $2002                    ; VBlank flag, reading it resets the address latch
PPU_SCROLL = $2005                    ; scroll position, written twice (x then y)
PPU_ADDR = $2006                      ; VRAM address, written twice (high then low)
PPU_DATA = $2007                      ; VRAM data

; Nametable
NAMETABLE_0 = $2000                   ; first tile of nametable 0
ATTRIBUTE_0 = $23C0                   ; first attribute byte of nametable 0
PALETTE_1_ALL = %01010101             ; attribute byte: all four 16x16 blocks use background palette 1
PALETTE_BYTES = 12                    ; size of PaletteData in chr.asm (3 palettes of 4 colours)

SCREEN_WIDTH = $20
SCREEN_HEIGHT = $1E

ATTR_DIM = 2

;; ==============================================
;;  HUD CONSTANTS
;; ==============================================

HUD_WIDTH   = SCREEN_WIDTH
HUD_HEIGHT  = 7
HUD_POS_X   = 0
HUD_POS_Y   = SCREEN_HEIGHT - HUD_HEIGHT

.enum
    WORKER_AMOUNT_ITEM
    FOOD_AMOUNT_ITEM
    MONEY_AMOUNT_ITEM

    TBD1_ITEM
    CONVEYER_ITEM
    TBD2_ITEM
    TBD3_ITEM
    TBD4_ITEM
    TBD5_ITEM
    WORKER_ITEM
    TBD6_ITEM
    
    MONEY_DEBUG_ITEM
.endenum

;; ==============================================
;;  MONEY CONSTANTS
;; ==============================================

MONEY_BYTES = 5

;; ==============================================
;;  PALETTE ENUM
;; ==============================================

;; background palette enums
.enum
    BG_PAL_1
    BG_PAL_2
    BG_PAL_3
    BG_PAL_4
.endenum

;; sprite palette enums
.enum
    CURSOR_PALETTE
    GHOST_PALLETTE
    SP_PAL_3
    SP_PAL_4
.endenum

;; ==============================================
;;  TILE CONSTANTS
;; ==============================================

.enum
    EMPTY_TILE
    
    CONVEYER_RIGHT
    CONVEYER_DOWN
    CONVEYER_LEFT
    CONVEYER_UP

    CURSOR_TILE

    BREAD_TILE
    SAND_TILE
    COIN_TILE
    WHEAT_TILE
    PLANK_TILE
    LOG_TILE
    STONE_TILE
    DUVEL_TILE

    WORKER_TILE

    ;; border tiles
    TOP_LEFT_CORNER
    TOP_RIGHT_CORNER
    BOTTOM_LEFT_CORNER
    BOTTOM_RIGHT_CORNER
    HORIZONTAL_EDGE
    VERTICAL_EDGE
    EMPTY_HUD_TILE

    ;; item tiles
    PLACEHOLDER_TILE

    TILE_ID_17
    TILE_ID_18
    TILE_ID_19
    TILE_ID_1A
    TILE_ID_1B
    TILE_ID_1C
    TILE_ID_1D
    TILE_ID_1E
    TILE_ID_1F
    TILE_ID_20
    TILE_ID_21
    TILE_ID_22
    TILE_ID_23
    TILE_ID_24
    TILE_ID_25
    TILE_ID_26
    TILE_ID_27
    TILE_ID_28
    TILE_ID_29
    TILE_ID_2A
    TILE_ID_2B
    TILE_ID_2C
    TILE_ID_2D
    TILE_ID_2E
    TILE_ID_2F

    ;; number tiles
    NUMBER_TILE_0
    NUMBER_TILE_1
    NUMEBR_TILE_2
    NUMBER_TILE_3
    NUMBER_TILE_4
    NUMBER_TILE_5
    NUMBER_TILE_6
    NUMBER_TILE_7
    NUMBER_TILE_8
    NUMBER_TILE_9

    TILE_ID_3A
    TILE_ID_3B
    TILE_ID_3C
    TILE_ID_3D
    TILE_ID_3E
    TILE_ID_3F
    TILE_ID_40

    ;; font tiles
    FONT_TILE_A
    FONT_TILE_B
    FONT_TILE_C
    FONT_TILE_D
    FONT_TILE_E
    FONT_TILE_F
    FONT_TILE_G
    FONT_TILE_H
    FONT_TILE_I
    FONT_TILE_J
    FONT_TILE_K
    FONT_TILE_L
    FONT_TILE_M
    FONT_TILE_N
    FONT_TILE_O
    FONT_TILE_P
    FONT_TILE_Q
    FONT_TILE_R
    FONT_TILE_S
    FONT_TILE_T
    FONT_TILE_U
    FONT_TILE_V
    FONT_TILE_W
    FONT_TILE_X
    FONT_TILE_Y
    FONT_TILE_Z
.endenum
