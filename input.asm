PLAYER_JUMP_VEL EQU %10000100
PLAYER_JUMP_DOWN_VEL EQU %00000010
PLAYER_WALK_VEL EQU 2
RIGHT_SCROLL_OFFSET_MIN EQU 50
RIGHT_SCROLL_OFFSET_MAX EQU RIGHT_SCROLL_OFFSET_MIN + PLAYER_WALK_VEL + 1
LEFT_SCROLL_OFFSET_MIN EQU SCRN_X - RIGHT_SCROLL_OFFSET_MIN
LEFT_SCROLL_OFFSET_MAX EQU SCRN_X - RIGHT_SCROLL_OFFSET_MAX

SECTION "Input Variables", BSS

INPUT: ds 1
INPUT_ON: ds 1
INPUT_OFF: ds 1

SECTION "Input Code", HOME

InputInit:
	xor a
	ld [INPUT], a
	ret

GetInput:
	ld a, [INPUT]
	ld d, a
	xor a
	ld [INPUT], a
	
	ld a, %00100000
	ld [rP1], a
	
	ld a, [rP1]
	ld a, [rP1]
	ld a, [rP1]
	ld a, [rP1]
	and %00001111
	swap a
	ld b, a
	
	ld a, %00010000
	ld [rP1], a
	
	ld a, [rP1]
	ld a, [rP1]
	ld a, [rP1]
	ld a, [rP1]
	ld a, [rP1]
	ld a, [rP1]
	and %00001111
	or b
	cpl
	
	ld [INPUT], a
	ld c, a
	
	ld a, %00110000
	ld [rP1], a
	
	ld a, c
	xor d
	and c
	ld [INPUT_ON], a
	
	ld a, c
	xor d
	and d
	ld [INPUT_OFF], a
	ret
	
HandleInput:
.jumpbutton
	ld a, [INPUT_ON]
	bit 0, a
	jr z, .sfx2
	ld a, [PLAYER_ON_FLOOR]
	or a
	jr z, .sfx2
	ld a, [INPUT]
	bit 7, a
	jr z, .jump
	jr .jumpdown
.jump
	ld hl, SFX2
	ld a, 0
	call GyalSFXPlay
	ld a, PLAYER_JUMP_VEL
	ld [PLAYER_YVEL], a
	xor a
	ld [GRAVITY_COUNTER], a
	ld [PLAYER_ON_FLOOR], a
	jr .sfx2
.jumpdown
	ld a, [SPRITE_PLAYER + METASPRITE_Y]
	inc a
	ld [SPRITE_PLAYER + METASPRITE_Y], a
	xor a
	ld [GRAVITY_COUNTER], a
	ld [PLAYER_ON_FLOOR], a
.sfx2
	ld a, [INPUT_ON]
	bit 1, a
	jr z, .scrollleft
	ld hl, SFX3
	ld a, 0
	call GyalSFXPlay
.scrollleft
	ld a, [INPUT]
	bit 5, a
	jr z, .scrollright
	ld a, PLAYER_WALK_VEL
	set 7, a
	ld [PLAYER_XVEL], a
.scrollright
	ld a, [INPUT]
	bit 4, a
	jr z, .playpause
	ld a, PLAYER_WALK_VEL
	ld [PLAYER_XVEL], a
.playpause
	ld a, [INPUT_ON]
	bit 3, a
	jr z, .restart
	call GyalPlayPause
.restart
	ld a, [INPUT_ON]
	bit 2, a
	jr z, .leftoff
	ld hl, MusicStream
	call GyalMusicStart
.leftoff
	ld a, [INPUT_OFF]
	bit 5, a
	jr z, .rightoff
	xor a
	ld [PLAYER_XVEL], a
.rightoff
	ld a, [INPUT_OFF]
	bit 4, a
	jr z, .end
	xor a
	ld [PLAYER_XVEL], a
.end
	ret