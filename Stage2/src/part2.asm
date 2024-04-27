.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
player_x: .res 1
player_y: .res 1
player_dir: .res 1
.exportzp player_x, player_y

direction_state : .res 1 ; Direction state: 0 for left, 1 for right
walk_state : .res 1      ; Walking state: 0 for standing, 1 for walking
walk_frame_counter : .res 0 ; Counter for walking animation frames

.segment "CODE"
.proc irq_handler
  RTI
.endproc

.proc nmi_handler
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA
  LDA #$00

	; JSR update_player
  JSR draw_player_up
  JSR draw_player_down
  JSR draw_player_left
  JSR draw_player_right


  STA $2005
  STA $2005
  RTI
.endproc

.proc reset_handler
  SEI
  CLD
  LDX #$40
  STX $4017
  LDX #$FF
  TXS
  INX
  STX $2000
  STX $2001
  STX $4010
  BIT $2002

  ; Initialize walk_state
  LDA #$00
  STA walk_state

vblankwait:
  BIT $2002
  BPL vblankwait

  LDX #$00
  LDA #$FF
clear_oam:
  STA $0200,X
  INX
  INX
  INX
  INX
  BNE clear_oam
  LDA #$40
  STA player_x
  LDA #$70
  STA player_y

vblankwait2:
  BIT $2002
  BPL vblankwait2
  JMP main
.endproc

.proc main
  ; write a palette
  LDX PPUSTATUS
  LDX #$3f
  STX PPUADDR
  LDX #$00
  STX PPUADDR
load_palettes:
  LDA palettes,X
  STA PPUDATA
  INX
  CPX #$20
  BNE load_palettes

	; finally, attribute table

	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$eb
	STA PPUADDR
	LDA #%01000000
	STA PPUDATA

  LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$eb
	STA PPUADDR
	LDA #%01100000
	STA PPUDATA

  LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$ec
	STA PPUADDR
	LDA #%01100000
	STA PPUDATA
vblankwait:       ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL vblankwait

  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK

forever:
  JMP forever
.endproc

; .proc update_player
;   PHP
;   PHA
;   TXA
;   PHA
;   TYA
;   PHA

;   LDA player_x
;   CMP #$e0
;   BCC not_at_right_edge
;   ; if BCC is not taken, we are greater than $e0
;   LDA #$00
;   STA player_dir    ; start moving left
;   JMP direction_set ; we already chose a direction,
;                     ; so we can skip the left side check
; not_at_right_edge:
;   LDA player_x
;   CMP #$10
;   BCS direction_set
;   ; if BCS not taken, we are less than $10
;   LDA #$01
;   STA player_dir   ; start moving right
; direction_set:
;   ; now, actually update player_x
;   LDA player_dir
;   CMP #$01
;   BEQ move_right
;   ; if player_dir minus $01 is not zero,
;   ; that means player_dir was $00 and
;   ; we need to move left
;   DEC player_x
;   JMP exit_subroutine
; move_right:
;   INC player_x

; exit_subroutine:
;   ; all done, clean up and return
;   PLA
;   TAY
;   PLA
;   TAX
;   PLA
;   PLP
;   RTS
; .endproc

.proc draw_player_down
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; Increment walk_frame_counter every frame
  INC walk_frame_counter

  ; Check if walk_frame_counter has reached the threshold for switching
  LDA walk_frame_counter
  CMP #$10  ; Adjust this threshold to control the speed of the switch
  BNE skip_switch

  ; Reset walk_frame_counter and toggle walk_state
  LDA #$00
  STA walk_frame_counter

  ; Toggle walk_state between 0 and 1
  LDA walk_state
  EOR #$01
  STA walk_state

skip_switch:
  ; Determine which sprite set to use based on walk_state
  LDA walk_state
  BEQ draw_sprite_set1
  JMP draw_sprite_set2

