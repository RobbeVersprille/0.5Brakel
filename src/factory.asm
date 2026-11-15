MAX_FACTORIES = 1            ;Set a limit for the number of factories in the game

.segment "ZEROPAGE"          ; Zero page variables

factory_index: .res 1                    ; Reserve 1 byte for factory index
factory_wood: .res MAX_FACTORIES         ; Reserve 1 byte for wood ingredient
factory_stone: .res MAX_FACTORIES        ; Reserve 1 byte for stone ingredient
factory_flower: .res MAX_FACTORIES       ; Reserve 1 byte for flower ingredient
factory_plank: .res MAX_FACTORIES        ; Reserve 1 byte for plank ingredient
factory_sand: .res MAX_FACTORIES         ; Reserve 1 byte for sand ingredient
factory_food: .res MAX_FACTORIES         ; Reserve 1 byte for food ingredient
factory_output: .res MAX_FACTORIES       ; Reserve 1 byte for output potion
potion_upgrade_level: .res 1             ; Reserve 1 byte for potion upgrade level

.segment "CODE"              ; Code segment (hence the name)

.proc FactoryInit:           ; Initialize factory
LDX #$00                     ; Start at index zero
LDA #$00                     ; Set everything to zero with this value

factoryInitLoop:                    ; Loop through all factory slots
STA factory_wood, X                 ; Reset wood inventory
STA factory_stone, X                ; Reset stone inventory
STA factory_flower, X               ; Reset flower inventory
STA factory_plank, X                ; Reset plank inventory
STA factory_sand, X                 ; Reset sand inventory
STA factory_food, X                 ; Reset food inventory
STA factory_crafting_timer, X       ; Reset crafting timer
STA factory_output_connected, X     ; Reset output connection
STA potion_upgrade_level, X         ; Reset potion upgrade level

INX                          ; Move to next factory
CPX #MAX_FACTORIES           ; Check if all factories were initialized
BNE factoryInitLoop          ; Repeat if more factories remain

RTS                          ; Return from subroutine
.endproc                     ; End subroutine

.proc FactoryUpdate:         ; Update factory
LDX #$00                     ; Start at index zero

factoryUpdateLoop:           ; Loop through all factory slots

JSR FactoryCheckRecipe        ; Check if the factory has a valid recipe

INX                          ; Move to next factory
CPX #MAX_FACTORIES           ; Check if all factories were updated
BNE factoryUpdateLoop        ; Repeat if more factories remain

RTS                          ; Return from subroutine (factory update)
.endproc                     ; End subroutine

.proc FactoryCheckRecipe:    ; Check factory recipe
LDA factory_plank, X         ; Check for planks
BNE checkSand                ; If found, skip wood check
LDA factory_wood, X          ; Check for wood
BEQ invalidRecipe            ; Invalid if neither exists

checkSand:                   ; Check stone category
LDA factory_sand, X          ; Check for sand
BNE checkFood                ; If found, skip stone check
LDA factory_stone, X         ; Check for stone
BEQ invalidRecipe            ; Invalid if neither exists

checkFood:                   ; Check flower category
LDA factory_food, X          ; Check for food
BNE recipeComplete           ; If found, skip flower check
LDA factory_flower, X        ; Check for flower
BEQ invalidRecipe            ; Invalid if neither exists

recipeComplete:              ; All three categories satisfied
;TODO: MAKE POTIONS
JSR FactoryCreatePotion      ; Create potion sprite if recipe is valid
;TODO: MAKE SURE TO DELETE THE MATERIALS AFTER CREATING THE POTION
JSR FactoryDeleteMaterials   ; Delete the used materials

invalidRecipe:               ; If any ingredient is zero, the recipe is invalid
RTS                          ; Return from subroutine
.endproc                     ; End subroutine

.proc FactoryCreatePotion:   ; Create potion sprite
RTS                          ; Return from subroutine
.endproc                     ; End subroutine

.proc FactoryDeleteMaterials:   ; Delete the used materials
RTS                          ; Return from subroutine
.endproc                     ; End subroutine

