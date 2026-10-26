; Controlls:
;   A-Button      =
;   B-Button      = 
;   UP Arrow      = 
;   DOWN Arrow    = 
;   LEFT Arrow    = 
;   RIGHT Arrow   = 
;   SELECT-Button =
;   START-Button  =

.segment "HEADER"
    .byte "NES", $1A           ; Identification bytes for an NES ROM
    .byte 2                    ; 2 PRG-ROM banks of 16 KB = 32 KB
    .byte 1                    ; 1 CHR-ROM bank of 8 KB = 8 KB
    .byte $00                  ; Mapper 0, horizontal mirroring
    .byte $00                  ; Other header settings
    .byte $00, $00, $00, $00   ; Unused header bytes
    .byte $00, $00, $00, $00   ; Additional reserved header bytes


.segment "ZEROPAGE"        
    buttons:     .res 1        ; New button input from current frame
    old_buttons: .res 1        ; Old button input from previous frame


.segment "CODE"



reset:
    SEI             ; Disable CPU interrupts
    CLD             ; Disable decimal mode

    LDX #$40        ; Value to disable the APU-frame-IRQ (audio)
    STX $4017       ; Disable APU frame IRQ

    LDX #$FF        ; X = #$FF
    TXS             ; Initialize stack pointer

    INX             ; X = 0 (FF + 1 = 0 )
    STX $2000       ; Disable NMI
    STX $2001       ; Disable rendering
    STX $4010       ; Disable DMC IRQ

;NOTE: Maybe we need 2 vBlank waits but not sure (Needs to be tested)    
wait_vblank:        ; Wait for the PPU to start
    BIT $2002       ; Reads the PPU-status; bit 7 = VBlank on/off
    BPL wait_vblank ; Loop util bit 7 = nul (negative bit)

    ; Initialize your game state
    LDA #$00        
    STA buttons
    STA old_buttons

    ; FOREVER LOOP
    forever:
        JMP forever

; INTERRUPTROUTINES
nmi:
    RTI                    ; Return from NMI-interrupt

irq:
    RTI                    ; Return from IRQ-interrupt


; INTERRUPTVECTOR
.segment "VECTORS"

.word nmi                  ; NMI-vector
.word reset                ; RESET-vector
.word irq                  ; IRQ/BRK-vector

; CHARACTER ROM
.segment "CHR" 