draw_sprite_set1:
  ; write player tile numbers for sprite set 1
  LDA #$04
  STA $0201
  LDA #$05
  STA $0205
  LDA #$14
  STA $0209
  LDA #$15
  STA $020d
  JMP sprite_attributes_set1

draw_sprite_set2:
  ; write player tile numbers for sprite set 2
  LDA #$06
  STA $0201
  LDA #$07
  STA $0205
  LDA #$16
  STA $0209
  LDA #$17
  STA $020d

sprite_attributes_set1:
  ; write player tile attributes for both sets
  ; use palette 0
  LDA #$00
  STA $0202
  STA $0206
  STA $020a
  STA $020e

  ; store tile locations
  ; top left tile:
  LDA player_y
  STA $0200
  LDA player_x
  STA $0203

  ; top right tile (x + 8):
  LDA player_y
  STA $0204
  LDA player_x
  CLC
  ADC #$08
  STA $0207

  ; bottom left tile (y + 8):
  LDA player_y
  CLC
  ADC #$08
  STA $0208
  LDA player_x
  STA $020b

  ; bottom right tile (x + 8, y + 8)
  LDA player_y
  CLC
  ADC #$08
  STA $020c
  LDA player_x
  CLC
  ADC #$08
  STA $020f

  ; restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.proc draw_player_up
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; Increment walk_frame_counter every frame
  INC walk_frame_counter

  ; Check if walk_frame_counter has reached the threshold for switching
  LDA walk_frame_counter
  CMP #$10  ; Adjust this threshold to control the speed of the switch
  BNE skip_switch

  ; Reset walk_frame_counter and toggle walk_state
  LDA #$00
  STA walk_frame_counter

  ; Toggle walk_state between 0 and 1
  LDA walk_state
  EOR #$01
  STA walk_state

skip_switch:
  ; Determine which sprite set to use based on walk_state
  LDA walk_state
  BEQ draw_sprite_set1
  JMP draw_sprite_set2

draw_sprite_set1:
  ; write player tile numbers for sprite set 1
  LDA #$0A
  STA $0211
  LDA #$0B
  STA $0215
  LDA #$1A
  STA $0219
  LDA #$1B
  STA $021d
  JMP sprite_attributes_set1

draw_sprite_set2:
  ; write player tile numbers for sprite set 2
  LDA #$0C
  STA $0211
  LDA #$0d
  STA $0215
  LDA #$1C
  STA $0219
  LDA #$1D
  STA $021d

sprite_attributes_set1:
  ; write player tile attributes for both sets
  ; use palette 0
  LDA #$00
  STA $0212
  STA $0216
  STA $021a
  STA $021e

  ; store tile locations
  ; top left tile:
  LDA player_y
  STA $0210
  LDA player_x
  CLC
  ADC #$16
  STA $0213

  ; top right tile (x + 8):
  LDA player_y
  STA $0214
  LDA player_x
  CLC
  ADC #$1E
  STA $0217

  ; bottom left tile (y + 8):
  LDA player_y
  CLC
  ADC #$08
  STA $0218
  LDA player_x
  CLC
  ADC #$16
  STA $021b

  ; bottom right tile (x + 8, y + 8)
  LDA player_y
  CLC
  ADC #$08
  STA $021c
  LDA player_x
  CLC
  ADC #$1E
  STA $021f

  ; restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.proc draw_player_left
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; Increment walk_frame_counter every frame
  INC walk_frame_counter

  ; Check if walk_frame_counter has reached the threshold for switching
  LDA walk_frame_counter
  CMP #$10  ; Adjust this threshold to control the speed of the switch
  BNE skip_switch

  ; Reset walk_frame_counter and toggle walk_state
  LDA #$00
  STA walk_frame_counter

  ; Toggle walk_state between 0 and 1
  LDA walk_state
  EOR #$01
  STA walk_state

skip_switch:
  ; Determine which sprite set to use based on walk_state
  LDA walk_state
  BEQ draw_sprite_set1
  JMP draw_sprite_set2

