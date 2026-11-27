;; ========================================================
;;  Contains code for drawing string to the screen
;; ========================================================

;; ========================EXPORTS=========================

;; -----------------------VARIABLES------------------------
;; string_ptr: location of first string character
;; string_size: amount of characters in string

;; ----------------------SUBROUTINES-----------------------

;; InitText
;;  initialises variables of string
;;  registers used: A, X

;; DrawText
;;  Draw Text copied to string_copy with size string_size to the nametable
;;  This subroutine expects PPU_ADDR to be set already
;;  @param string_ptr: location of first string character
;;  @param string_size: amount of characters in string
;;  registers used: A, X

;; =========================================================

.include "constants.asm"

.exportzp string_ptr
.export string_size
.export InitText, DrawText

.segment "ZEROPAGE"
    string_ptr: .res 2    ; reserves 2 bytes to store a pointer to the start of the string

.segment "BSS"
    string_size: .res 1               ; amount of chars in string

.segment "CODE"

;; initialises variables of string
;; registers used: A, X
.proc InitText

    ;; reset all variable bytes to 0
    LDA #$00
    STA string_ptr
    STA string_ptr + 1
    STA string_size

    RTS
.endproc

;; Draw Text copied to string_copy with size string_size to the nametable
;; This subroutine expects PPU_ADDR to be set already
;; @param string_ptr: location of first string character
;; @param string_size: amount of characters in string
;; registers used: A, Y
.proc DrawText
    LDY #0  ; load index of first character in y

@loop:
    LDA (string_ptr), Y   ; get character at index y in pointer (*(ptr + Y))
    STA PPU_DATA        ; write character to screen

    INY             ; increment character index
    CPY string_size   ; compare to total characters
    BNE @loop       ; keep looping while character index is less that total characters

    RTS
.endproc