.include "constants.asm"
.import TransferOamData, oam_copy ; importing OAM
.export InitRefinery, PlaceRefinery, RotateRefinery
;macros
ITEM_WOOD = $00                 ;Wood item ID
ITEM_STONE = $01                ;Stone item ID
ITEM_WHEAT = $02                ;Wheat item ID
DIRECTION_MASK = %00000011      ;direction mask to make the rotation wrap 3 -> 0
.segment "ZEROPAGE"          ; Zero page variables

refinery_index: .res 1                    ; Reserve 1 byte for refinery index
refinery_tile_ptr: .res 2                 ; address of the refinery tile
refinery_dir: .res 1                      ; the direction of the refinery
refinery_draw_hi: .res 1
refinery_draw_lo: .res 1

.segment "BSS"              ; BSS variables

refinery_wheat: .res MAX_REFINERIES       ; Reserve 1 byte for wheat ingredient
refinery_wood: .res MAX_REFINERIES        ; Reserve 1 byte for wood ingredient
refinery_stone: .res MAX_REFINERIES       ; Reserve 1 byte for stone ingredient
refinery_output: .res MAX_REFINERIES      ; Reserve 1 byte for output
refinery_x: .res MAX_REFINERIES             ; x position
refinery_y: .res MAX_REFINERIES             ; y position
refinery_state: .res MAX_REFINERIES         ; the state of the refinery
    IS_PLACED = %10000000                   ; is the refinery placed? bit 0
    
.segment "CODE"              ; Code segment (hence the name)

.proc InitRefinery          ; Initialize refinery
    LDX #$00                     ; Start at index zero
    LDA #$00                     ; Set everything to zero with this value

    STA refinery_dir
refineryInitLoop:                    ; Loop through all refinery slots
    STA refinery_wheat, X                ; Reset wheat inventory
    STA refinery_wood, X                 ; Reset wood inventory
    STA refinery_stone, X                ; Reset stone inventory
    STA refinery_output, X               ; Reset output potion
    STA refinery_x, X
    STA refinery_y, X

    INX                          ; Move to next refinery
    CPX #MAX_REFINERIES          ; Check if all refineries were initialized
    BNE refineryInitLoop           ; If not, continue the loop

    RTS                          ; Return from subroutine
.endproc                     ; End subroutine


;------------------------------------------------------------------------
; IN: A = low byte, X = high byte of the PPU tile address (nametable 0)
; OUT: carry clear = placed (X = slot), carry set = no free slot
; Writes to the PPU, so call it with rendering off or during VBlank.
;------------------------------------------------------------------------
.proc PlaceRefinery
    STA refinery_tile_ptr                  ; store low byte of the address
    STX refinery_tile_ptr + 1              ; store high byte of the address

    BIT PPU_STATUS                    ; reset the PPU address latch
    LDA refinery_tile_ptr + 1         ; high byte of the tile address
    STA PPU_ADDR                      ; first address write
    LDA refinery_tile_ptr             ; low byte of the tile address
    STA PPU_ADDR                      ; second address write
    LDA refinery_dir                  ; direction 0..3
    CLC                               ; clear carry before adding
    ADC #REFINERY_TILE                ; tile index = first refinery tile
    STA PPU_DATA                      ; write the tile (the animation never rewrites it)

    RTS                               ; return
.endproc

.proc RotateRefinery
    LDA refinery_dir                  ; load current direction
    CLC                               ; clear carry before adding
    ADC #$01                          ; next direction
    AND #DIRECTION_MASK               ; wrap 3 -> 0
    STA refinery_dir                  ; save new direction

    RTS                               ; return
.endproc

.proc DrawRefinery
    LDA #REFINERY_TILE
    LDA refinery_y, X                 
    LSR A                            ; divide by 2
    LSR A                            ; divide by 4
    LSR A                            ; divide by 8
    CLC                              ; clear carry
    ADC #$20                         ; Add the nametable 0 base address ($2000)
    STA refinery_draw_hi             ; Save the high byte

    LDA refinery_y, X                 
    AND #%00000111                   ; Keep the row inside this block of 8 rows (0-7)
    ASL A                            ; multiply by 2
    ASL A                            ; multiply by 4
    ASL A                            ; multiply by 8
    ASL A                            ; multiply by 16
    ASL A                            ; multiply by 32 
    ORA refinery_x, X                 ; Add the column (0-31)
    STA refinery_draw_lo              ; Save the low byte

    STA refinery_dir
    BEQ drawTile

    drawTile:
    LDA #REFINERY_TILE                   ; Load refinery tile ID
    STA PPU_DATA                        ; Write tile to PPU

    LDA refinery_draw_lo                 ; Load current low address
    CLC                                 ; Clear carry
    ADC #$20                            ; Move down one nametable row
    STA refinery_draw_lo                 ; Store updated low address
    LDA refinery_draw_hi                 ; Load current high address
    ADC #$00                            ; Add carry if necessary
    STA refinery_draw_hi                 ; Store updated high address

    RTS
.endproc