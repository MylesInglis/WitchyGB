;1 - Enemy struct address
EnemyInit: MACRO
	ld [\1 + ENEMY_YVEL], a
	ld [\1 + ENEMY_XVEL], a
	ld [\1 + ENEMY_GRAVITY_COUNTER], a
	ld [\1 + ENEMY_ON_FLOOR], a
	ld [\1 + ENEMY_DEAD], a
	ld [\1 + ENEMY_ACTION], a
	ld [\1 + ENEMY_ACTION_COUNTER], a
	ld [\1 + ENEMY_ACTIVE], a
	ld [\1 + ENEMY_TYPE], a
	ENDM
	
;1 - Enemy struct address
;2 - Metasprite address
;3 - OAM buffer location
EnemyCheckAlive: MACRO
	ld a, [\1 + ENEMY_DEAD]
	or a
	jr z, .end\@
	xor a
	ld [\1 + ENEMY_ACTIVE], a
	SpriteEnemyClear \2, \3
	EnemyInit \1
.end\@
	ENDM
	
;1 - Enemy struct address
;2 - Metasprite address
EnemyThink: MACRO
	ld a, [\1 + ENEMY_ON_FLOOR]
	or a
	jr z, .inair\@
	jr .onfloor\@
.inair\@
	ld a, ENEMY_ACTION_IN_AIR
	ld [\1 + ENEMY_ACTION], a
	jp .end\@
.onfloor\@
	ld a, [\1 + ENEMY_ACTION_COUNTER]
	or a
	jp nz, .dec\@
	ld a, [\1 + ENEMY_TYPE]
	cp ENEMY_MONK
	jr z, .monk\@
.monk\@
	ld a, [\1 + ENEMY_ACTION]
	cp ENEMY_ACTION_IDLE
	jr z, .monkdosomething\@
	ld a, ENEMY_ACTION_IDLE
	ld [\1 + ENEMY_ACTION], a
	ld a, ENEMY_MONK_IDLE_TIME
	ld [\1 + ENEMY_ACTION_COUNTER], a
	jp .end\@
.monkdosomething\@
	ld a, [SPRITE_PLAYER + METASPRITE_Y]
	ld b, a
	ld a, [\2 + METASPRITE_Y]
	cp b
	jp c, .monkcheckbelow\@
	jr z, .monkwalkorfire\@
.monkcheckabove\@
	CheckBelowTile -1, \2, .monkjump\@
	CheckBelowTile -2, \2, .monkjump\@
	CheckBelowTile -3, \2, .monkjump\@
	jr .monkwalk\@
.monkjump\@
	ld a, ENEMY_ACTION_JUMP
	ld [\1 + ENEMY_ACTION], a
	jp .end\@
.monkwalkorfire\@
	ld a, OAMF_XFLIP
	ld b, a
	ld a, [\2 + METASPRITE_ATR]
	and b
	cp OAMF_XFLIP
	jr z, .monkfaceright\@
.monkfaceleft\@
	ld a, [SPRITE_PLAYER + METASPRITE_X]
	ld b, a
	ld a, [\2 + METASPRITE_X]
	cp b
	jp nc, .monkfire\@
	jr .monkwalkright\@
.monkfaceright\@
	ld a, [SPRITE_PLAYER + METASPRITE_X]
	ld b, a
	ld a, [\2 + METASPRITE_X]
	cp b
	jp c, .monkfire\@
	jr .monkwalkleft\@
.monkwalk\@
	ld a, [SPRITE_PLAYER + METASPRITE_X]
	ld b, a
	ld a, [\2 + METASPRITE_X]
	cp b
	jr c, .monkwalkright\@
.monkwalkleft\@
	ld a, ENEMY_ACTION_WALK_LEFT
	ld [\1 + ENEMY_ACTION], a
	ld a, ENEMY_MONK_ACTION_TIME
	ld [\1 + ENEMY_ACTION_COUNTER], a
	jp .end\@
.monkwalkright\@
	ld a, ENEMY_ACTION_WALK_RIGHT
	ld [\1 + ENEMY_ACTION], a
	ld a, ENEMY_MONK_ACTION_TIME
	ld [\1 + ENEMY_ACTION_COUNTER], a
	jp .end\@
.monkcheckbelow\@
	CheckBelowTile 1, \2, .monkjumpdown\@
	CheckBelowTile 2, \2, .monkjumpdown\@
	CheckBelowTile 3, \2, .monkjumpdown\@
	CheckBelowTile 4, \2, .monkjumpdown\@
	CheckBelowTile 5, \2, .monkjumpdown\@
	jp .monkwalk\@