draw_sprite_set1:
  ; write player tile numbers for sprite set 1
  LDA #$0E
  STA $0221
  LDA #$0F
  STA $0225
  LDA #$1E
  STA $0229
  LDA #$1F
  STA $022d
  JMP sprite_attributes_set1

draw_sprite_set2:
  ; write player tile numbers for sprite set 2
  LDA #$24
  STA $0221
  LDA #$25
  STA $0225
  LDA #$34
  STA $0229
  LDA #$35
  STA $022d

sprite_attributes_set1:
  ; write player tile attributes for both sets
  ; use palette 0
  LDA #$00
  STA $0222
  STA $0226
  STA $022a
  STA $022e

  ; store tile locations
  ; top left tile:
  LDA player_y
  CLC
  ADC #$16
  STA $0220
  LDA player_x
  STA $0223

  ; top right tile (x + 8):
  LDA player_y
  CLC
  ADC #$16
  STA $0224
  LDA player_x
  CLC
  ADC #$08
  STA $0227

  ; bottom left tile (y + 8):
  LDA player_y
  CLC
  ADC #$1E
  STA $0228
  LDA player_x
  STA $022b

  ; bottom right tile (x + 8, y + 8)
  LDA player_y
  CLC
  ADC #$1E
  STA $022c
  LDA player_x
  CLC
  ADC #$08
  STA $022f

  ; restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.proc draw_player_right
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; Increment walk_frame_counter every frame
  INC walk_frame_counter

  ; Check if walk_frame_counter has reached the threshold for switching
  LDA walk_frame_counter
  CMP #$10  ; Adjust this threshold to control the speed of the switch
  BNE skip_switch

  ; Reset walk_frame_counter and toggle walk_state
  LDA #$00
  STA walk_frame_counter

  ; Toggle walk_state between 0 and 1
  LDA walk_state
  EOR #$01
  STA walk_state

skip_switch:
  ; Determine which sprite set to use based on walk_state
  LDA walk_state
  BEQ draw_sprite_set1
  JMP draw_sprite_set2

draw_sprite_set1:
  ; write player tile numbers for sprite set 1
  LDA #$26
  STA $0231
  LDA #$27
  STA $0235
  LDA #$36
  STA $0239
  LDA #$37
  STA $023d
  JMP sprite_attributes_set1

draw_sprite_set2:
  ; write player tile numbers for sprite set 2
  LDA #$2a
  STA $0231
  LDA #$2b
  STA $0235
  LDA #$3a
  STA $0239
  LDA #$3b
  STA $023d

sprite_attributes_set1:
  ; write player tile attributes for both sets
  ; use palette 0
  LDA #$00
  STA $0232
  STA $0236
  STA $023a
  STA $023e

  ; store tile locations
  ; top left tile:
  LDA player_y
  CLC
  ADC #$16
  STA $0230
  LDA player_x
  CLC
  ADC #$16
  STA $0233

  ; top right tile (x + 8):
  LDA player_y
  CLC
  ADC #$16  
  STA $0234
  LDA player_x
  CLC
  ADC #$1E
  STA $0237

  ; bottom left tile (y + 8):
  LDA player_y
  CLC
  ADC #$1E
  STA $0238
  LDA player_x
  CLC
  ADC #$16  
  STA $023b

  ; bottom right tile (x + 8, y + 8)
  LDA player_y
  CLC
  ADC #$1e
  STA $023c
  LDA player_x
  CLC
  ADC #$1E
  STA $023f

  ; restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc



.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "RODATA"
palettes:
.byte $0f, $27, $2d, $30
.byte $0f, $11, $31, $30
.byte $0f, $11, $31, $30
.byte $0f, $19, $09, $29

.byte $0f, $27, $2d, $30
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29

sprites:


.segment "CHR"
.incbin "graphics.chr"
