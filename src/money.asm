;; ========================================================
;;  Handles the money of the player
;; ========================================================

;; =====================EXPORTS============================

;; InitMoney
;; Initialises money variable with all 0s
;; registers used: A, X

;; ========================================================

.include "constants.asm"

.export InitMoney

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