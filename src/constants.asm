
;; ----------------------------------------------
;; PPU CONSTANTS
;; ----------------------------------------------

SCREEN_WIDTH = $20
SCREEN_HEIGHT = $1E

PPUSCROLL   = $2005
PPUADDR     = $2006
PPUDATA     = $2007

VRAM_NAMETABLE_0 = $2000
VRAM_ATTRTABLE_0 = $23C0

ATTRSIZE = 4

;; ==============================================
;;  HUD CONSTANTS
;; ==============================================

HUD_WIDTH   = SCREEN_WIDTH
HUD_HEIGHT  = 7
HUD_POS_X   = 0
HUD_POS_Y   = SCREEN_HEIGHT - HUD_HEIGHT

;; ==============================================
;;  TILE CONSTANTS
;; ==============================================

;; border tiles
TOP_LEFT_CORNER     = $0A
TOP_RIGHT_CORNER    = $0B
BOTTOM_LEFT_CORNER  = $0C
BOTTOM_RIGHT_CORNER = $0D
HORIZONTAL_EDGE     = $0E
VERTICAL_EDGE       = $0F
EMPTY_TILE          = $10

;; item tiles
PLACEHOLDER_TILE    = $11

;; number tiles
NUMBER_TILE         = $12