.monkjumpdown\@
	ld a, ENEMY_ACTION_JUMP_DOWN
	ld [\1 + ENEMY_ACTION], a
	jp .end\@
.monkfire\@
	ld a, ENEMY_PROJECTILE_LIFE
	ld b, a
	FireProjectile ENEMY_PROJECTILE1_LIFE, ENEMY_PROJECTILE2_LIFE, \2, SPRITE_ENEMY_PROJECTILE1, SPRITE_ENEMY_PROJECTILE2, EnemyProjectile1RightAnim, EnemyProjectile1LeftAnim, EnemyProjectile2RightAnim, EnemyProjectile2LeftAnim
	or a
	jp nz, .monkwalk\@
	ld hl, EnemyFireSFX
	xor a
	call GyalSFXPlay
	ld a, ENEMY_ACTION_FIRE
	ld [\1 + ENEMY_ACTION], a
	ld a, ENEMY_MONK_FIRE_ANIM_TIME
	ld [\1 + ENEMY_ACTION_COUNTER], a
	jr .end\@
.dec\@
	ld a, [\1 + ENEMY_ACTION_COUNTER]
	dec a
	ld [\1 + ENEMY_ACTION_COUNTER], a
.end\@
	ENDM
	
;1 - Enemy struct address
EnemyStop: MACRO
	xor a
	ld [\1 + ENEMY_XVEL], a
	ENDM

;1 - Enemy struct address
;2 - Speed
EnemyWalkLeft: MACRO
	ld a, \2
	set 7, a
	ld [\1 + ENEMY_XVEL], a
	ENDM
	
;1 - Enemy struct address
;2 - Speed
EnemyWalkRight: MACRO
	ld a, \2
	ld [\1 + ENEMY_XVEL], a
	ENDM
	
;1 - Enemy struct address
;2 - Speed
EnemyJump: MACRO
	ld a, \2
	ld [\1 + ENEMY_YVEL], a
	xor a
	ld [\1 + ENEMY_GRAVITY_COUNTER], a
	ld [\1 + ENEMY_ON_FLOOR], a
	ENDM
	
;1 - Enemy struct address
;2 - Metasprite address
EnemyJumpDown: MACRO
	ld a, [\2 + METASPRITE_Y]
	inc a
	ld [\2 + METASPRITE_Y], a
	xor a
	ld [\1 + ENEMY_GRAVITY_COUNTER], a
	ld [\1 + ENEMY_ON_FLOOR], a
	ENDM
	
;1 - Enemy struct address
;2 - Metasprite address
;3 - Animation data address
EnemyAct: MACRO
	ld a, [\1 + ENEMY_TYPE]
	cp ENEMY_MONK
	jr z, .monk\@
.monk\@
	ld a, [\1 + ENEMY_ACTION]
	cp ENEMY_ACTION_IDLE
	jr z, .monkidle\@
	cp ENEMY_ACTION_WALK_LEFT
	jr z, .monkwalkleft\@
	cp ENEMY_ACTION_WALK_RIGHT
	jp z, .monkwalkright\@
	cp ENEMY_ACTION_JUMP
	jp z, .monkjump\@
	cp ENEMY_ACTION_JUMP_DOWN
	jp z, .monkjumpdown\@
	cp ENEMY_ACTION_FIRE
	jp z, .monkfire\@
	cp ENEMY_ACTION_IN_AIR
	jp z, .monkinair\@
	cp ENEMY_ACTION_HURT
	jp z, .monkhurt\@
.monkidle\@
	EnemyStop \1
	MonkIdleAnim \2, \3
	jp .end\@
.monkwalkleft\@
	EnemyWalkLeft \1, ENEMY_MONK_SPEED
	MonkWalkLeftAnim \2, \3
	jp .end\@
.monkwalkright\@
	EnemyWalkRight \1, ENEMY_MONK_SPEED
	MonkWalkRightAnim \2, \3
	jp .end\@
.monkjump\@
	EnemyJump \1, ENEMY_MONK_JUMP_VEL
	jr .monknowinair\@
.monkjumpdown\@
	EnemyJumpDown \1, \2
.monknowinair\@
	ld a, ENEMY_ACTION_IN_AIR
	ld [\1 + ENEMY_ACTION], a
.monkinair\@
	MonkJumpAnim \2, \3
	jr .end\@
.monkfire\@
	MonkFireAnim \2, \3
	jr .end\@
.monkhurt\@
	EnemyStop \1
	MonkJumpAnim \2, \3
.end\@
	ENDM
	