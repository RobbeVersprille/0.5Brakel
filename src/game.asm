; Besturing:
;   A-knop       = rode achtergrond, zwart punt
;   B-knop       = blauwe achtergrond, wit punt
;   Pijl omhoog  = punt omhoog bewegen
;   Pijl omlaag  = punt omlaag bewegen
;   Pijl links   = punt naar links bewegen
;   Pijl rechts  = punt naar rechts bewegen

.setcpu "6502"                 ; target CPU of this file

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

.import FactoryDraw, FactoryInit, PlaceFactory
.import PaletteData            ; Import background and sprite palettes
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
                    JSR FactoryInit            ; Initialize factory variables

        ; Upload the palettes
    BIT $2002                   ; Reset PPU address latch
    LDA #$3F                    ; Palette RAM high byte
    STA $2006                   ; Set PPU address high byte
    LDA #$00                    ; Palette RAM low byte
    STA $2006                   ; Set PPU address low byte

    LDX #$00                    ; Start at palette byte 0
paletteLoop:
    LDA PaletteData, X          ; Load palette colour
    STA $2007                   ; Write colour to PPU
    INX                         ; Next palette byte
    CPX #$20                    ; Have we written 32 bytes?
    BNE paletteLoop             ; Repeat if not

    
    ; Draw factory
    LDA #$0A                    ; tile (10, 8) = $210A
    LDX #$21
    JSR PlaceFactory

    LDA #$8C                    
    LDX #$21
    JSR PlaceFactory


    
; Assign palette 1 to the factory area
        ; Assign palette 1 to the factory area
    ; BIT $2002                   ; Reset PPU address latch
    ; LDA #$23                    ; Attribute table high byte
    ; STA $2006                   ; Set PPU address high byte
    ; LDA #$D2                    ; Attribute table low byte
    ; STA $2006                   ; Set PPU address low byte
    ; LDA #$44                    ; Select palette 1 for right quadrants
    ; STA $2007                   ; Write attribute byte

    BIT $2002                   ; reset the PPU address latch
    LDA #$23                    ; attribute table starts at $23C0
    STA $2006                   ; high byte
    LDA #$C0
    STA $2006                   ; low byte
    LDA #$55                    ; %01010101 = palette 1 in all four quadrants
    LDX #$40                    ; the attribute table is 64 bytes
attrLoop:
    STA $2007                   ; write one attribute byte (the address auto-increments)
    DEX                         ; one byte less to go
    BNE attrLoop                ; repeat until all 64 are written

    LDA #$00                    ; reset the scroll, the $2006 writes above disturb it
    STA $2005                   ; horizontal scroll
    STA $2005                   ; vertical scroll

    LDA #%00001000              ; Enable background rendering
    STA $2001                   ; Set PPU mask

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