; Besturing:
;   A-knop       = rode achtergrond, zwart punt
;   B-knop       = blauwe achtergrond, wit punt
;   Pijl omhoog  = punt omhoog bewegen
;   Pijl omlaag  = punt omlaag bewegen
;   Pijl links   = punt naar links bewegen
;   Pijl rechts  = punt naar rechts bewegen

.segment "HEADER" ; Header is meestal 16 bytes        
    .byte "NES", $1A           ; Herkenningsbytes voor een NES-ROM
    .byte 2                    ; 2 PRG-ROM banken van 16 KB = 32 KB
    .byte 1                    ; 1 CHR-ROM bank van 8 KB = 8 KB
    .byte $00                  ; Mapper 0, horizontale mirroring
    .byte $00                  ; Overige headerinstellingen 
    .byte $00, $00, $00, $00   ; Ongebruikte headerbytes
    .byte $00, $00, $00, $00   ; Extra ongebruikte headerbytes


.segment "ZEROPAGE"        
    buttons:     .res 1        ; Bewaart de huidige controllerknoppen
    old_buttons: .res 1        ; Bewaart de knoppen van de vorige frame
    dot_x:       .res 1        ; Horizontale positie van het punt
    dot_y:       .res 1        ; Verticale positie van het punt
    bg_color:    .res 1        ; Kleur van de achtergrond
    dot_color:   .res 1        ; Kleur van het punt


.segment "CODE"



reset:
    SEI             ; Disable interrupts
    CLD             ; Disable decimal mode
    LDX #$40
    STX $4017       ; Disable APU frame IRQ
    LDX #$FF
    TXS             ; Initialize stack pointer
    INX             ; X = 0
    STX $2000       ; Disable NMI
    STX $2001       ; Disable rendering
    STX $4010       ; Disable DMC IRQ

    ; Wait for the PPU to start
wait_vblank:
    BIT $2002
    BPL wait_vblank

    ; Initialize your game state
    LDA #$00
    STA buttons
    STA old_buttons
    STA bg_color
    STA dot_color

    ; Continue with your game initialization here
    ; JMP main_loop

    forever:
        JMP forever

; INTERRUPTROUTINES
; Deze routines worden momenteel niet gebruikt.
; RTI keert terug uit een interrupt.

nmi:
    RTI                    ; Keer terug uit de NMI-interrupt

irq:
    RTI                    ; Keer terug uit de IRQ-interrupt


; INTERRUPTVECTOR
; De NES leest deze adressen om te weten welke routine
; uitgevoerd moet worden bij NMI, RESET en IRQ.

.segment "VECTORS"         ; Plaats de interruptvectoren op het einde van PRG-ROM

.word nmi                  ; NMI-vector
.word reset                ; RESET-vector
.word irq                  ; IRQ/BRK-vector

.segment "CHR" 