.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
player_x: .res 1
player_y: .res 1
player_dir: .res 1
.exportzp player_x, player_y

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
	LDA #$80
	STA player_x
	LDA #$80
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
	LDA #$c2
	STA PPUADDR
	LDA #%01000000
	STA PPUDATA

	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$e0
	STA PPUADDR
	LDA #%00001100
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
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; write player  tile numbers
  LDA #$02
  STA $0201
  LDA #$03
  STA $0205
  LDA #$12
  STA $0209
  LDA #$13
  STA $020d

  ; write player tile attributes
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
.byte $0f, $12, $23, $27
.byte $0f, $2b, $3c, $39
.byte $0f, $0c, $07, $13
.byte $0f, $19, $09, $29

.byte $0f, $27, $2d, $30
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29

sprites:
;front 1
; .byte $70, $02, $00, $50
; .byte $70, $03, $00, $58
; .byte $78, $12, $00, $50
; .byte $78, $13, $00, $58
; ;front2
; .byte $70, $04, $00, $60
; .byte $70, $05, $00, $68
; .byte $78, $14, $00, $60
; .byte $78, $15, $00, $68
; ;front3
; .byte $70, $06, $00, $70
; .byte $70, $07, $00, $78
; .byte $78, $16, $00, $70
; .byte $78, $17, $00, $78
; ;back1
; .byte $70, $08, $00, $80
; .byte $70, $09, $00, $88
; .byte $78, $18, $00, $80
; .byte $78, $19, $00, $88
; ;back2
; .byte $70, $0a, $00, $90
; .byte $70, $0b, $00, $98
; .byte $78, $1a, $00, $90
; .byte $78, $1b, $00, $98
; ;back3
; .byte $70, $0c, $00, $a0
; .byte $70, $0d, $00, $a8
; .byte $78, $1c, $00, $a0
; .byte $78, $1d, $00, $a8
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
; .byte $80, $26, $00, $80
; .byte $80, $27, $00, $88
; .byte $88, $36, $00, $80
; .byte $88, $37, $00, $88
; ;right2
; .byte $80, $28, $00, $90
; .byte $80, $29, $00, $98
; .byte $88, $38, $00, $90
; .byte $88, $39, $00, $98
; ;right3
; .byte $80, $2a, $00, $a0
; .byte $80, $2b, $00, $a8
; .byte $88, $3a, $00, $a0
; .byte $88, $3b, $00, $a8

.segment "CHR"
.incbin "graphics.chr"
