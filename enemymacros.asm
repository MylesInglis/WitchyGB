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
EnemyThink: MACRO
	ld a, [\1 + ENEMY_ON_FLOOR]
	or a
	jr z, .inair\@
	jr .onfloor\@
.inair\@
	ld a, ENEMY_ACTION_IN_AIR
	ld [\1 + ENEMY_ACTION], a
	jr .end\@
.onfloor\@
	ld a, ENEMY_ACTION_IDLE
	ld [\1 + ENEMY_ACTION], a
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
	
;1 - Enemy struct address
;2 - Metasprite address
EnemyMove: MACRO
	ld a, [\1 + ENEMY_GRAVITY_COUNTER]
	inc a
	cp GRAVITY
	jr z, .gravity\@
	ld [\1 + ENEMY_GRAVITY_COUNTER], a
	jr .move\@
.gravity\@
	xor a
	ld [\1 + ENEMY_GRAVITY_COUNTER], a
	ld a, [\1 + ENEMY_YVEL]
	bit 7, a
	jr z, .positive\@
.negative\@
	dec a
	bit 7, a
	jr z, .zero\@
	jr .applygravity\@
.zero\@
	xor a
	jr .applygravity\@
.positive\@
	inc a
	cp TERMINAL_VEL
	jr c, .applygravity\@
	ld a, TERMINAL_VEL
.applygravity\@
	ld [\1 + ENEMY_YVEL], a
.move\@
	ld a, [\1 + ENEMY_YVEL]
	ld c, a
	ld a, [\1 + ENEMY_XVEL]
	ld b, a
;	jr .noboundary\@
	bit 7, b
	jr z, .right\@
.left\@
	ld a, [SCROLL_CURRENT_MAP_COLUMN]
	sub SCRN_VX_B
	or a
	jr nz, .noboundary\@
	ld a, [rSCX]
	or a
	jr nz, .noboundary\@
	ld a, [\2 + METASPRITE_X]
	cp ENEMY_MONK_SPEED + 6
	jr nc, .noboundary\@
	xor a
	ld [\1 + ENEMY_XVEL], a
	ld b, a
	jr .noboundary\@
.right\@
	ld a, [SCROLL_MAP_SIZE]
	ld d, a
	ld a, [SCROLL_CURRENT_MAP_COLUMN]
	cp d
	jr nz, .noboundary\@
	ld a, [rSCX]
	cp ($FF - SCRN_X)
	jr c, .noboundary\@
	ld a, [\2 + METASPRITE_X]
	cp ($FF - ENEMY_MONK_SPEED - 106)
	jr c, .noboundary\@
	xor a
	ld [\1 + ENEMY_XVEL], a
	ld b, a
.noboundary\@
	SpriteMove \2
	ld a, [\1 + ENEMY_YVEL]
	bit 7, a
	jr nz, .checkalive\@
	or a
	jr z, .checkalive\@
	ld a, [\2 + METASPRITE_X]
	add a, 4
	ld b, a
	ld a, [\2 + METASPRITE_Y]
	add a, 8
	ld c, a
	call CheckWorldCollision
	or a
	jr z, .inair\@
.stop\@
	ld a, [rSCY]
	ld b, a
	ld a, [\2 + METASPRITE_Y]
	add b
	ld d, a
	and %11111000 ;set to previous multiple of 8 in world pos
	ld e, a
	ld a, [\1 + ENEMY_ON_FLOOR]
	and a
	jr nz, .skip\@
	ld a, d ;make sure player collided this frame
	sub e
	ld d, a
	ld a, [\1 + ENEMY_YVEL]
	cp d
	jr c, .inair\@
.skip\@
	ld a, e
	sub b ;back to screen pos
	ld [\2 + METASPRITE_Y], a
	xor a
	ld [\1 + ENEMY_YVEL], a
	ld a, 1
	ld [\1 + ENEMY_ON_FLOOR], a
	jr .checkalive\@
.inair\@
	xor a
	ld [\1 + ENEMY_ON_FLOOR], a
.checkalive\@
	ld a, [\2 + METASPRITE_Y]
	cp SCRN_Y + 50
	jr nc, .dead\@
	ld a, [\2 + METASPRITE_X]
	cp SCRN_X + 25
	jr c, .end\@
	cp SCRN_X + 50
	jr nc, .end\@
.dead\@
	ld a, 1
	ld [\1 + ENEMY_DEAD], a
.end\@
	ENDM