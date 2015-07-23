INCLUDE "gbhw.inc"

SPRITE_SIZE EQU 8

ANIM_RATE EQU 4

;Sprite struct

SPRITE_STRUCT_SIZE EQU 4
SPRITE_Y EQU 0
SPRITE_X EQU 1
SRRITE_TILE EQU 2
SPRITE_ATTRIB EQU 3

;Metasprite struct

METASPRITE_STRUCT_SIZE EQU 7
METASPRITE_ATR EQU 0
METASPRITE_X EQU 1
METASPRITE_Y EQU 2
METASPRITE_W EQU 3 ;in no. of sprites 
METASPRITE_H EQU 4 ;in no. of sprites
METASPRITE_WxH EQU 5 ;total no. of sprites
METASPRITE_START_TILE EQU 6

;Player Anims

PLAYER_ANIM_IDLE EQU 0
PLAYER_ANIM_WALK EQU 1
PLAYER_ANIM_JUMP EQU 2

PLAYER_ANIM_IDLE_START EQU 23
PLAYER_ANIM_IDLE_END EQU 23

PLAYER_ANIM_WALK_START EQU 23
PLAYER_ANIM_WALK_END EQU 50

PLAYER_ANIM_JUMP_START EQU 59
PLAYER_ANIM_JUMP_END EQU 59

SECTION "OAM Buffer", BSS[$C000]

OAMBuf: ds 40 * SPRITE_STRUCT_SIZE

SECTION "Sprite Variables", BSS

SPRITE_COUNTER : DS 1
SPRITE_PLAYER : DS METASPRITE_STRUCT_SIZE
ANIM_COUNTER : DS 1
ANIM_ID : DS 1
ANIM_START : DS 1
ANIM_END : DS 1

SECTION "Sprite Code", HOME

SpriteInit:
	xor a
	ld [ANIM_COUNTER], a
	ld [SPRITE_PLAYER + METASPRITE_ATR], a
	ld a, 60
	ld [SPRITE_PLAYER + METASPRITE_X], a
	ld [SPRITE_PLAYER + METASPRITE_Y], a
	ld a, 3
	ld [SPRITE_PLAYER + METASPRITE_W], a
	ld [SPRITE_PLAYER + METASPRITE_H], a
	ld a, 3*3
	ld [SPRITE_PLAYER + METASPRITE_WxH], a
	ld a, PLAYER_ANIM_IDLE_START
	ld [SPRITE_PLAYER + METASPRITE_START_TILE], a
	call SpriteUpdate
	ret
	
SpriteUpdate:
	ld a, [SPRITE_PLAYER + METASPRITE_ATR]
	or a
	jr z, .noflip
.flip
	call SpriteUpdateFlip
	jr .end
.noflip
	call SpriteUpdateNoFlip
.end
	ret
	
SpriteUpdateNoFlip:
	ld a, [SPRITE_PLAYER + METASPRITE_W]
	ld b, a
	ld a, [SPRITE_PLAYER + METASPRITE_H]
	ld c, a
	ld hl, OAMBuf
	ld a, [SPRITE_PLAYER + METASPRITE_X]
	ld d, a
	ld a, [SPRITE_PLAYER + METASPRITE_Y]
	ld e, a
	ld a, [SPRITE_PLAYER + METASPRITE_START_TILE]
	ld [SPRITE_COUNTER], a
.loop
	ld a, e
	ld [HLI], a
	ld a, d
	ld [HLI], a
	ld a, SPRITE_SIZE
	add a, d
	ld d, a
	ld a, [SPRITE_COUNTER]
	ld [HLI], a
	inc a
	ld [SPRITE_COUNTER], a
	ld a, [SPRITE_PLAYER + METASPRITE_ATR]
	ld [HLI], a
	dec b
	jr z, .nextrow
	jr .loop
.nextrow
	ld a, SPRITE_SIZE
	add a, e
	ld e, a
	ld a, [SPRITE_PLAYER + METASPRITE_X]
	ld d, a
	ld a, [SPRITE_PLAYER + METASPRITE_W]
	ld b, a
	dec c
	jr z, .end
	jr .loop
.end
	ret
	
SpriteUpdateFlip:
	ld a, [SPRITE_PLAYER + METASPRITE_START_TILE]
	ld b, a
	ld a, [SPRITE_PLAYER + METASPRITE_W]
	dec a
	add a, b
	ld [SPRITE_COUNTER], a
	ld a, [SPRITE_PLAYER + METASPRITE_W]
	ld b, a
	ld a, [SPRITE_PLAYER + METASPRITE_H]
	ld c, a
	ld hl, OAMBuf
	ld a, [SPRITE_PLAYER + METASPRITE_X]
	ld d, a
	ld a, [SPRITE_PLAYER + METASPRITE_Y]
	ld e, a
