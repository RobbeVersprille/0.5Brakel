.import TransferOamData, oam_copy ; importing OAM

;macros
MAX_REFINERIES = 32 ; Maximum number of refineries allowed
ITEM_WOOD = $00                 ;Wood item ID
ITEM_STONE = $01                ;Stone item ID
ITEM_WHEAT = $02                ;Wheat item ID

.segment "ZEROPAGE"          ; Zero page variables

refinery_index: .res 1                    ; Reserve 1 byte for refinery index
refinery_wheat: .res MAX_REFINERIES       ; Reserve 1 byte for wheat ingredient
refinery_wood: .res MAX_REFINERIES        ; Reserve 1 byte for wood ingredient
refinery_stone: .res MAX_REFINERIES       ; Reserve 1 byte for stone ingredient
refinery_output: .res MAX_REFINERIES      ; Reserve 1 byte for output

.segment "CODE"              ; Code segment (hence the name)

.proc RefineryInit          ; Initialize refinery
    LDX #$00                     ; Start at index zero
    LDA #$00                     ; Set everything to zero with this value

refineryInitLoop:                    ; Loop through all refinery slots
    STA refinery_wheat, X                ; Reset wheat inventory
    STA refinery_wood, X                 ; Reset wood inventory
    STA refinery_stone, X                ; Reset stone inventory
    STA refinery_output, X               ; Reset output potion
    INX                          ; Move to next refinery
    CPX #MAX_REFINERIES          ; Check if all refineries were initialized
    BNE refineryInitLoop           ; If not, continue the loop

    RTS                          ; Return from subroutine
.endproc                     ; End subroutine

