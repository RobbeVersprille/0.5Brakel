
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
;;  FACTORY CONSTANTS
;; ==============================================

MAX_FACTORIES = 16              ;Set a limit for the number of factories in the game

;; ==============================================
;;  REFINERY CONSTANTS
;; ==============================================

MAX_REFINERIES = 32 ; Maximum number of refineries allowed

;; ==============================================
;;  HUD CONSTANTS
;; ==============================================

HUD_WIDTH   = SCREEN_WIDTH
HUD_HEIGHT  = 7
HUD_POS_X   = 0
HUD_POS_Y   = SCREEN_HEIGHT - HUD_HEIGHT

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

    REFINERY_TILE

    CURSOR_TILE

    BREAD_TILE
    SAND_TILE
    COIN_TILE
    WHEAT_TILE
    PLANK_TILE
    LOG_TILE
    STONE_TILE
    DUVEL_TILE
    FACTORY_TILE
    
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
.endenum
