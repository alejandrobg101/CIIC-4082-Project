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
  
  ; JSR draw_player

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

  ; write sprite data
  LDX #$00
load_sprites: ;Shows sprites
  LDA sprites,X
  STA $0200,X
  INX
  CPX #$ff ;How many sprites it shows
  BNE load_sprites
    
  ; write a nametable
   ;BACKGROUND LEVEL 1
  ; Block
  LDA PPUSTATUS
  LDA #$23
  STA PPUADDR
  LDA #$0C
  STA PPUADDR
  LDX #$02
  STX PPUDATA
  
  LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$0D
	STA PPUADDR
  LDX #$03
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$2C
	STA PPUADDR
  LDX #$12
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$2D
	STA PPUADDR
  LDX #$13
	STX PPUDATA
    ; Brick
  LDA PPUSTATUS
  LDA #$23
  STA PPUADDR
  LDA #$0E
  STA PPUADDR
  LDX #$04
  STX PPUDATA
  
  LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$0F
	STA PPUADDR
  LDX #$05
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$2E
	STA PPUADDR
  LDX #$14
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$2F
	STA PPUADDR
  LDX #$15
	STX PPUDATA
    ; Spider
  LDA PPUSTATUS
	LDA #$23
  STA PPUADDR
  LDA #$10
  STA PPUADDR
  LDX #$06
  STX PPUDATA
  
  LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$11
	STA PPUADDR
  LDX #$07
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$30
	STA PPUADDR
  LDX #$16
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$31
	STA PPUADDR
  LDX #$17
	STX PPUDATA
    ; Back
  LDA PPUSTATUS
	LDA #$23
  STA PPUADDR
  LDA #$12
  STA PPUADDR
  LDX #$08
  STX PPUDATA
  
  LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$13
	STA PPUADDR
  LDX #$09
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$32
	STA PPUADDR
  LDX #$18
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$33
	STA PPUADDR
  LDX #$19
	STX PPUDATA

  ;BACKGROUND LEVEL 2
  ; Block
  LDA PPUSTATUS
  LDA #$22
  STA PPUADDR
  LDA #$CC
  STA PPUADDR
  LDX #$22
  STX PPUDATA
  
  LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$CD
	STA PPUADDR
  LDX #$23
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$EC
	STA PPUADDR
  LDX #$32
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$ED
	STA PPUADDR
  LDX #$33
	STX PPUDATA
    ; Ice
  LDA PPUSTATUS
  LDA #$22
  STA PPUADDR
  LDA #$CE
  STA PPUADDR
  LDX #$0A
  STX PPUDATA
  
  LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$CF
	STA PPUADDR
  LDX #$0B
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$EE
	STA PPUADDR
  LDX #$1A
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$EF
	STA PPUADDR
  LDX #$1B
	STX PPUDATA
    ; Watter
  LDA PPUSTATUS
  LDA #$22
  STA PPUADDR
  LDA #$D0
  STA PPUADDR
  LDX #$0C
  STX PPUDATA
  
  LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$D1
	STA PPUADDR
  LDX #$0D
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$F0
	STA PPUADDR
  LDX #$1C
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$F1
	STA PPUADDR
  LDX #$1D
	STX PPUDATA
    ; Snow
  LDA PPUSTATUS
  LDA #$22
  STA PPUADDR
  LDA #$D2
  STA PPUADDR
  LDX #$0E
  STX PPUDATA
  
  LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$D3
	STA PPUADDR
  LDX #$0F
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$F2
	STA PPUADDR
  LDX #$1E
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$F3
	STA PPUADDR
  LDX #$1F
	STX PPUDATA
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

; .proc draw_player ;subrutine to show the player in this case, depending on variables X and Y
;   ; save registers
;   PHP
;   PHA
;   TXA
;   PHA
;   TYA
;   PHA

;   ; write player  tile numbers
;   LDA #$02
;   STA $0201
;   LDA #$03
;   STA $0205
;   LDA #$12
;   STA $0209
;   LDA #$13
;   STA $020d

;   ; write player tile attributes
;   ; use palette 0
;   LDA #$00
;   STA $0202
;   STA $0206
;   STA $020a
;   STA $020e

;   ; store tile locations
;   ; top left tile:
;   LDA player_y
;   STA $0200
;   LDA player_x
;   STA $0203

;   ; top right tile (x + 8):
;   LDA player_y
;   STA $0204
;   LDA player_x
;   CLC
;   ADC #$08
;   STA $0207

;   ; bottom left tile (y + 8):
;   LDA player_y
;   CLC
;   ADC #$08
;   STA $0208
;   LDA player_x
;   STA $020b

;   ; bottom right tile (x + 8, y + 8)
;   LDA player_y
;   CLC
;   ADC #$08
;   STA $020c
;   LDA player_x
;   CLC
;   ADC #$08
;   STA $020f

;   ; restore registers and return
;   PLA
;   TAY
;   PLA
;   TAX
;   PLA
;   PLP
;   RTS
; .endproc

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
; ;front 1
.byte $60, $02, $00, $50
.byte $60, $03, $00, $58
.byte $68, $12, $00, $50
.byte $68, $13, $00, $58
;front2
.byte $60, $04, $00, $60
.byte $60, $05, $00, $68
.byte $68, $14, $00, $60
.byte $68, $15, $00, $68
;front3
.byte $60, $06, $00, $70
.byte $60, $07, $00, $78
.byte $68, $16, $00, $70
.byte $68, $17, $00, $78
;back1
.byte $70, $08, $00, $50
.byte $70, $09, $00, $58
.byte $78, $18, $00, $50
.byte $78, $19, $00, $58
;back2
.byte $70, $0a, $00, $60
.byte $70, $0b, $00, $68
.byte $78, $1a, $00, $60
.byte $78, $1b, $00, $68
;back3
.byte $70, $0c, $00, $70
.byte $70, $0d, $00, $78
.byte $78, $1c, $00, $70
.byte $78, $1d, $00, $78
;left1
.byte $80, $0e, $00, $50
.byte $80, $0f, $00, $58
.byte $88, $1e, $00, $50
.byte $88, $1f, $00, $58
;left2
.byte $80, $22, $00, $60
.byte $80, $23, $00, $68
.byte $88, $32, $00, $60
.byte $88, $33, $00, $68
;left3
.byte $80, $24, $00, $70
.byte $80, $25, $00, $78
.byte $88, $34, $00, $70
.byte $88, $35, $00, $78
;right1
.byte $90, $26, $00, $50
.byte $90, $27, $00, $58
.byte $98, $36, $00, $50
.byte $98, $37, $00, $58
;right2
.byte $90, $28, $00, $60
.byte $90, $29, $00, $68
.byte $98, $38, $00, $60
.byte $98, $39, $00, $68
;right3
.byte $90, $2a, $00, $70
.byte $90, $2b, $00, $78
.byte $98, $3a, $00, $70
.byte $98, $3b, $00, $78

.segment "CHR"
.incbin "graphics.chr"
