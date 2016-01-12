GRAVITY EQU 3
FLOOR EQU 100
TERMINAL_VEL EQU 3

TOP_SCROLL_OFFSET EQU 50
BOTTOM_SCROLL_OFFSET EQU SCRN_Y - TOP_SCROLL_OFFSET

PROJECTILE_SPEED EQU 4
PROJECTILE_LIFE EQU 22

SECTION "Player Variables", BSS

PLAYER_YVEL : DS 1
PLAYER_XVEL : DS 1
GRAVITY_COUNTER : DS 1
PLAYER_ON_FLOOR : DS 1
PLAYER_DEAD : DS 1
PLAYER_FIRE_COUNTER : DS 1
PLAYER_PROJECTILES : DS 1
PLAYER_PROJECTILE1_LIFE : DS 1
PLAYER_PROJECTILE2_LIFE : DS 1

SECTION "Player Code", HOME

PlayerInit:
	xor a
	ld [PLAYER_YVEL], a
	ld [PLAYER_XVEL], a
	ld [GRAVITY_COUNTER], a
	ld [PLAYER_ON_FLOOR], a
	ld [PLAYER_DEAD], a
	ld [PLAYER_FIRE_COUNTER], a
	ld [PLAYER_PROJECTILES], a
	ld [PLAYER_PROJECTILE1_LIFE], a
	ld [PLAYER_PROJECTILE2_LIFE], a
	ret
	
FireProjectile:
	ld a, [PLAYER_PROJECTILE1_LIFE]
	or a
	jr z, .spawnproj1
	ld a, [PLAYER_PROJECTILE2_LIFE]
	or a
	jp z, .spawnproj2
	jp .nofire
.spawnproj1
	ld a, PROJECTILE_LIFE
	ld [PLAYER_PROJECTILE1_LIFE], a
	ld a, [SPRITE_PLAYER + METASPRITE_Y]
	add a, 11
	ld [SPRITE_PLAYER_PROJECTILE1 + METASPRITE_Y], a
	ld a, [SPRITE_PLAYER + METASPRITE_ATR]
	or a
	jr z, .proj1right
	PlayerProjectile1LeftAnim
	ld a, [SPRITE_PLAYER + METASPRITE_X]
	sub a, 4
	ld [SPRITE_PLAYER_PROJECTILE1 + METASPRITE_X], a
	jp .end
.proj1right
	PlayerProjectile1RightAnim
	ld a, [SPRITE_PLAYER + METASPRITE_X]
	add a, 20
	ld [SPRITE_PLAYER_PROJECTILE1 + METASPRITE_X], a
	jp .end
.spawnproj2
	ld a, PROJECTILE_LIFE
	ld [PLAYER_PROJECTILE2_LIFE], a
	ld a, [SPRITE_PLAYER + METASPRITE_Y]
	add a, 11
	ld [SPRITE_PLAYER_PROJECTILE2 + METASPRITE_Y], a
	ld a, [SPRITE_PLAYER + METASPRITE_ATR]
	or a
	jr z, .proj2right
	PlayerProjectile2LeftAnim
	ld a, [SPRITE_PLAYER + METASPRITE_X]
	sub a, 4
	ld [SPRITE_PLAYER_PROJECTILE2 + METASPRITE_X], a
	jr .end
.proj2right
	PlayerProjectile2RightAnim
	ld a, [SPRITE_PLAYER + METASPRITE_X]
	add a, 20
	ld [SPRITE_PLAYER_PROJECTILE2 + METASPRITE_X], a
	jr .end
.end
	ld a, FIRE_ANIM_TIME
	ld [PLAYER_FIRE_COUNTER], a
	ld hl, SFX3
	ld a, 0
	call GyalSFXPlay
.nofire
	ret
	
UpdateProjectiles:
	ld a, [PLAYER_PROJECTILE1_LIFE]
	or a
	jr z, .killproj1
	xor a
	ld c, a
	ld a, [PLAYER_PROJECTILE1_ANIM + ANIM_ID]
	cp PLAYER_PROJECTILE_ANIM_LEFT
	jr z, .proj1left
	ld a, PROJECTILE_SPEED
	ld b, a
	jr .move1
.proj1left
	ld a, PROJECTILE_SPEED
	set 7, a
	ld b, a
.move1
	SpriteMove SPRITE_PLAYER_PROJECTILE1
	ld a, [PLAYER_PROJECTILE1_LIFE]
	dec a
	ld [PLAYER_PROJECTILE1_LIFE], a
	jr .proj2
.killproj1
	xor a
	ld [SPRITE_PLAYER_PROJECTILE1 + METASPRITE_Y], a
.proj2
	ld a, [PLAYER_PROJECTILE2_LIFE]
	or a
	jr z, .killproj2
	xor a
	ld c, a
	ld a, [PLAYER_PROJECTILE2_ANIM + ANIM_ID]
	cp PLAYER_PROJECTILE_ANIM_LEFT
	jr z, .proj2left
	ld a, PROJECTILE_SPEED
	ld b, a
	jr .move2
.proj2left
	ld a, PROJECTILE_SPEED
	set 7, a
	ld b, a
.move2
	SpriteMove SPRITE_PLAYER_PROJECTILE2
	ld a, [PLAYER_PROJECTILE2_LIFE]
	dec a
	ld [PLAYER_PROJECTILE2_LIFE], a
	jr .end
.killproj2
	xor a
	ld [SPRITE_PLAYER_PROJECTILE2 + METASPRITE_Y], a
.end
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
	SpriteMove SPRITE_PLAYER
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
	ld a, [PLAYER_FIRE_COUNTER]
	or a
	jr z, .checkmove
	dec a
	ld [PLAYER_FIRE_COUNTER], a
	PlayerFireAnim
	jp .onground
.checkmove
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
	