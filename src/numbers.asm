;; ========================================================
;;  file containing code that handles working 
;;  with decimal number and binary numbers simultaneously
;; ========================================================

;; =====================EXPORTS============================

;; ---------------------VARIABLES--------------------------
;; number:  a number that can be either in binary
;;          or decimal but every byte needs to be less than 100
;;
;; number_size: the amount of bytes numer contains

;; --------------------SUBROUTINES-------------------------

;; InitNumbers
;;  initialises varibles in file
;;  registers used: A, X

;; ConvertNumberToDecimal:
;;  converts the number in the number variable to decimal mode
;;  @param number: the number to convert
;;  @param number_size: the total amount of bytes number contains
;;  registers used: A, X, Y

;; ========================================================

.include "constants.asm"

.export number, number_size
.export InitNumbers, ConvertNumberToDecimal

.segment "BSS"

NumberVariables:
    MAX_NUMBER_SIZE = 5
    number:         .res MAX_NUMBER_SIZE    ; stored segments after conversion from binary to decimal
    number_size:    .res 1                  ; amount bytes of decimal number
NumberVariablesEnd:

.segment "CODE"

;; initialises varibles in file
;; registers used: A, X
.proc InitNumbers
    LDA #$00    ; load init value in A
    TAX         ; set X to 0, use as index
@Mloop:
    STA NumberVariables, X                      ; init variable byte at index X
    INX                                         ; increment index
    CPX NumberVariablesEnd - NumberVariables    ; compare index to amount of bytes to initialise
    BNE @Mloop                                  ; keep looping if index is still less than total bytes needed to initialise

    RTS
.endproc

;; TAKEN FROM BOOK, THEY DO RANDOM SHIT
;; converts the number in the number variable to decimal mode
;; @param number: the number to convert
;; @param number_size: the total amount of bytes number contains
;; registers used: A, X, Y
.proc ConvertNumberToDecimal
    LDX #$00    ; use X as byte index in number variable

loop:
    LDY #0          ; use Y as second nibble decimal and init with 0
    LDA number, X   ; load byte at index X in A
    CMP #50         ; compare A to 50
    BCC cmp20       ; if A <= 50, compare to 20

    SBC #50     ; subtract 50 from A
    LDY #5      ; set second nibble (tens) to 5
    BNE cmp20 

div20:
    INY     ; increment tens
    INY     ; increment tens
    SBC #20

cmp20:
    CMP #20
    BCS div20

cmp10:
    CMP #10
    BCC loopTail
    SBC #10
    INY             ; increment tens

loopTail:
    STA number, X   ; store ones into byte
    TYA             ; tranfer tens into A

    ;; shift tens value into high nibble
    ASL
    ASL
    ASL
    ASL

    ADC number, X   ; add ones value from number
    STA number, X   ; store tens + ones into byte

    INX             ; increment byte index
    CPX number_size ; compare to total amount of bytes to process
    BNE loop        ; keep looping while index is less than amount of bytes to process

end:
    RTS

.endproc