.loop
	ld a, e
	ld [HLI], a
	ld a, d
	ld [HLI], a
	ld a, SPRITE_SIZE
	add a, d
	ld d, a
	ld a, [SPRITE_COUNTER]
	ld [HLI], a
	dec a
	ld [SPRITE_COUNTER], a
	ld a, [SPRITE_PLAYER + METASPRITE_ATR]
	ld [HLI], a
	dec b
	jr z, .nextrow
	jr .loop
.nextrow
	ld a, SPRITE_SIZE
	add a, e
	ld e, a
	ld a, [SPRITE_PLAYER + METASPRITE_X]
	ld d, a
	ld a, [SPRITE_PLAYER + METASPRITE_W]
	ld b, a
	ld a, [SPRITE_COUNTER]
	add a, 6
	ld [SPRITE_COUNTER], a
	dec c
	jr z, .end
	jr .loop
.end
	ret
	
;in: b - anim start
;    c - anim end
;	 d - anim id
	
SpriteAnimStart:
	ld a, [ANIM_ID]
	cp d
	jr z, .same
	ld a, d
	ld [ANIM_ID], a
	ld a, b
	ld [ANIM_START], a
	ld [SPRITE_PLAYER + METASPRITE_START_TILE], a
	ld a, c
	ld [ANIM_END], a
.same
	ret
	
SpriteAnim:
	ld a, [ANIM_COUNTER]
	inc a
	cp ANIM_RATE
	jr z, .nextframe
	ld [ANIM_COUNTER], a
	jr .end
.nextframe
	xor a
	ld [ANIM_COUNTER], a
	ld a, [ANIM_END]
	ld b, a
	ld a, [SPRITE_PLAYER + METASPRITE_START_TILE]
	cp b
	jr z, .reset
	ld b, a
	ld a, [SPRITE_PLAYER + METASPRITE_WxH]
	add a, b
	ld [SPRITE_PLAYER + METASPRITE_START_TILE], a
	jr .end
.reset
	ld a, [ANIM_START]
	ld [SPRITE_PLAYER + METASPRITE_START_TILE], a
.end
	ret
	
PlayerWalkRightAnim: MACRO
	xor a
	ld [SPRITE_PLAYER + METASPRITE_ATR], a
	ld a, PLAYER_ANIM_WALK_START
	ld b, a
	ld a, PLAYER_ANIM_WALK_END
	ld c, a
	ld a, PLAYER_ANIM_WALK
	ld d, a
	call SpriteAnimStart
	ENDM
	
PlayerWalkLeftAnim: MACRO
	ld a, OAMF_XFLIP
	ld [SPRITE_PLAYER + METASPRITE_ATR], a
	ld a, PLAYER_ANIM_WALK_START
	ld b, a
	ld a, PLAYER_ANIM_WALK_END
	ld c, a
	ld a, PLAYER_ANIM_WALK
	ld d, a
	call SpriteAnimStart
	ENDM
	
PlayerIdleAnim: MACRO
	ld a, PLAYER_ANIM_IDLE_START
	ld b, a
	ld a, PLAYER_ANIM_IDLE_END
	ld c, a
	ld a, PLAYER_ANIM_IDLE
	ld d, a
	call SpriteAnimStart
	ENDM
	
PlayerJumpAnim: MACRO
	ld a, PLAYER_ANIM_JUMP_START
	ld b, a
	ld a, PLAYER_ANIM_JUMP_END
	ld c, a
	ld a, PLAYER_ANIM_JUMP
	ld d, a
	call SpriteAnimStart
	ENDM
	
;in: b - x movement
;    c - y movement
	
SpriteMove:
	ld a, b
	or a
	jr z, .ymove
	bit 7, a
	jr z, .xadd
	jr .xsub
.xadd
	res 7, a
	ld b, a
	ld a, [SPRITE_PLAYER + METASPRITE_X]
	add a, b
	ld [SPRITE_PLAYER + METASPRITE_X], a
	jr .ymove
.xsub
	res 7, a
	ld b, a
	ld a, [SPRITE_PLAYER + METASPRITE_X]
	sub a, b
	ld [SPRITE_PLAYER + METASPRITE_X], a
.ymove
	ld a, c
	or a
	jr z, .end
	bit 7, a
	jr z, .yadd
	jr .ysub
.yadd
	res 7, a
	ld c, a
	ld a, [SPRITE_PLAYER + METASPRITE_Y]
	add a, c
	ld [SPRITE_PLAYER + METASPRITE_Y], a
	jr .end
.ysub
	res 7, a
	ld c, a
	ld a, [SPRITE_PLAYER + METASPRITE_Y]
	sub a, c
	ld [SPRITE_PLAYER + METASPRITE_Y], a
.end
	ret
	