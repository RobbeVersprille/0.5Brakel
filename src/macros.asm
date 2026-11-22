;; GLOBAL MACROS

;; ========================================================
;;  Numbers macros
;; ========================================================

;; copies a variable with size amount of bytes into number variable
;; needed includes: number, number_size
.macro FillBinaryNumber number_addr, size
    .scope
        LDA #size        ; load total size in A
        STA number_size ; store total size in number_size

        LDX #$00    ; set index to 0
    @loop:
        LDA number_addr, X  ; load byte at index X in A
        STA number, X       ; store byte in binary number at index X

        INX         ; increment index
        CPX #size    ; compare index to amount of bytes to copy
        BNE @loop   ; keep looping while index is smaller
    .endscope
.endmacro