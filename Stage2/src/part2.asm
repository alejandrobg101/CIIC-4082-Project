.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
player_x: .res 1
player_y: .res 1
player_dir: .res 1
.exportzp player_x, player_y

direction_state : .res 1 ; Direction state: 0 for left, 1 for right
walk_state : .res 1      ; Walking state: 0 for standing, 1 for walking
walk_frame_counter : .res 2 ; Counter for walking animation frames

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
  JSR draw_player


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
vblankwait:
  BIT $2002
  BPL vblankwait

	LDX #$00
	LDA #$FF
clear_oam:
	STA $0200,X ; set sprite y-positions off the screen
	INX
	INX
	INX
	INX
	BNE clear_oam

	; initialize zero-page values
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

.proc draw_player
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; Use a flag to alternate between sprite sets
  LDA walk_frame_counter
  AND #$01  ; Keep only the least significant bit to alternate between 0 and 1
  BEQ draw_sprite_set1
  JMP draw_sprite_set2

draw_sprite_set1:
  ; write player ship tile numbers for sprite set 1
  LDA #$02
  STA $0201
  LDA #$03
  STA $0205
  LDA #$12
  STA $0209
  LDA #$13
  STA $020d
  JMP sprite_attributes_set1

draw_sprite_set2:
  ; write player ship tile numbers for sprite set 2
  LDA #$04
  STA $0201
  LDA #$05
  STA $0205
  LDA #$14
  STA $0209
  LDA #$15
  STA $020d

sprite_attributes_set1:
  ; write player ship tile attributes for both sets
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
  INC walk_frame_counter
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
