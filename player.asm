GRAVITY EQU 3
FLOOR EQU 100
TERMINAL_VEL EQU 3

TOP_SCROLL_OFFSET EQU 50
BOTTOM_SCROLL_OFFSET EQU SCRN_Y - TOP_SCROLL_OFFSET


SECTION "Player Variables", BSS

PLAYER_YVEL : DS 1
PLAYER_XVEL : DS 1
GRAVITY_COUNTER : DS 1
PLAYER_ON_FLOOR : DS 1
PLAYER_DEAD : DS 1

SECTION "Player Code", HOME

PlayerInit:
	xor a
	ld [PLAYER_YVEL], a
	ld [PLAYER_XVEL], a
	ld [GRAVITY_COUNTER], a
	ld [PLAYER_ON_FLOOR], a
	ld [PLAYER_DEAD], a
	ret

PlayerMove:
	ld a, [GRAVITY_COUNTER]
	inc a
	cp GRAVITY
	jr z, .gravity
	ld [GRAVITY_COUNTER], a
	jr .move
.gravity
	xor a
	ld [GRAVITY_COUNTER], a
	ld a, [PLAYER_YVEL]
	bit 7, a
	jr z, .positive
.negative
	dec a
	bit 7, a
	jr z, .zero
	jr .applygravity
.zero
	xor a
	jr .applygravity
.positive
	inc a
	cp TERMINAL_VEL
	jr c, .applygravity
	ld a, TERMINAL_VEL
.applygravity
	ld [PLAYER_YVEL], a
.move
	ld a, [PLAYER_YVEL]
	ld c, a
	ld a, [PLAYER_XVEL]
	ld b, a
	bit 7, b
	jr z, .right
.left
	ld a, [SCROLL_CURRENT_MAP_COLUMN]
	sub SCRN_VX_B
	or a
	jr nz, .noboundary
	ld a, [rSCX]
	or a
	jr nz, .noboundary
	ld a, [SPRITE_PLAYER + METASPRITE_X]
	cp PLAYER_WALK_VEL + 6
	jr nc, .noboundary
	xor a
	ld [PLAYER_XVEL], a
	ld b, a
	jr .noboundary
.right
	ld a, [SCROLL_MAP_SIZE]
	ld d, a
	ld a, [SCROLL_CURRENT_MAP_COLUMN]
	cp d
	jr nz, .noboundary
	ld a, [rSCX]
	cp ($FF - SCRN_X)
	jr c, .noboundary
	ld a, [SPRITE_PLAYER + METASPRITE_X]
	cp ($FF - PLAYER_WALK_VEL - 106)
	jr c, .noboundary
	xor a
	ld [PLAYER_XVEL], a
	ld b, a
.noboundary
	call SpriteMove
	ld a, [PLAYER_YVEL]
	bit 7, a
	jr nz, .checkalive
	or a
	jr z, .checkalive
	ld a, [SPRITE_PLAYER + METASPRITE_X]
	add a, 4
	ld b, a
	ld a, [SPRITE_PLAYER + METASPRITE_Y]
	add a, 8
	ld c, a
	call CheckWorldCollision
	or a
	jr z, .inair
.stop
	ld a, [rSCY]
	ld b, a
	ld a, [SPRITE_PLAYER + METASPRITE_Y]
	add b
	ld d, a
	and %11111000 ;set to previous multiple of 8 in world pos
	ld e, a
	ld a, [PLAYER_ON_FLOOR]
	and a
	jr nz, .skip
	ld a, d ;make sure player collided this frame
	sub e
	ld d, a
	ld a, [PLAYER_YVEL]
	cp d
	jr c, .inair
.skip
	ld a, e
	sub b ;back to screen pos
	ld [SPRITE_PLAYER + METASPRITE_Y], a
	xor a
	ld [PLAYER_YVEL], a
	ld a, 1
	ld [PLAYER_ON_FLOOR], a
	jr .checkalive
.inair
	xor a
	ld [PLAYER_ON_FLOOR], a
.checkalive
	ld a, [SPRITE_PLAYER + METASPRITE_Y]
	cp SCRN_Y + 50
	jr c, .end
	ld a, 1
	ld [PLAYER_DEAD], a
.end
	ret
	
PlayerAnim:
	ld a, [PLAYER_XVEL]
	or a
	jr z, .notmoving
	jr .moving
.notmoving
	PlayerIdleAnim
	jr .yvel
.moving
	bit 7, a
	jr z, .positive
	jr .negative
.positive
	PlayerWalkRightAnim
	jr .yvel
.negative
	PlayerWalkLeftAnim
.yvel
	ld a, [PLAYER_ON_FLOOR]
	or a
	jr nz, .onground
.inair
	PlayerJumpAnim
.onground
	ret
	
CameraFollow:
	ld a, [SPRITE_PLAYER + METASPRITE_Y]
	cp TOP_SCROLL_OFFSET
	jr c, .scrollup
	cp BOTTOM_SCROLL_OFFSET
	jr nc, .scrolldown
	jr .scrollx
.scrollup
	call ScrollUp
	jr .scrollx
.scrolldown
	call ScrollDown
.scrollx
	ld a, [PLAYER_XVEL]
	or a
	jr z, .end
	bit 7, a
	jr z, .scrollright
.scrollleft
	ld a, [SPRITE_PLAYER + METASPRITE_X]
	cp LEFT_SCROLL_OFFSET_MIN
	jr nc, .end
	cp LEFT_SCROLL_OFFSET_MAX
	jr c, .scrollleftfaster
	ld d, PLAYER_WALK_VEL
	call ScrollLeft
	jr .end
.scrollleftfaster
	ld a, PLAYER_WALK_VEL + 1
	ld d, a
	call ScrollLeft
	jr .end
.scrollright
	ld a, [SPRITE_PLAYER + METASPRITE_X]
	cp RIGHT_SCROLL_OFFSET_MIN
	jr c, .end
	cp RIGHT_SCROLL_OFFSET_MAX
	jr c, .normalspeed
	ld a, PLAYER_WALK_VEL + 1
	ld d, a
	call ScrollRight
	jr .end
.normalspeed
	ld d, PLAYER_WALK_VEL
	call ScrollRight
.end
	ret
	