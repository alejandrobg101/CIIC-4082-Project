.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
player_x: .res 1
player_y: .res 1
player_dir: .res 1
.exportzp player_x, player_y

ppuctrl_settings: .res 1
pad1: .res 1
.exportzp player_x, player_y, pad1

direction_state : .res 1 
walk_state : .res 1      ; Walking state: 0 for standing, 1 for walking
walk_frame_counter : .res 0 ; Counter for walking animation frames

.segment "CODE"
.proc irq_handler
  RTI
.endproc

.import read_controller1

.proc nmi_handler
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA
  LDA #$00
  
  JSR update_player
  JSR read_controller1
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

  ; Initialize walk_state
  LDA #$00
  STA walk_state
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

.proc update_player
  PHP  ; Start by saving registers,
  PHA  ; as usual.
  TXA
  PHA
  TYA
  PHA

  LDA pad1        ; Load button presses
  AND #BTN_LEFT   ; Filter out all but Left
  BEQ check_right ; If result is zero, left not pressed
  LDA #$00             ; Player is moving left
  STA player_dir
  DEC player_x  ; If the branch is not taken, move player left
check_right:
  LDA pad1
  AND #BTN_RIGHT
  BEQ check_up
  LDA #$01             ; Player is moving right
  STA player_dir
  INC player_x
check_up:
  LDA pad1
  AND #BTN_UP
  BEQ check_down
  LDA #$02             ; Player is moving up
  STA player_dir
  DEC player_y
check_down:
  LDA pad1
  AND #BTN_DOWN
  BEQ done_checking
  LDA #$03             ; Player is moving down
  STA player_dir
  INC player_y
  
done_checking:
  PLA ; Done with updates, restore registers
  TAY ; and return to where we called this
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.proc draw_player
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  LDA player_dir
  CMP #$00             ; Check player direction
  BEQ draw_left
  CMP #$01
  BEQ draw_right
  CMP #$02
  BEQ draw_up
  CMP #$03
  BEQ draw_down

draw_left:
  JSR draw_player_left
  JMP done_drawing

draw_right:
  JSR draw_player_right
  JMP done_drawing

draw_up:
  JSR draw_player_up
  JMP done_drawing

draw_down:
  JSR draw_player_down

done_drawing:
  ; restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

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

  ; Reset walk_frame_counter
  LDA #$00
  STA walk_frame_counter

  ; Toggle walk_state between 0 and 1
  LDA walk_state
  EOR #$01
  STA walk_state

skip_switch:
  ; Determine which sprite set to use based on walk_state
  LDA walk_state
  BEQ draw_sprite_set1_down
  JMP draw_sprite_set2_down

draw_sprite_set1_down:
  ; write player tile numbers for sprite set 1
  LDA #$04
  STA $0201
  LDA #$05
  STA $0205
  LDA #$14
  STA $0209
  LDA #$15
  STA $020d
  JMP sprite_attributes_set_down

draw_sprite_set2_down:
  ; write player tile numbers for sprite set 2
  LDA #$06
  STA $0201
  LDA #$07
  STA $0205
  LDA #$16
  STA $0209
  LDA #$17
  STA $020d
  JMP sprite_attributes_set_down

sprite_attributes_set_down:
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
  STA $0201
  LDA #$0B
  STA $0205
  LDA #$1A
  STA $0209
  LDA #$1B
  STA $020D
  JMP sprite_attributes_set1

draw_sprite_set2:
  ; write player tile numbers for sprite set 2
  LDA #$0C
  STA $0201
  LDA #$0d
  STA $0205
  LDA #$1C
  STA $0209
  LDA #$1D
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
  STA $0201
  LDA #$0F
  STA $0205
  LDA #$1E
  STA $0209
  LDA #$1F
  STA $020D
  JMP sprite_attributes_set1

draw_sprite_set2:
  ; write player tile numbers for sprite set 2
  LDA #$24
  STA $0201
  LDA #$25
  STA $0205
  LDA #$34
  STA $0209
  LDA #$35
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
  STA $0201
  LDA #$27
  STA $0205
  LDA #$36
  STA $0209
  LDA #$37
  STA $020d
  JMP sprite_attributes_set1

draw_sprite_set2:
  ; write player tile numbers for sprite set 2
  LDA #$2a
  STA $0201
  LDA #$2b
  STA $0205
  LDA #$3a
  STA $0209
  LDA #$3b
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


.segment "CHR"
.incbin "graphics.chr"
