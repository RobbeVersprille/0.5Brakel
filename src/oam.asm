;; ========================================================
;;  Handling OAM data
;; ========================================================

;; @param: nothing
;; @return: nothing
;; InitOamData: Initialises variables used by oam
;; registers used: A, X

;; @param: nothing
;; @return: nothing
;; TransferOamData: loads the full page at oam_copy into ppu oam data
;; registers used: A

.export oam_copy
.export InitOamData, TransferOamData

OAMDMA = $4014

.segment "OAM"

;; copy of oam used for dma transfer, never directly load data into ppu oam data, only use this copy
oam_copy: .res 256

.segment "CODE"

.proc InitOamData
    LDA #$00    ; load reset value into a
    TAX         ; transfer value 0 to x to use as counter
@loop:
    STA oam_copy, X ; store reset value in oam_copy at index of X
    INX             ; increment counter
    BNE @loop       ; if X hasnt overflowed into 0, keep looping

    RTS
.endproc

.proc TransferOamData
    LDA #>oam_copy  ; load high byte of oam copy into a
    STA OAMDMA      ; store high byte of oam copy into OAMDMA register to start oam dma transfer

    RTS
.endproc