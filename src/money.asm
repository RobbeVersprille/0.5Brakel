;; ========================================================
;;  Handles the money of the player
;; ========================================================

;; =====================EXPORTS============================

;; ---------------------VARIABLES--------------------------
;; money:   variable containing money value every
;;          byte should be between [0-99]

;; --------------------SUBROUTINES-------------------------
;; InitMoney
;;  Initialises money variable with all 0s
;;  registers used: A, X

;; AddValue
;;  adds a decimal value to the money variable
;;  this keeps every byte between [0-99]
;;  @param A: value to add (THIS MUST BE A VALUE IN [0-99]!!!)
;;  @param X: add offset (if you want to add 1000 => A = 10, X = 1)
;;  registers used: A, X

;; ========================================================

.include "constants.asm"

.export money
.export InitMoney, AddValue

.segment "BSS"
money:  .res MONEY_BYTES    ; reserve an amount of bytes to store player money

.segment "CODE"

;; Initialises money variable with all 0s
;; registers used: A, X
.proc InitMoney

    LDA #$00    ; load init value in A
    TAX         ; set X to 0 to use as index for money byte
@loop:
    STA money, X        ; store init value into money byte at index X
    INX                 ; increment index
    CPX #MONEY_BYTES    ; check if index < MONEY_BYTES
    BNE @loop           ; while index < MONEY_BYTES keep looping

    RTS

.endproc

;; adds a decimal value to the money variable
;; this keeps every byte between [0-99]
;; @param A: value to add (THIS MUST BE A VALUE IN [0-99]!!!)
;; @param X: add offset (if you want to add 1000 => A = 10, X = 1)
;; registers used: A, X
.proc AddValue
    CLC             ; clear carry
    ADC money, X    ; add value to byte at offset index X
    STA money, X    ; store added value back
    CMP #100        ; compare current value to 100
    BCC end         ; go to the end if byte is still less than 100

    ;; since previous byte was >= 100
    SEC             ; set carry for normal subtraction
    SBC #100        ; subtract 100 from the value
    STA money, X    ; store the new value back

@handleOverflow:
    ;; check overflow for next bytes
    INX             ; increment byte offset
    CPX MONEY_BYTES ; compare current byte offset to total money bytes
    BEQ end         ; if they are equal, go to the end

    INC money, X        ; increment next byte
    BCS @handleOverflow ; if the previous increment caused an overflow, check next byte 

end:
    RTS

.endproc