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

.proc draw_player
    ; Draw standing player tiles
    ; Write player tile numbers for standing
    LDA #$02  ; Adjust these values according to your specific tile mappings
    STA $0201
    LDA #$03
    STA $0205
    LDA #$12
    STA $0209
    LDA #$13
    STA $020d
    JMP DrawDone

    ;   ; write player tile attributes
    ; use palette 0
    LDA #$00
    STA $0202
    STA $0206
    STA $020a
    STA $020e
.endproc


.proc WalkingLeft
    ; Determine which frame of walking animation to draw
    ; Use a counter or timer to alternate between frames

    ; Increment walk_frame_counter
    INC walk_frame_counter

    ; Call the appropriate subroutine for the current frame of animation
    ; This example assumes there are three frames for walking left
    LDA walk_frame_counter
    AND #$03     ; Mask to ensure the counter stays within the range of 0 to 2
    CMP #$00
    BEQ DrawLeftFrame1
    CMP #$01
    BEQ DrawLeftFrame2
    ; Default to the third frame if the counter is 2
    JMP DrawLeftFrame3

DrawLeftFrame1:
    ; Draw left-facing player tiles for the first frame of walking animation
    ; Write player tile numbers for the first frame
    LDA #$24  ; Adjust these values according to your specific tile mappings
    STA $0201
    LDA #$25
    STA $0205
    LDA #$34
    STA $0209
    LDA #$35
    STA $020d
    JMP DrawDone

DrawLeftFrame2:
    ; Draw left-facing player tiles for the second frame of walking animation
    ; Write player tile numbers for the second frame
    LDA #$22  ; Adjust these values according to your specific tile mappings
    STA $0201
    LDA #$23
    STA $0205
    LDA #$32
    STA $0209
    LDA #$33
    STA $020d
    JMP DrawDone

DrawLeftFrame3:
    ; Draw left-facing player tiles for the third frame of walking animation
    ; Write player tile numbers for the third frame
    LDA #$0f  ; Adjust these values according to your specific tile mappings
    STA $0201
    LDA #$0e
    STA $0205
    LDA #$1f
    STA $0209
    LDA #$1e
    STA $020d
    JMP DrawDone

DrawDone:
    ; Restore registers and return
    PLA
    TAY
    PLA
    TAX
    PLA
    PLP
    RTS

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
; ; ;front 1
; .byte $60, $02, $00, $50
; .byte $60, $03, $00, $58
; .byte $68, $12, $00, $50
; .byte $68, $13, $00, $58
; ;front2
; .byte $60, $04, $00, $60
; .byte $60, $05, $00, $68
; .byte $68, $14, $00, $60
; .byte $68, $15, $00, $68
; ;front3
; .byte $60, $06, $00, $70
; .byte $60, $07, $00, $78
; .byte $68, $16, $00, $70
; .byte $68, $17, $00, $78
; ;back1
; .byte $70, $08, $00, $50
; .byte $70, $09, $00, $58
; .byte $78, $18, $00, $50
; .byte $78, $19, $00, $58
; ;back2
; .byte $70, $0a, $00, $60
; .byte $70, $0b, $00, $68
; .byte $78, $1a, $00, $60
; .byte $78, $1b, $00, $68
; ;back3
; .byte $70, $0c, $00, $70
; .byte $70, $0d, $00, $78
; .byte $78, $1c, $00, $70
; .byte $78, $1d, $00, $78
; ;left1
; .byte $80, $0e, $00, $50
; .byte $80, $0f, $00, $58
; .byte $88, $1e, $00, $50
; .byte $88, $1f, $00, $58
; ;left2
; .byte $80, $22, $00, $60
; .byte $80, $23, $00, $68
; .byte $88, $32, $00, $60
; .byte $88, $33, $00, $68
; ;left3
; .byte $80, $24, $00, $70
; .byte $80, $25, $00, $78
; .byte $88, $34, $00, $70
; .byte $88, $35, $00, $78
; ;right1
; .byte $90, $26, $00, $50
; .byte $90, $27, $00, $58
; .byte $98, $36, $00, $50
; .byte $98, $37, $00, $58
; ;right2
; .byte $90, $28, $00, $60
; .byte $90, $29, $00, $68
; .byte $98, $38, $00, $60
; .byte $98, $39, $00, $68
; ;right3
; .byte $90, $2a, $00, $70
; .byte $90, $2b, $00, $78
; .byte $98, $3a, $00, $70
; .byte $98, $3b, $00, $78

.segment "CHR"
.incbin "graphics.chr"
