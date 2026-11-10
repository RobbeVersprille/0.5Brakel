; ---------------------------------------------------------------------
; Conveyor logic
;
; Public subroutines (callable from any file that does .import):
;   PlaceConveyor  - IN: A = low byte of tile address, X = high byte
;   RotateConveyor - IN: none; turns conveyor_dir 90 degrees
;   RemoveConveyor - IN: A = low byte of tile address, X = high byte
;
; All three may change A, X and Y.
; ---------------------------------------------------------------------
.setcpu "6502"                        ; target CPU of this file

.export PlaceConveyor                 ; make visible to other files
.export RotateConveyor                ; make visible to other files
.export RemoveConveyor                ; make visible to other files

; Conveyor directions (value of 'conveyor_dir')
CONVEYOR_DIR_MASK = %00000011         ; 4 directions: 0..3

.segment "ZEROPAGE"                   ; variables private to this file
    conveyor_ptr: .res 2              ; address of the tile being edited (low, high)
    conveyor_dir: .res 1              ; direction of the conveyor to place (0..3)

.segment "CODE"                       ; code goes into PRG-ROM

.proc PlaceConveyor
    STA conveyor_ptr                  ; store low byte of the address
    STX conveyor_ptr + 1              ; store high byte of the address

    ; TODO: write the conveyor tile for conveyor_dir to conveyor_ptr

    RTS                               ; return to caller
.endproc

.proc RotateConveyor
    LDA conveyor_dir                  ; load current direction
    CLC                               ; clear carry before adding
    ADC #$01                          ; next direction
    AND #CONVEYOR_DIR_MASK            ; wrap 3 -> 0
    STA conveyor_dir                  ; save new direction

    RTS                               ; return to caller
.endproc

.proc RemoveConveyor
    STA conveyor_ptr                  ; store low byte of the address
    STX conveyor_ptr + 1              ; store high byte of the address

    ; TODO: write the empty tile (tile 0) to conveyor_ptr

    RTS                               ; return to caller
.endproc
