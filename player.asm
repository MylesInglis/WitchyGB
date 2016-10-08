INCLUDE "projectilemacros.asm"

GRAVITY EQU 3
FLOOR EQU 100
TERMINAL_VEL EQU 3

TOP_SCROLL_OFFSET EQU 50
BOTTOM_SCROLL_OFFSET EQU SCRN_Y - TOP_SCROLL_OFFSET

PROJECTILE_SPEED EQU 4
PROJECTILE_LIFE EQU 22

;Player struct

PLAYER_STRUCT_SIZE EQU 3
PLAYER_FIRE_COUNTER EQU PLAYER_ENEMY_STRUCT_SIZE
PLAYER_PROJECTILE1_LIFE EQU PLAYER_ENEMY_STRUCT_SIZE + 1
PLAYER_PROJECTILE2_LIFE EQU PLAYER_ENEMY_STRUCT_SIZE + 2

SECTION "Player Variables", BSS

PLAYER_VARS : DS PLAYER_ENEMY_STRUCT_SIZE + PLAYER_STRUCT_SIZE
;PLAYER_YVEL : DS 1
;PLAYER_XVEL : DS 1
;PLAYER_VARS + PLAYER_GRAVITY_COUNTER : DS 1
;PLAYER_ON_FLOOR : DS 1
;PLAYER_DEAD : DS 1
;PLAYER_FIRE_COUNTER : DS 1
;PLAYER_PROJECTILE1_LIFE : DS 1
;PLAYER_PROJECTILE2_LIFE : DS 1

SECTION "Player Code", HOME

PlayerInit:
	xor a
	ld [PLAYER_VARS + PLAYER_YVEL], a
	ld [PLAYER_VARS + PLAYER_XVEL], a
	ld [PLAYER_VARS + PLAYER_GRAVITY_COUNTER], a
	ld [PLAYER_VARS + PLAYER_ON_FLOOR], a
	ld [PLAYER_VARS + PLAYER_DEAD], a
	ld [PLAYER_VARS + PLAYER_FIRE_COUNTER], a
	ld [PLAYER_VARS + PLAYER_PROJECTILE1_LIFE], a
	ld [PLAYER_VARS + PLAYER_PROJECTILE2_LIFE], a
	ret
	
PlayerFireProjectile:
	ld a, PROJECTILE_LIFE
	ld b, a
	FireProjectile PLAYER_VARS + PLAYER_PROJECTILE1_LIFE, PLAYER_VARS + PLAYER_PROJECTILE2_LIFE, SPRITE_PLAYER, SPRITE_PLAYER_PROJECTILE1, SPRITE_PLAYER_PROJECTILE2, PlayerProjectile1LeftAnim, PlayerProjectile1RightAnim, PlayerProjectile2LeftAnim, PlayerProjectile2RightAnim
	or a
	jr nz, .nofire
	ld a, FIRE_ANIM_TIME
	ld [PLAYER_VARS + PLAYER_FIRE_COUNTER], a
	ld hl, SFX3
	xor a
	call GyalSFXPlay
.nofire
	ret
	
UpdateProjectilesOLD:
	ld a, [PLAYER_VARS + PLAYER_PROJECTILE1_LIFE]
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
	ld a, [PLAYER_VARS + PLAYER_PROJECTILE1_LIFE]
	dec a
	ld [PLAYER_VARS + PLAYER_PROJECTILE1_LIFE], a
	jr .proj2
.killproj1
	xor a
	ld [SPRITE_PLAYER_PROJECTILE1 + METASPRITE_Y], a
.proj2
	ld a, [PLAYER_VARS + PLAYER_PROJECTILE2_LIFE]
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
	ld a, [PLAYER_VARS + PLAYER_PROJECTILE2_LIFE]
	dec a
	ld [PLAYER_VARS + PLAYER_PROJECTILE2_LIFE], a
	jr .end
.killproj2
	xor a
	ld [SPRITE_PLAYER_PROJECTILE2 + METASPRITE_Y], a
.end
	ret
	
PlayerAnim:
	ld a, [PLAYER_VARS + PLAYER_FIRE_COUNTER]
	or a
	jr z, .checkmove
	dec a
	ld [PLAYER_VARS + PLAYER_FIRE_COUNTER], a
	PlayerFireAnim
	jp .onground
.checkmove
	ld a, [PLAYER_VARS + PLAYER_XVEL]
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
	ld a, [PLAYER_VARS + PLAYER_ON_FLOOR]
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
	ld a, [PLAYER_VARS + PLAYER_XVEL]
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
	